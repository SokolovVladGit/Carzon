import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/services/supabase_service.dart';
import 'package:carzon/features/create_listing/data/datasources/create_listing_remote_datasource.dart';
import 'package:carzon/features/create_listing/data/datasources/seller_listing_defaults_remote_datasource.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/seller_listing_defaults.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/repositories/seller_listing_defaults_repository.dart';
import 'package:carzon/features/create_listing/domain/repositories/vehicle_resolver_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing_v2.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/get_my_listing_defaults.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle.dart';
import 'package:carzon/features/create_listing/domain/usecases/save_my_listing_defaults.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../helpers/create_listing_test_stubs.dart';

class _MockCreateRepo extends Mock implements CreateListingRepository {}

class _MockImageRepo extends Mock implements ListingImageRepository {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

class _MockGoTrueClient extends Mock implements sb.GoTrueClient {}

/// Records request-local headers and holds execution at an async boundary.
class _PendingRpc extends Mock implements sb.PostgrestFilterBuilder<dynamic> {
  final headers = <String, String>{};
  final response = Completer<dynamic>();

  @override
  sb.PostgrestFilterBuilder<dynamic> setHeader(String key, String value) {
    headers[key] = value;
    return this;
  }

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) => response.future.then(onValue, onError: onError);
}

sb.Session _session(String id) => sb.Session(
  accessToken: 'test-token-$id',
  tokenType: 'bearer',
  user: sb.User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

class _NoopResolver implements VehicleResolverRepository {
  @override
  Future<Result<VehicleResolveResult>> resolveVehicle({required String vin}) {
    throw StateError('resolve-vehicle must not run in defaults tests');
  }
}

class _FakeDefaultsRepo implements SellerListingDefaultsRepository {
  Result<SellerListingDefaults> getResult = const Success(
    SellerListingDefaults.empty(),
  );
  Completer<Result<SellerListingDefaults>>? getGate;
  Result<SellerListingDefaults> saveResult = const Success(
    SellerListingDefaults.empty(),
  );
  final saved = <SellerListingDefaults>[];
  Completer<Result<SellerListingDefaults>>? saveGate;

  @override
  Future<Result<SellerListingDefaults>> getMyListingDefaults() {
    final gate = getGate;
    if (gate != null) return gate.future;
    return Future.value(getResult);
  }

  @override
  Future<Result<SellerListingDefaults>> saveMyListingDefaults(
    SellerListingDefaults defaults,
  ) async {
    saved.add(defaults);
    if (saveGate != null) return saveGate!.future;
    return saveResult;
  }
}

const _populated = SellerListingDefaults(
  contactPhone: '+373 690 00001',
  telegramUsername: 'seller_md',
  whatsappEnabled: true,
  marketRegion: MarketRegion.moldova,
  city: 'Chișinău',
);

NewListingInput _input({
  String contactPhone = '+373 777 11111',
  String? telegramUsername = 'visible_user',
  bool whatsappEnabled = true,
  MarketRegion marketRegion = MarketRegion.moldova,
  String city = 'Bălți',
}) => NewListingInput(
  sellerId: 's1',
  title: 't',
  make: 'M',
  model: 'm',
  year: 2020,
  priceEur: 10000,
  priceCurrency: ListingCurrency.eur,
  mileageKm: 50000,
  type: ListingType.sale,
  city: city,
  marketRegion: marketRegion,
  contactPhone: contactPhone,
  telegramUsername: telegramUsername,
  whatsappEnabled: whatsappEnabled,
);

Listing _listing() => Listing(
  id: 'l1',
  title: 't',
  make: 'M',
  model: 'm',
  year: 2020,
  priceCurrency: ListingCurrency.eur,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Bălți',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 1, 1),
  status: ListingStatus.active,
  sellerId: 's1',
);

void main() {
  late _MockCreateRepo createRepo;
  late _MockImageRepo imageRepo;
  late _FakeDefaultsRepo defaultsRepo;
  late CreateListingCubit cubit;
  String? currentUserId;

  setUpAll(() {
    registerFallbackValue(_input());
  });

  setUp(() async {
    await sl.reset();
    createRepo = _MockCreateRepo();
    imageRepo = _MockImageRepo();
    defaultsRepo = _FakeDefaultsRepo();
    currentUserId = 's1';
    cubit = CreateListingCubit(
      currentUserId: () => currentUserId,
      createListingV2: CreateListingV2(createRepo),
      uploadListingImagesSequential: UploadListingImagesSequential(imageRepo),
      deleteUploadedListingImagesBestEffort:
          DeleteUploadedListingImagesBestEffort(imageRepo),
      resolveVehicle: ResolveVehicle(_NoopResolver()),
      getMyListingDefaults: GetMyListingDefaults(defaultsRepo),
      saveMyListingDefaults: SaveMyListingDefaults(defaultsRepo),
    );
  });

  tearDown(() async {
    await sl.reset();
    if (!cubit.isClosed) await cubit.close();
  });

  for (final rpcName in ['create_listing_v2', 'upsert_my_listing_defaults']) {
    test(
      '$rpcName retains A authorization when execution completes under B',
      () async {
        final client = _MockSupabaseClient();
        final auth = _MockGoTrueClient();
        final rpc = _PendingRpc();
        var session = _session('s1');
        when(() => client.auth).thenReturn(auth);
        when(() => auth.currentSession).thenAnswer((_) => session);
        when(
          () => client.rpc<dynamic>(rpcName, params: any(named: 'params')),
        ).thenAnswer((_) => rpc);
        final service = SupabaseService(client);
        final Future<Object?> pending = rpcName == 'create_listing_v2'
            ? SupabaseCreateListingRemoteDataSource(service).insertV2(_input())
            : SupabaseSellerListingDefaultsRemoteDataSource(
                service,
              ).upsertMyListingDefaults(_populated);
        final outcome = expectLater(pending, throwsA(isA<ServerException>()));
        session = _session('user-b');
        rpc.response.completeError(
          const sb.PostgrestException(message: 'rejected', code: '22023'),
        );
        await outcome;
        expect(rpc.headers['Authorization'], 'Bearer test-token-s1');
        expect(auth.currentSession!.user.id, 'user-b');
      },
    );
  }

  test(
    'create datasource refuses a seller different from current account',
    () async {
      final client = _MockSupabaseClient();
      final auth = _MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      when(() => auth.currentSession).thenReturn(_session('user-b'));
      await expectLater(
        SupabaseCreateListingRemoteDataSource(
          SupabaseService(client),
        ).insertV2(_input()),
        throwsA(isA<ServerException>()),
      );
      verifyNever(
        () => client.rpc<dynamic>(any(), params: any(named: 'params')),
      );
    },
  );

  testWidgets('late Moldova defaults preserve a selected Transnistria city', (
    tester,
  ) async {
    defaultsRepo.getGate = Completer();
    sl.registerFactory<CreateListingCubit>(() => cubit);
    registerIdleManualSmartFillCubit();
    final auth = _MockAuthCubit();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(
        AuthUser(id: 's1', email: 'seller@example.com'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const CreateListingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();

    defaultsRepo.getGate!.complete(const Success(_populated));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: city, matching: find.text('Тирасполь')),
      findsOneWidget,
    );
    expect(cubit.state.listingDefaults.prefill.marketRegion, isNull);
    expect(cubit.state.listingDefaults.prefill.city, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('defaults load does not block initial Create state', () async {
    defaultsRepo.getGate = Completer();
    expect(cubit.state.status, CreateListingStatus.idle);

    final pending = cubit.loadListingDefaults(userId: 's1');
    await Future<void>.value();

    expect(cubit.state.status, CreateListingStatus.idle);
    expect(
      cubit.state.listingDefaults.status,
      CreateListingDefaultsStatus.loading,
    );

    defaultsRepo.getGate!.complete(const Success(_populated));
    await pending;

    expect(cubit.state.status, CreateListingStatus.idle);
    expect(
      cubit.state.listingDefaults.status,
      CreateListingDefaultsStatus.ready,
    );
  });

  test('phone prefills when untouched', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    expect(cubit.state.listingDefaults.prefill.contactPhone, '+373 690 00001');
  });

  test('Telegram prefills when untouched', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    expect(cubit.state.listingDefaults.prefill.telegramUsername, 'seller_md');
  });

  test('WhatsApp prefills when untouched', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    expect(cubit.state.listingDefaults.prefill.whatsappEnabled, isTrue);
  });

  test('market region prefills when untouched', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    expect(
      cubit.state.listingDefaults.prefill.marketRegion,
      MarketRegion.moldova,
    );
  });

  test('city prefills with matching region', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    expect(cubit.state.listingDefaults.prefill.city, 'Chișinău');
    expect(
      cubit.state.listingDefaults.prefill.marketRegion,
      MarketRegion.moldova,
    );
  });

  Future<void> lateDefaultsAfter(void Function() edit) async {
    defaultsRepo.getGate = Completer();
    final pending = cubit.loadListingDefaults(userId: 's1');
    await Future<void>.value();
    edit();
    defaultsRepo.getGate!.complete(const Success(_populated));
    await pending;
  }

  test('late defaults do not overwrite user-edited phone', () async {
    await lateDefaultsAfter(cubit.markPhoneEdited);
    expect(cubit.state.listingDefaults.prefill.contactPhone, isNull);
    expect(cubit.state.listingDefaults.prefill.telegramUsername, 'seller_md');
  });

  test('late defaults do not overwrite user-edited Telegram', () async {
    await lateDefaultsAfter(cubit.markTelegramEdited);
    expect(cubit.state.listingDefaults.prefill.telegramUsername, isNull);
    expect(cubit.state.listingDefaults.prefill.contactPhone, '+373 690 00001');
  });

  test('late defaults do not overwrite user-edited WhatsApp', () async {
    await lateDefaultsAfter(cubit.markWhatsappEdited);
    expect(cubit.state.listingDefaults.prefill.whatsappEnabled, isNull);
  });

  test('late defaults do not overwrite user-edited region', () async {
    await lateDefaultsAfter(cubit.markRegionEdited);
    expect(cubit.state.listingDefaults.prefill.marketRegion, isNull);
    expect(cubit.state.listingDefaults.prefill.city, isNull);
  });

  test('late defaults do not overwrite user-edited city', () async {
    await lateDefaultsAfter(cubit.markCityEdited);
    expect(cubit.state.listingDefaults.prefill.city, isNull);
    expect(cubit.state.listingDefaults.prefill.marketRegion, isNull);
  });

  test('account/session change discards stale defaults result', () async {
    final gateA = Completer<Result<SellerListingDefaults>>();
    defaultsRepo.getGate = gateA;
    currentUserId = 'user-a';
    final loadA = cubit.loadListingDefaults(userId: 'user-a');
    await Future<void>.value();

    final gateB = Completer<Result<SellerListingDefaults>>();
    defaultsRepo.getGate = gateB;
    currentUserId = 'user-b';
    final loadB = cubit.loadListingDefaults(userId: 'user-b');
    await Future<void>.value();

    gateA.complete(const Success(_populated));
    await loadA;
    expect(cubit.state.listingDefaults.requestedUserId, 'user-b');
    expect(cubit.state.listingDefaults.values.isEmpty, isTrue);
    expect(cubit.state.listingDefaults.applyRevision, 0);

    const userB = SellerListingDefaults(
      contactPhone: '+373 555 00000',
      marketRegion: MarketRegion.transnistria,
      city: 'Tiraspol',
    );
    gateB.complete(const Success(userB));
    await loadB;
    expect(cubit.state.listingDefaults.requestedUserId, 'user-b');
    expect(cubit.state.listingDefaults.values.contactPhone, '+373 555 00000');
    expect(cubit.state.listingDefaults.prefill.contactPhone, '+373 555 00000');
    expect(
      cubit.state.listingDefaults.values.contactPhone,
      isNot('+373 690 00001'),
    );
  });

  test(
    'no defaults preserves empty prefill (transnistria/empty city)',
    () async {
      defaultsRepo.getResult = const Success(SellerListingDefaults.empty());
      await cubit.loadListingDefaults(userId: 's1');
      expect(cubit.state.listingDefaults.prefill.hasAny, isFalse);
      expect(cubit.state.listingDefaults.prefill.marketRegion, isNull);
      expect(cubit.state.listingDefaults.prefill.city, isNull);
    },
  );

  test('manual region change still treats city as user-owned', () async {
    defaultsRepo.getGate = Completer();
    final pending = cubit.loadListingDefaults(userId: 's1');
    await Future<void>.value();
    cubit.markRegionEdited();
    defaultsRepo.getGate!.complete(const Success(_populated));
    await pending;
    expect(cubit.state.listingDefaults.regionEdited, isTrue);
    expect(cubit.state.listingDefaults.cityEdited, isTrue);
    expect(cubit.state.listingDefaults.prefill.marketRegion, isNull);
    expect(cubit.state.listingDefaults.prefill.city, isNull);
  });

  test('submitted listing uses current visible values', () async {
    defaultsRepo.getResult = const Success(_populated);
    await cubit.loadListingDefaults(userId: 's1');
    when(
      () => createRepo.createV2(any()),
    ).thenAnswer((_) async => Success(_listing()));

    final visible = _input();
    await cubit.submit(listingInput: visible, orderedPhotos: []);

    final captured =
        verify(() => createRepo.createV2(captureAny())).captured.single
            as NewListingInput;
    expect(captured.contactPhone, visible.contactPhone);
    expect(captured.telegramUsername, visible.telegramUsername);
    expect(captured.whatsappEnabled, visible.whatsappEnabled);
    expect(captured.marketRegion, visible.marketRegion);
    expect(captured.city, visible.city);
    expect(captured.contactPhone, isNot(_populated.contactPhone));
  });

  test(
    'successful create triggers save defaults matching submit values',
    () async {
      when(
        () => createRepo.createV2(any()),
      ).thenAnswer((_) async => Success(_listing()));

      final visible = _input();
      await cubit.submit(listingInput: visible, orderedPhotos: []);

      expect(cubit.state.status, CreateListingStatus.success);
      expect(defaultsRepo.saved, hasLength(1));
      expect(defaultsRepo.saved.single.contactPhone, visible.contactPhone);
      expect(
        defaultsRepo.saved.single.telegramUsername,
        visible.telegramUsername,
      );
      expect(
        defaultsRepo.saved.single.whatsappEnabled,
        visible.whatsappEnabled,
      );
      expect(defaultsRepo.saved.single.marketRegion, visible.marketRegion);
      expect(defaultsRepo.saved.single.city, visible.city);
    },
  );

  test(
    'save-defaults failure does not turn successful create into failure',
    () async {
      defaultsRepo.saveResult = const FailureResult(
        ServerFailure('defaults unavailable'),
      );
      when(
        () => createRepo.createV2(any()),
      ).thenAnswer((_) async => Success(_listing()));

      await cubit.submit(listingInput: _input(), orderedPhotos: []);

      expect(cubit.state.status, CreateListingStatus.success);
      expect(cubit.state.failureKind, isNull);
      expect(defaultsRepo.saved, hasLength(1));
    },
  );

  test('failed create does not save defaults', () async {
    when(
      () => createRepo.createV2(any()),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('db')));

    await cubit.submit(listingInput: _input(), orderedPhotos: []);

    expect(cubit.state.status, CreateListingStatus.failure);
    expect(defaultsRepo.saved, isEmpty);
  });

  test(
    'account switches before create response: no defaults save or success',
    () async {
      final gate = Completer<Result<Listing>>();
      when(() => createRepo.createV2(any())).thenAnswer((_) => gate.future);
      final pending = cubit.submit(listingInput: _input(), orderedPhotos: []);
      currentUserId = 'user-b';
      gate.complete(Success(_listing()));
      await pending;
      expect(defaultsRepo.saved, isEmpty);
      expect(cubit.state.status, CreateListingStatus.idle);
      expect(cubit.state.created, isNull);
    },
  );

  test(
    'account switches during defaults save: completion cannot show success',
    () async {
      defaultsRepo.saveGate = Completer();
      when(
        () => createRepo.createV2(any()),
      ).thenAnswer((_) async => Success(_listing()));
      final pending = cubit.submit(listingInput: _input(), orderedPhotos: []);
      await Future<void>.delayed(Duration.zero);
      expect(defaultsRepo.saved, hasLength(1));
      currentUserId = 'user-b';
      cubit.syncWithAuth(currentUserId);
      defaultsRepo.saveGate!.complete(
        const Success(SellerListingDefaults.empty()),
      );
      await pending;
      expect(defaultsRepo.saved, hasLength(1));
      expect(cubit.state.status, CreateListingStatus.idle);
    },
  );
}
