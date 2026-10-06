import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/seller_listing_defaults.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/models/create_listing_draft_dirty.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_exit_dialog.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/create_listing_test_stubs.dart';
import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  late FakeVehicleModelCatalogRepository catalog;
  final ru = ruStrings();
  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  setUpAll(() {
    registerFallbackValue(
      NewListingInput(
        sellerId: 'fallback',
        title: '-',
        make: '-',
        model: '-',
        year: 2000,
        priceEur: 1,
        mileageKm: 0,
        type: ListingType.sale,
        city: '-',
        marketRegion: MarketRegion.transnistria,
        contactPhone: '+000',
      ),
    );
    registerFallbackValue(<CoverImageUpload>[]);
  });

  setUp(() async {
    await sl.reset();
    catalog = FakeVehicleModelCatalogRepository();
    createCubit = _MockCreateCubit();
    authCubit = _MockAuthCubit();
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
    when(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    ).thenAnswer((_) async {});
    stubCreateListingVinResolve(createCubit);
    CreateListingPage.debugRevealAllSteps = false;
    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    CreateListingPage.debugRevealAllSteps = false;
    await sl.reset();
  });

  Future<void> openPushed(
    WidgetTester tester, {
    CreateListingImagePicker? imagePicker,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CreateListingPage(
                          imagePicker: imagePicker,
                          vehicleModelCatalog: catalog,
                        ),
                      ),
                    );
                  },
                  child: const Text('open-create'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-create'));
    await tester.pumpAndSettle();
  }

  Future<void> tapIdentityBack(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('create_listing_back')));
    await tester.pump();
  }

  Future<void> fillManualIdentity(WidgetTester tester) async {
    await openCreateListingManualIdentity(tester);
    await tester.tap(find.byKey(const ValueKey('create_listing_brand_field')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_model_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.commonDone));
    await tester.pumpAndSettle();
  }

  test('seller defaults alone are not a dirty draft', () {
    const baseline = CreateListingExitBaseline(
      phone: '+37369000001',
      telegram: 'seller_md',
      whatsapp: true,
      region: MarketRegion.transnistria,
      city: 'Тирасполь',
    );
    expect(
      createListingRouteExitIsDirty(
        vin: '',
        identityConfirmed: false,
        make: '',
        model: '',
        customMake: '',
        variant: '',
        year: null,
        brandChosen: false,
        photoCount: 0,
        price: '',
        mileage: '',
        dealType: ListingType.sale,
        currency: ListingCurrency.eur,
        description: '',
        hasTechnicalValue: false,
        phone: baseline.phone,
        telegram: baseline.telegram,
        whatsapp: baseline.whatsapp,
        region: baseline.region,
        city: baseline.city,
        baseline: baseline,
      ),
      isFalse,
    );
    expect(
      createListingRouteExitIsDirty(
        vin: '',
        identityConfirmed: false,
        make: '',
        model: '',
        customMake: '',
        variant: '',
        year: null,
        brandChosen: false,
        photoCount: 1,
        price: '',
        mileage: '',
        dealType: ListingType.sale,
        currency: ListingCurrency.eur,
        description: '',
        hasTechnicalValue: false,
        phone: baseline.phone,
        telegram: baseline.telegram,
        whatsapp: baseline.whatsapp,
        region: baseline.region,
        city: baseline.city,
        baseline: baseline,
      ),
      isTrue,
    );
  });

  testWidgets('untouched Step 1 back closes the route without a dialog', (
    tester,
  ) async {
    await openPushed(tester);
    await tapIdentityBack(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.text('open-create'), findsOneWidget);
  });

  testWidgets('typed VIN asks before leaving Step 1', (tester) async {
    await openPushed(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pump();
    await tapIdentityBack(tester);
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsOneWidget);
    expect(find.text(ru.createListingExitTitle), findsOneWidget);
    expect(find.text(ru.createListingExitBody), findsOneWidget);
    expect(find.text('open-create'), findsNothing);
  });

  testWidgets('system back with a VIN asks once', (tester) async {
    await openPushed(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      'WVWZZZ3CZWE123456',
    );
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    navigator.maybePop();
    await tester.pump();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsOneWidget);
    expect(find.text('open-create'), findsNothing);
  });

  testWidgets('manual MMY asks before leaving', (tester) async {
    await openPushed(tester);
    await fillManualIdentity(tester);
    await tapIdentityBack(tester);
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsOneWidget);
  });

  testWidgets('a photo kept while returning to Step 1 asks before leaving', (
    tester,
  ) async {
    await openPushed(
      tester,
      imagePicker:
          ({
            required source,
            required maxWidth,
            required imageQuality,
          }) async => XFile.fromData(png, mimeType: 'image/png', name: 'a.png'),
    );
    await fillManualIdentity(tester);
    await tester.tap(find.byKey(const ValueKey('create_listing_step_continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_step_continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tester.tap(find.byKey(const ValueKey('create_listing_step_continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create_listing_photos_section')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('create_listing_add_photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.byKey(const ValueKey('create_listing_vin_field')), findsOneWidget);
    await tapIdentityBack(tester);
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsOneWidget);
  });

  testWidgets('seller defaults alone do not warn on exit', (tester) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    CreateListingPage.debugRevealAllSteps = true;
    await openPushed(tester);
    controller.add(
      const CreateListingState(
        listingDefaults: CreateListingListingDefaults(
          status: CreateListingDefaultsStatus.ready,
          applyRevision: 1,
          prefill: SellerListingDefaultsPrefill(
            contactPhone: '+37369000001',
            telegramUsername: 'seller_md',
            whatsappEnabled: true,
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+37369000001'), findsWidgets);
    await tapIdentityBack(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.text('open-create'), findsOneWidget);
  });

  testWidgets('Stay keeps the route and the entered VIN', (tester) async {
    await openPushed(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pump();
    await tapIdentityBack(tester);
    await tester.tap(find.byKey(CreateListingExitDialog.stayKey));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.text('1HGBH41JXMN109186'), findsOneWidget);
    expect(find.text('open-create'), findsNothing);
  });

  testWidgets('Exit pops the Create Listing route', (tester) async {
    await openPushed(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pump();
    await tapIdentityBack(tester);
    await tester.tap(find.byKey(CreateListingExitDialog.leaveKey));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.text('open-create'), findsOneWidget);
  });

  testWidgets('back between steps does not confirm', (tester) async {
    await openPushed(tester);
    await fillManualIdentity(tester);
    await tester.tap(find.byKey(const ValueKey('create_listing_step_continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.byKey(const ValueKey('create_listing_vin_field')), findsOneWidget);
    expect(find.text('open-create'), findsNothing);
  });

  testWidgets('successful publish does not show the exit dialog', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.createListing,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(body: Text('feed-home')),
        ),
        GoRoute(
          path: AppRoutes.createListing,
          builder: (_, _) => CreateListingPage(vehicleModelCatalog: catalog),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pump();
    controller.add(const CreateListingState(status: CreateListingStatus.success));
    await tester.pumpAndSettle();
    expect(find.byKey(CreateListingExitDialog.dialogKey), findsNothing);
    expect(find.text('feed-home'), findsOneWidget);
  });
}
