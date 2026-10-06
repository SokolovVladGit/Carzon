import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_refinement.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compact_summary.dart';
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
  final ru = ruStrings();
  const user = AuthUser(id: 'u1', email: 'seller@example.com');

  setUpAll(() {
    registerFallbackValue(
      const ManualSmartFillRefinementOption(
        id: 'fallback',
        kind: ManualSmartFillRefinementKind.body,
        candidateCount: 0,
        bodyType: 'sedan',
      ),
    );
  });

  setUp(() async {
    await sl.reset();
    createCubit = _MockCreateCubit();
    authCubit = _MockAuthCubit();
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
    stubCreateListingVinResolve(createCubit, registerSmartFill: false);
    smartFill = registerIdleManualSmartFillCubit();
    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap() {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(
          vehicleModelCatalog: FakeVehicleModelCatalogRepository(),
        ),
      ),
    );
  }

  CreateListingState confirmedState({
    required VehicleResolveSuggestion vehicle,
    required ConfirmedVehicleIdentity identity,
    int applyRevision = 1,
    String? normalizedVin = '1FTFW1E50PFA00001',
    CreateListingStatus status = CreateListingStatus.idle,
    bool confirmed = true,
    bool clearIdentity = false,
  }) {
    return CreateListingState(
      status: status,
      vehicleResolve: CreateListingVehicleResolve(
        status: confirmed
            ? CreateListingVinResolveStatus.resolved
            : CreateListingVinResolveStatus.idle,
        normalizedVin: normalizedVin,
        suggestion: VehicleResolveResult(
          resolution: VehicleResolveResolution.resolved,
          vehicle: vehicle,
          completeness: 0.8,
          warnings: const [],
        ),
        confirmed: confirmed,
        applyRevision: applyRevision,
        confirmedIdentity: clearIdentity ? null : identity,
      ),
    );
  }

  Future<StreamController<CreateListingState>> pumpPage(
    WidgetTester tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> emitConfirmed(
    WidgetTester tester,
    StreamController<CreateListingState> controller,
    CreateListingState next,
  ) async {
    when(() => createCubit.state).thenReturn(next);
    controller.add(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  void stubPeek(Result<ManualSmartFillResult> result) {
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async => result);
  }

  ManualSmartFillResult catalog({
    ManualSmartFillResolution resolution = ManualSmartFillResolution.ok,
    String? transmission,
    bool clarification = false,
    String? body,
    String? fuel,
    double? liters,
    int? power,
    String? drivetrain,
  }) {
    return ManualSmartFillResult(
      resolution: resolution,
      identity: const ManualSmartFillIdentity(
        makeKey: 'ford',
        modelKey: 'maverick',
        year: 2024,
      ),
      consensus: ManualSmartFillConsensusSpecs(
        transmissionType: transmission,
        bodyType: body,
        fuelType: fuel,
        engineDisplacementLiters: liters,
        enginePowerHp: power,
        drivetrain: drivetrain,
      ),
      nextRefinement: clarification
          ? const ManualSmartFillNextRefinement(
              kind: ManualSmartFillRefinementKind.transmission,
              options: [
                ManualSmartFillRefinementOption(
                  id: 'auto',
                  kind: ManualSmartFillRefinementKind.transmission,
                  candidateCount: 2,
                  transmissionType: 'automatic',
                ),
                ManualSmartFillRefinementOption(
                  id: 'manual',
                  kind: ManualSmartFillRefinementKind.transmission,
                  candidateCount: 1,
                  transmissionType: 'manual',
                ),
              ],
            )
          : null,
    );
  }

  const ford = ConfirmedVehicleIdentity(
    make: 'Ford',
    model: 'Maverick',
    year: 2024,
    variant: 'LARIAT',
  );

  VehicleResolveSuggestion fordVehicle({String? transmission}) {
    return VehicleResolveSuggestion(
      make: 'Ford',
      model: 'Maverick',
      year: 2024,
      trim: 'LARIAT',
      transmission: transmission,
      bodyType: 'Pickup',
      fuelType: 'Gasoline',
      driveType: 'AWD',
      displacement: '2.0 L',
    );
  }

  Finder summary() =>
      find.byKey(const ValueKey('create_listing_characteristics_summary'));

  testWidgets('VIN transmission is kept when catalog fills only power', (
    tester,
  ) async {
    stubPeek(
      Success(catalog(transmission: 'manual', power: 186)),
    );
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(
        vehicle: fordVehicle(transmission: 'Automatic'),
        identity: ford,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(ru.listingTransmissionAutomatic),
      ),
      findsOneWidget,
    );
    expect(find.text(ru.listingTransmissionManual), findsNothing);
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(formatEnginePowerHpDisplay(ru, 186)),
      ),
      findsOneWidget,
    );
    verify(
      () => smartFill.peekIdentityConsensus(
        make: 'Ford',
        model: 'Maverick',
        year: 2024,
      ),
    ).called(1);
    verifyNever(
      () => smartFill.lookup(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    );
  });

  testWidgets('null VIN transmission takes strict automatic consensus', (
    tester,
  ) async {
    stubPeek(
      Success(
        catalog(
          transmission: 'automatic',
          body: 'suv',
          fuel: 'diesel',
          liters: 3.0,
          power: 200,
          drivetrain: 'awd',
        ),
      ),
    );
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(ru.listingTransmissionAutomatic),
      ),
      findsOneWidget,
    );
    expect(find.text(ru.listingBodyTypeSuv), findsNothing);
    expect(find.text(ru.listingFuelTypeDiesel), findsNothing);
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(formatEnginePowerHpDisplay(ru, 200)),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsNothing,
    );
    verify(
      () => smartFill.peekIdentityConsensus(
        make: 'Ford',
        model: 'Maverick',
        year: 2024,
      ),
    ).called(1);
    verifyNever(
      () => smartFill.lookup(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    );
  });

  testWidgets('null VIN transmission takes strict manual consensus', (
    tester,
  ) async {
    stubPeek(Success(catalog(transmission: 'manual')));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(ru.listingTransmissionManual),
      ),
      findsOneWidget,
    );
  });

  testWidgets('null consensus leaves the three VIN facts', (tester) async {
    stubPeek(Success(catalog()));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary(),
        matching: find.text(ru.listingDrivetrainAwd),
      ),
      findsOneWidget,
    );
    expect(find.text(ru.compareRowTransmission), findsNothing);
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
    final displacement = formatEngineDisplacementForDisplay(ru, 2);
    expect(
      find.descendant(
        of: summary(),
        matching: find.text('${ru.listingFuelTypePetrol} · $displacement'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary(), matching: find.text(ru.listingFuelType)),
      findsNothing,
    );
    expect(
      find.descendant(of: summary(), matching: find.text(displacement)),
      findsNothing,
    );
    expect(
      find.descendant(of: summary(), matching: find.text('—')),
      findsNothing,
    );
    expect(
      find.descendant(of: summary(), matching: find.text('Неизвестно')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: summary(),
        matching: find.byType(CreateListingCompactSummary),
      ),
      findsNothing,
    );
  });

  testWidgets('power replaces fuel in the fourth cell without duplicating it', (
    tester,
  ) async {
    stubPeek(Success(catalog()));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_engine_power_field')),
      '150',
    );
    await tester.pump();
    final summaryFinder = summary();
    final displacement = formatEngineDisplacementForDisplay(ru, 2);
    expect(
      find.descendant(
        of: summaryFinder,
        matching: find.text(ru.compareRowPower),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summaryFinder,
        matching: find.text(formatEnginePowerHpDisplay(ru, 150)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summaryFinder,
        matching: find.text('${ru.listingFuelTypePetrol} · $displacement'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summaryFinder,
        matching: find.text(ru.listingFuelType),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: summaryFinder,
        matching: find.text(ru.compareRowTransmission),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Offstage>(
            find.byKey(const ValueKey('create_listing_additional_details')),
          )
          .offstage,
      isFalse,
    );
  });

  testWidgets('clarification does not ask and does not fill transmission', (
    tester,
  ) async {
    stubPeek(Success(catalog(transmission: 'automatic', clarification: true)));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.compareRowTransmission), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsNothing,
    );
  });

  testWidgets('noData leaves transmission empty and publish available', (
    tester,
  ) async {
    stubPeek(Success(catalog(resolution: ManualSmartFillResolution.noData)));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.compareRowTransmission), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_publish_section')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failure leaves transmission empty and publish available', (
    tester,
  ) async {
    stubPeek(const FailureResult(ServerFailure('catalog down')));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.compareRowTransmission), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_publish_section')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('seller edit in flight rejects the late catalog value', (
    tester,
  ) async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) => pending.future);
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    await tester.tap(
      find.byKey(const ValueKey('create_listing_transmission_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.listingTransmissionManual).last);
    await tester.pumpAndSettle();
    pending.complete(Success(catalog(transmission: 'automatic')));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionManual), findsWidgets);
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
  });

  testWidgets('a newer VIN identity rejects the previous consensus', (
    tester,
  ) async {
    final pending = <Completer<Result<ManualSmartFillResult>>>[];
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) {
      final next = Completer<Result<ManualSmartFillResult>>();
      pending.add(next);
      return next.future;
    });
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pump();
    const toyota = ConfirmedVehicleIdentity(
      make: 'Toyota',
      model: 'Corolla',
      year: 2022,
    );
    await emitConfirmed(
      tester,
      controller,
      confirmedState(
        vehicle: const VehicleResolveSuggestion(
          make: 'Toyota',
          model: 'Corolla',
          year: 2022,
          bodyType: 'Sedan',
          fuelType: 'Gasoline',
          driveType: 'FWD',
          displacement: '1.8 L',
        ),
        identity: toyota,
        applyRevision: 2,
        normalizedVin: '2T1BURHE0NC000001',
      ),
    );
    pending.first.complete(Success(catalog(transmission: 'automatic')));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
    pending.last.complete(Success(catalog()));
    await tester.pumpAndSettle();
    expect(find.text(ru.compareRowTransmission), findsNothing);
    verify(
      () => smartFill.peekIdentityConsensus(
        make: 'Ford',
        model: 'Maverick',
        year: 2024,
      ),
    ).called(1);
    verify(
      () => smartFill.peekIdentityConsensus(
        make: 'Toyota',
        model: 'Corolla',
        year: 2022,
      ),
    ).called(1);
  });

  testWidgets('clearing VIN rejects an in-flight consensus', (tester) async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) => pending.future);
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await emitConfirmed(
      tester,
      controller,
      confirmedState(
        vehicle: fordVehicle(),
        identity: ford,
        confirmed: false,
        clearIdentity: true,
        normalizedVin: null,
      ),
    );
    pending.complete(Success(catalog(transmission: 'automatic')));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
  });

  testWidgets('account change drops the in-flight consensus', (tester) async {
    final authEvents = StreamController<AuthState>();
    addTearDown(authEvents.close);
    whenListen(
      authCubit,
      authEvents.stream,
      initialState: const AuthState.authenticated(user),
    );
    final pending = Completer<Result<ManualSmartFillResult>>();
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) => pending.future);
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    const other = AuthUser(id: 'u2', email: 'other@example.com');
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.authenticated(other));
    authEvents.add(const AuthState.authenticated(other));
    await tester.pumpAndSettle();
    pending.complete(Success(catalog(transmission: 'automatic')));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
  });

  testWidgets('submitting rejects a late consensus', (tester) async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    when(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) => pending.future);
    final controller = await pumpPage(tester);
    final confirmed = confirmedState(vehicle: fordVehicle(), identity: ford);
    await emitConfirmed(tester, controller, confirmed);
    final submitting = CreateListingState(
      status: CreateListingStatus.submitting,
      vehicleResolve: confirmed.vehicleResolve,
    );
    await emitConfirmed(tester, controller, submitting);
    pending.complete(Success(catalog(transmission: 'automatic')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
  });

  testWidgets('a later VIN transmission replaces catalog consensus', (
    tester,
  ) async {
    stubPeek(Success(catalog(transmission: 'automatic')));
    final controller = await pumpPage(tester);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(vehicle: fordVehicle(), identity: ford),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionAutomatic), findsWidgets);
    await emitConfirmed(
      tester,
      controller,
      confirmedState(
        vehicle: fordVehicle(transmission: 'Manual'),
        identity: ford,
        applyRevision: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionManual), findsWidgets);
    expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
  });

  testWidgets('manual identity does not start the VIN fallback', (
    tester,
  ) async {
    await pumpPage(tester);
    await openCreateListingManualIdentity(tester);
    verifyNever(
      () => smartFill.peekIdentityConsensus(
        make: any(named: 'make'),
        model: any(named: 'model'),
        year: any(named: 'year'),
      ),
    );
    expect(
      find.byKey(const ValueKey('create_listing_smart_fill_clarification')),
      findsNothing,
    );
  });
}
