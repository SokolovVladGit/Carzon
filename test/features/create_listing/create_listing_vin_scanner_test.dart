import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/repositories/vehicle_resolver_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing_v2.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/create_listing_test_stubs.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _CreateRepo extends Mock implements CreateListingRepository {}

class _Images extends Mock implements ListingImageRepository {}

class _Resolver implements VehicleResolverRepository {
  final vins = <String>[];
  @override
  Future<Result<VehicleResolveResult>> resolveVehicle({
    required String vin,
  }) async {
    vins.add(vin);
    return const Success(
      VehicleResolveResult(
        resolution: VehicleResolveResolution.noData,
        vehicle: VehicleResolveSuggestion(),
        completeness: 0,
        warnings: [],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('carzon/vin_scanner');
  const vinA = '1HGBH41JXMN109186';
  const vinB = 'WVWZZZ1JZXW000001';
  final field = find.byKey(const ValueKey('create_listing_vin_field'));
  final scan = find.byKey(const ValueKey('create_listing_scan_vin'));
  late _Auth auth;
  late _Resolver resolver;
  late CreateListingCubit cubit;
  late StreamController<AuthState> authEvents;
  String? userId;
  Object? nativeResult;
  Future<Object?> Function(MethodCall)? handler;
  late List<MethodCall> calls;

  setUp(() async {
    await sl.reset();
    userId = 'a';
    nativeResult = null;
    handler = null;
    calls = [];
    resolver = _Resolver();
    final images = _Images();
    cubit = CreateListingCubit(
      createListingV2: CreateListingV2(_CreateRepo()),
      uploadListingImagesSequential: UploadListingImagesSequential(images),
      deleteUploadedListingImagesBestEffort:
          DeleteUploadedListingImagesBestEffort(images),
      resolveVehicle: ResolveVehicle(resolver),
      currentUserId: () => userId,
      resolveDebounce: Duration.zero,
    );
    sl.registerFactory<CreateListingCubit>(() => cubit);
    registerIdleManualSmartFillCubit();
    auth = _Auth();
    authEvents = StreamController<AuthState>();
    whenListen(
      auth,
      authEvents.stream,
      initialState: const AuthState.authenticated(
        AuthUser(id: 'a', email: 'a@example.com'),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler == null ? nativeResult : await handler!(call);
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await sl.reset();
    if (!cubit.isClosed) await cubit.close();
    await authEvents.close();
  });

  Future<void> open(WidgetTester tester, {String locale = 'ru'}) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const CreateListingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(field);
  }

  Future<void> tapScan(WidgetTester tester) async {
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'scan action is accessible and confirmed VIN follows normal resolver path',
    (tester) async {
      nativeResult = ' wvw-zzz1jz xw000001 ';
      await open(tester);
      expect(tester.widget<IconButton>(scan).tooltip, 'Сканировать VIN');
      await tapScan(tester);
      expect(calls.single.method, 'scanVin');
      expect(tester.widget<TextFormField>(field).controller!.text, vinB);
      expect(resolver.vins, [vinB]);
      expect(cubit.state.vehicleResolve.confirmed, isFalse);
      expect(cubit.state.vehicleResolve.confirmedIdentity, isNull);
    },
  );

  testWidgets('scanner checksum-invalid VIN does not call resolver', (
    tester,
  ) async {
    nativeResult = '1HGBH41JXMN109187';
    await open(tester);
    await tapScan(tester);
    expect(
      tester.widget<TextFormField>(field).controller!.text,
      '1HGBH41JXMN109187',
    );
    expect(resolver.vins, isEmpty);
    expect(
      find.byKey(const ValueKey('create_listing_vin_checksum')),
      findsOneWidget,
    );
    expect(
      find.text('Проверьте VIN. Возможно, один из символов указан неверно.'),
      findsWidgets,
    );
  });

  testWidgets('cancel preserves manual VIN and does not resolve again', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field, vinA);
    await tester.pumpAndSettle();
    await tapScan(tester);
    expect(tester.widget<TextFormField>(field).controller!.text, vinA);
    expect(resolver.vins, [vinA]);
  });

  for (final invalid in <Object>['', '123', 'WVWZZZ1JZXW00000O', 17]) {
    testWidgets('invalid native result $invalid is safely ignored', (
      tester,
    ) async {
      nativeResult = invalid;
      await open(tester);
      await tester.enterText(field, vinA);
      await tester.pumpAndSettle();
      await tapScan(tester);
      expect(tester.widget<TextFormField>(field).controller!.text, vinA);
      expect(resolver.vins, [vinA]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scanner failure leaves manual entry usable', (tester) async {
    handler = (_) async => throw PlatformException(code: 'unavailable');
    await open(tester);
    await tapScan(tester);
    await tester.enterText(field, vinA);
    await tester.pumpAndSettle();
    expect(resolver.vins, [vinA]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing presenter still falls back to manual VIN entry', (
    tester,
  ) async {
    handler = (_) async => throw PlatformException(code: 'no_presenter');
    await open(tester);
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pump();
    expect(
      find.text('Попробуйте снова или введите VIN вручную.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    await tester.enterText(field, vinA);
    await tester.pumpAndSettle();
    expect(resolver.vins, [vinA]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported platform safely returns to manual input', (
    tester,
  ) async {
    await open(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tapScan(tester);
    await tester.enterText(field, vinB);
    await tester.pumpAndSettle();
    expect(resolver.vins, [vinB]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending scanner result cannot enter another account form', (
    tester,
  ) async {
    final result = Completer<Object?>();
    handler = (_) => result.future;
    await open(tester);
    await tapScan(tester);
    expect(tester.widget<IconButton>(scan).onPressed, isNull);
    userId = 'b';
    authEvents.add(
      const AuthState.authenticated(AuthUser(id: 'b', email: 'b@example.com')),
    );
    await tester.pumpAndSettle();
    result.complete(vinB);
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
    expect(resolver.vins, isEmpty);
  });

  testWidgets('scanner supplies complete RU and RO native copy', (
    tester,
  ) async {
    for (final locale in ['ru', 'ro']) {
      await open(tester, locale: locale);
      await tapScan(tester);
      final strings = Map<String, String>.from(calls.last.arguments as Map);
      expect(strings, hasLength(16));
      expect(strings.values.every((value) => value.isNotEmpty), isTrue);
      expect(
        strings['title'],
        locale == 'ru' ? 'Сканировать VIN' : 'Scanează VIN',
      );
      expect(
        strings['use'],
        locale == 'ru' ? 'Использовать VIN' : 'Folosește VIN',
      );
    }
  });
}
