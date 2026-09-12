import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_manual_smart_fill_panel.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/validation/listing_valid_years.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
  late MockManualSmartFillCubit smartFill;
  late StreamController<ManualSmartFillState> smartFillEvents;
  late FakeVehicleModelCatalogRepository catalog;
  final ru = ruStrings();
  final newestYear = listingYearsOrderedNewestFirst().first;

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
  });

  setUp(() async {
    await sl.reset();
    catalog = FakeVehicleModelCatalogRepository(
      modelsByMake: {
        'skoda': ['Octavia'],
        'bmw': ['3 Series', 'X5'],
        'hyundai': ['Tucson'],
      },
    );
    createCubit = _MockCreateCubit();
    authCubit = _MockAuthCubit();
    smartFill = MockManualSmartFillCubit();
    smartFillEvents = StreamController<ManualSmartFillState>.broadcast();
    addTearDown(smartFillEvents.close);
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );
    when(() => smartFill.state).thenReturn(const ManualSmartFillState.idle());
    whenListen(
      smartFill,
      smartFillEvents.stream,
      initialState: const ManualSmartFillState.idle(),
    );
    when(
      () => smartFill.lookup(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenReturn(null);
    when(
      () => smartFill.answer(
        attribute: any(named: 'attribute'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(smartFill.dismissClarification).thenReturn(null);
    void emitSmartFillIdle() {
      when(() => smartFill.state).thenReturn(const ManualSmartFillState.idle());
      smartFillEvents.add(const ManualSmartFillState.idle());
    }

    when(smartFill.reset).thenAnswer((_) => emitSmartFillIdle());
    when(
      smartFill.cancelForVinAuthority,
    ).thenAnswer((_) => emitSmartFillIdle());
    when(smartFill.retry).thenAnswer((_) async {});
    when(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    ).thenAnswer((_) async {});
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
    stubCreateListingVinResolve(createCubit, registerSmartFill: false);
    sl.registerFactory<CreateListingCubit>(() => createCubit);
    sl.registerFactory<ManualSmartFillCubit>(() => smartFill);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap({CreateListingState? resolveState}) {
    if (resolveState != null) {
      when(() => createCubit.state).thenReturn(resolveState);
      whenListen(
        createCubit,
        const Stream<CreateListingState>.empty(),
        initialState: resolveState,
      );
    }
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(vehicleModelCatalog: catalog),
      ),
    );
  }

  Future<void> completeSkodaOctavia(WidgetTester tester) async {
    await openCreateListingManualIdentity(tester);
    await tester.tap(find.byKey(const ValueKey('create_listing_brand_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Skoda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_model_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_Octavia')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.commonDone));
    await tester.pumpAndSettle();
  }

  ManualSmartFillResult okResult({
    String? body,
    String? fuel,
    double? liters,
    int? hp,
    String? transmission,
    ManualSmartFillClarification? clarification,
  }) {
    return ManualSmartFillResult(
      resolution: ManualSmartFillResolution.ok,
      identity: const ManualSmartFillIdentity(
        makeKey: 'skoda',
        modelKey: 'octavia',
        year: 2018,
      ),
      consensus: ManualSmartFillConsensusSpecs(
        bodyType: body,
        fuelType: fuel,
        engineDisplacementLiters: liters,
        enginePowerHp: hp,
        transmissionType: transmission,
        drivetrain: 'awd',
      ),
      clarification: clarification,
      mappingVersion: 'm1.1',
    );
  }

  Future<void> emitSmartFill(ManualSmartFillState next) async {
    when(() => smartFill.state).thenReturn(next);
    smartFillEvents.add(next);
  }

  Finder bodyTypeField() =>
      find.byKey(const ValueKey('create_listing_body_type_field'));
  Finder fuelField() => find.byKey(const ValueKey('create_listing_fuel_field'));
  Finder displacementField() =>
      find.byKey(const ValueKey('create_listing_engine_displacement_field'));
  Finder powerField() =>
      find.byKey(const ValueKey('create_listing_engine_power_field'));
  Finder transmissionField() =>
      find.byKey(const ValueKey('create_listing_transmission_field'));

  Future<void> changeToBmw3Series(WidgetTester tester) async {
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    await tester.scrollUntilVisible(
      brand,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'BMW'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_model_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_3 Series')));
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredDeal(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.createListingPricePlaceholder),
      '9000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.createListingMileagePlaceholder),
      '100000',
    );
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.scrollUntilVisible(
      city,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.fieldPhone),
      '+37369000001',
    );
  }

  StreamController<CreateListingState> listenCreate() {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    return controller;
  }

  void emitCreate(
    StreamController<CreateListingState> controller,
    CreateListingState next,
  ) {
    when(() => createCubit.state).thenReturn(next);
    controller.add(next);
  }

  CreateListingState vinConfirmed({
    required VehicleResolveResult suggestion,
    required ConfirmedVehicleIdentity identity,
    bool confirmed = true,
    int applyRevision = 1,
    CreateListingVinResolveStatus status =
        CreateListingVinResolveStatus.resolved,
  }) {
    return CreateListingState(
      vehicleResolve: CreateListingVehicleResolve(
        status: status,
        normalizedVin: 'WBA12345678901234',
        suggestion: suggestion,
        confirmed: confirmed,
        applyRevision: applyRevision,
        confirmedIdentity: identity,
      ),
    );
  }

  const octaviaVin = VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: 'Skoda',
      model: 'Octavia',
      year: 2018,
      bodyType: 'Sedan',
      fuelType: 'Diesel',
      displacement: '1.6 L',
      transmission: 'Automatic',
    ),
    completeness: 0.9,
    warnings: [],
  );

  const bmwX5Vin = VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: 'BMW',
      model: 'X5',
      year: 2020,
      bodyType: 'Pickup',
      fuelType: 'Gasoline',
      displacement: '3.0 L',
    ),
    completeness: 0.9,
    warnings: [],
  );

  testWidgets('VIN idle does not lookup before manual identity', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    verifyNever(
      () => smartFill.lookup(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    );
  });

  testWidgets('complete MMY triggers lookup', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    verify(
      () => smartFill.lookup(make: 'Skoda', model: 'Octavia', year: newestYear),
    ).called(1);
  });

  testWidgets('confirmed VIN mode does not trigger Smart Fill', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: const CreateListingState(
          vehicleResolve: CreateListingVehicleResolve(
            status: CreateListingVinResolveStatus.resolved,
            confirmed: true,
            applyRevision: 1,
            confirmedIdentity: ConfirmedVehicleIdentity(
              make: 'BMW',
              model: 'X5',
              year: 2020,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verifyNever(
      () => smartFill.lookup(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    );
    verify(smartFill.reset).called(greaterThanOrEqualTo(1));
  });

  testWidgets(
    'consensus fills empty specs and preview without opening Advanced',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await completeSkodaOctavia(tester);
      await emitSmartFill(
        ManualSmartFillState(
          status: ManualSmartFillStatus.filled,
          query: ManualSmartFillQuery(
            make: 'Skoda',
            model: 'Octavia',
            year: newestYear,
          ),
          result: okResult(
            body: 'suv',
            fuel: 'petrol',
            liters: 2,
            hp: 150,
            transmission: 'automatic',
          ),
          applyRevision: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('create_listing_smart_fill_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_body_type_field')),
        findsNothing,
      );

      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
        contains(formatListingBodyType(ru, ListingBodyType.suv)),
      );

      await expandCreateListingAdditionalDetails(tester);
      expect(
        find.text(formatListingBodyType(ru, ListingBodyType.suv)),
        findsWidgets,
      );
      expect(
        find.text(formatListingFuelType(ru, ListingFuelType.petrol)),
        findsWidgets,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(
                const ValueKey('create_listing_engine_displacement_field'),
              ),
            )
            .controller
            ?.text,
        '2',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('create_listing_engine_power_field')),
            )
            .controller
            ?.text,
        '150',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_transmission_field')),
          matching: find.text(formatListingTransmissionType(ru, ListingTransmissionType.automatic)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_drivetrain_field')),
          matching: find.text(ru.listingDrivetrain),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('seller-owned body is not overwritten', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await expandCreateListingAdditionalDetails(tester);
    await tester.tap(
      find.byKey(const ValueKey('create_listing_body_type_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
    );
    await tester.pumpAndSettle();

    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'diesel'),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
      findsWidgets,
    );
    expect(
      find.text(formatListingFuelType(ru, ListingFuelType.diesel)),
      findsWidgets,
    );
  });

  testWidgets('clarification is localized and I do not know hides it', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.needsClarification,
        result: okResult(
          clarification: const ManualSmartFillClarification(
            attribute: 'body',
            options: [
              ManualSmartFillClarificationOption(value: 'wagon'),
              ManualSmartFillClarificationOption(value: 'sedan'),
            ],
          ),
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingSmartFillSeveralVersions), findsOneWidget);
    expect(find.text(ru.createListingSmartFillAskBody), findsOneWidget);
    expect(
      find.text(manualSmartFillOptionLabel(ru, 'body', 'wagon')!),
      findsOneWidget,
    );
    expect(find.text('wagon'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('create_listing_smart_fill_dont_know')),
    );
    verify(smartFill.dismissClarification).called(1);
  });

  testWidgets('answer option calls resolver once', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.needsClarification,
        result: okResult(
          clarification: const ManualSmartFillClarification(
            attribute: 'fuel',
            options: [
              ManualSmartFillClarificationOption(value: 'diesel'),
              ManualSmartFillClarificationOption(value: 'petrol'),
            ],
          ),
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('create_listing_smart_fill_option_diesel')),
    );
    verify(
      () => smartFill.answer(attribute: 'fuel', value: 'diesel'),
    ).called(1);
  });

  testWidgets('noData and failure stay non-blocking', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      const ManualSmartFillState(
        status: ManualSmartFillStatus.noData,
        applyRevision: 1,
        result: ManualSmartFillResult(
          resolution: ManualSmartFillResolution.noData,
          identity: ManualSmartFillIdentity(
            makeKey: 'skoda',
            modelKey: 'octavia',
            year: 2018,
          ),
          consensus: ManualSmartFillConsensusSpecs(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_no_data')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_publish_section')),
      findsOneWidget,
    );

    await emitSmartFill(
      const ManualSmartFillState(status: ManualSmartFillStatus.failure),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_retry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_publish_section')),
      findsOneWidget,
    );
  });

  testWidgets('loading does not disable publish', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      const ManualSmartFillState(status: ManualSmartFillStatus.loading),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_publish_section')),
      findsOneWidget,
    );
  });

  testWidgets('seller-owned displacement and power are not overwritten', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await expandCreateListingAdditionalDetails(tester);
    await tester.enterText(displacementField(), '1.4');
    await tester.enterText(powerField(), '110');
    await tester.pump();
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'petrol', liters: 2, hp: 150),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '1.4',
    );
    expect(tester.widget<TextFormField>(powerField()).controller?.text, '110');
  });

  testWidgets('edit after autofill clears catalog ownership', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'petrol', liters: 2, hp: 150),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    await tester.tap(bodyTypeField());
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(powerField(), '200');
    await tester.pump();

    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'wagon', fuel: 'diesel', liters: 1.8, hp: 90),
        applyRevision: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(powerField()).controller?.text, '200');
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(formatListingFuelType(ru, ListingFuelType.diesel)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('MMY change clears only catalog-owned values', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await expandCreateListingAdditionalDetails(tester);
    await tester.tap(bodyTypeField());
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
    );
    await tester.pumpAndSettle();
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'diesel', liters: 2, hp: 150),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await changeToBmw3Series(tester);
    await tester.scrollUntilVisible(
      bodyTypeField(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(formatListingFuelType(ru, ListingFuelType.diesel)),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(powerField()).controller?.text,
      isEmpty,
    );
  });

  testWidgets('confirmed VIN may replace catalog-owned but not seller-owned', (
    tester,
  ) async {
    final controller = listenCreate();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'petrol', liters: 2, hp: 150),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: octaviaVin,
        identity: const ConfirmedVehicleIdentity(
          make: 'Skoda',
          model: 'Octavia',
          year: 2018,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(formatListingBodyType(ru, ListingBodyType.sedan)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(formatListingFuelType(ru, ListingFuelType.diesel)),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '1.6',
    );
    verify(smartFill.cancelForVinAuthority).called(greaterThanOrEqualTo(1));
  });

  testWidgets('confirmed VIN does not replace seller-owned field', (
    tester,
  ) async {
    final controller = listenCreate();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await expandCreateListingAdditionalDetails(tester);
    await tester.tap(bodyTypeField());
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(formatListingBodyType(ru, ListingBodyType.hatchback)),
    );
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: octaviaVin,
        identity: const ConfirmedVehicleIdentity(
          make: 'Skoda',
          model: 'Octavia',
          year: 2018,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(formatListingBodyType(ru, ListingBodyType.hatchback)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('VIN-owned specs are not overwritten by catalog', (tester) async {
    final controller = listenCreate();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: bmwX5Vin,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
        ),
      ),
    );
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: bmwX5Vin,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
        ),
        confirmed: false,
        status: CreateListingVinResolveStatus.manual,
      ),
    );
    await tester.pumpAndSettle();
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'diesel', liters: 2, hp: 150),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '3',
    );
  });

  testWidgets('manual MMY change clears stale VIN-owned optional specs', (
    tester,
  ) async {
    final controller = listenCreate();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: bmwX5Vin,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
        ),
      ),
    );
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: bmwX5Vin,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
        ),
        confirmed: false,
        status: CreateListingVinResolveStatus.manual,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_brand_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Skoda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_model_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_Octavia')));
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
  });

  testWidgets('Smart Fill values reach preview and NewListingInput', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(
          body: 'suv',
          fuel: 'petrol',
          liters: 2,
          hp: 150,
          transmission: 'cvt',
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
      contains(formatListingBodyType(ru, ListingBodyType.suv)),
    );
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
      contains(formatListingFuelType(ru, ListingFuelType.petrol)),
    );
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
      contains(
        formatListingTransmissionType(ru, ListingTransmissionType.cvt),
      ),
    );
    await fillRequiredDeal(tester);
    final publish = find.text(ru.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pump();
    final submitted =
        verify(
              () => createCubit.submit(
                listingInput: captureAny(named: 'listingInput'),
                orderedPhotos: any(named: 'orderedPhotos'),
              ),
            ).captured.single
            as NewListingInput;
    expect(submitted.bodyType, ListingBodyType.suv);
    expect(submitted.fuelType, ListingFuelType.petrol);
    expect(submitted.engineDisplacementLiters, 2);
    expect(submitted.enginePowerHp, 150);
    expect(submitted.transmissionType, ListingTransmissionType.cvt);
    expect(submitted.drivetrain, isNull);
  });

  testWidgets('account change resets Smart Fill and provenance', (
    tester,
  ) async {
    final authEvents = StreamController<AuthState>();
    addTearDown(authEvents.close);
    const nextUser = AuthUser(id: 'u2', email: 'other@example.com');
    whenListen(
      authCubit,
      authEvents.stream,
      initialState: const AuthState.authenticated(
        AuthUser(id: 'u1', email: 'seller@example.com'),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.needsClarification,
        result: okResult(
          body: 'suv',
          fuel: 'petrol',
          clarification: const ManualSmartFillClarification(
            attribute: 'body',
            options: [
              ManualSmartFillClarificationOption(value: 'wagon'),
              ManualSmartFillClarificationOption(value: 'sedan'),
            ],
          ),
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsOneWidget,
    );
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.authenticated(nextUser));
    authEvents.add(const AuthState.authenticated(nextUser));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsNothing,
    );
    expect(find.byKey(ListingPreviewCard.specsKey), findsNothing);
    verify(smartFill.reset).called(greaterThanOrEqualTo(1));
  });

  testWidgets('dispose does not apply a late Smart Fill response', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(body: 'suv', fuel: 'petrol'),
        applyRevision: 1,
      ),
    );
    await tester.pump();
    expect(find.byType(CreateListingPage), findsNothing);
  });

  testWidgets('catalog transmission fills Advanced and keeps drivetrain empty', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(transmission: 'dual_clutch'),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_summary')),
      findsNothing,
    );
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(
          formatListingTransmissionType(ru, ListingTransmissionType.dualClutch),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_drivetrain_field')),
        matching: find.text(ru.listingDrivetrain),
      ),
      findsOneWidget,
    );
  });

  testWidgets('seller transmission edit is not overwritten', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await expandCreateListingAdditionalDetails(tester);
    await tester.scrollUntilVisible(
      transmissionField(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(transmissionField());
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(formatListingTransmissionType(ru, ListingTransmissionType.manual)),
    );
    await tester.pumpAndSettle();
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(transmission: 'automatic'),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(
          formatListingTransmissionType(ru, ListingTransmissionType.manual),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('MMY change clears catalog-owned transmission', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(transmission: 'automatic'),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    await changeToBmw3Series(tester);
    await tester.scrollUntilVisible(
      transmissionField(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(
          formatListingTransmissionType(ru, ListingTransmissionType.automatic),
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('VIN replaces catalog-owned transmission only', (tester) async {
    final controller = listenCreate();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        result: okResult(transmission: 'manual'),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    emitCreate(
      controller,
      vinConfirmed(
        suggestion: octaviaVin,
        identity: const ConfirmedVehicleIdentity(
          make: 'Skoda',
          model: 'Octavia',
          year: 2018,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(
          formatListingTransmissionType(ru, ListingTransmissionType.automatic),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('transmission clarification uses listing labels not raw codes', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.needsClarification,
        result: okResult(
          clarification: const ManualSmartFillClarification(
            attribute: 'transmission',
            options: [
              ManualSmartFillClarificationOption(value: 'manual'),
              ManualSmartFillClarificationOption(value: 'automatic'),
              ManualSmartFillClarificationOption(value: 'other'),
            ],
          ),
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingSmartFillAskTransmission), findsOneWidget);
    expect(
      find.text(formatListingTransmissionType(ru, ListingTransmissionType.manual)),
      findsOneWidget,
    );
    expect(
      find.text(
        formatListingTransmissionType(ru, ListingTransmissionType.automatic),
      ),
      findsOneWidget,
    );
    expect(find.text('M'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_option_other')),
      findsNothing,
    );
  });

  testWidgets('answered clarification never shows a second question', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await completeSkodaOctavia(tester);
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.needsClarification,
        result: okResult(
          body: 'suv',
          clarification: const ManualSmartFillClarification(
            attribute: 'fuel',
            options: [
              ManualSmartFillClarificationOption(value: 'diesel'),
              ManualSmartFillClarificationOption(value: 'petrol'),
            ],
          ),
        ),
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('create_listing_smart_fill_option_diesel')),
    );
    await emitSmartFill(
      ManualSmartFillState(
        status: ManualSmartFillStatus.filled,
        answered: true,
        result: okResult(
          body: 'suv',
          fuel: 'diesel',
          clarification: const ManualSmartFillClarification(
            attribute: 'body',
            options: [ManualSmartFillClarificationOption(value: 'wagon')],
          ),
        ),
        applyRevision: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsNothing,
    );
    verify(
      () => smartFill.answer(attribute: 'fuel', value: 'diesel'),
    ).called(1);
  });
}
