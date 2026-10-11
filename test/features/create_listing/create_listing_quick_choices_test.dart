import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_refinement.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_state.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/models/create_listing_quick_choices.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_characteristic_quick_picks.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
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
  final ru = ruStrings();
  final ro = roStrings();

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

  group('createListingMissingQuickChoices', () {
    test('Corolla decode leaves only drivetrain', () {
      final missing = createListingMissingQuickChoices(
        const CreateListingQuickChoiceValues(
          transmissionType: ListingTransmissionType.cvt,
          doors: 4,
          seats: 5,
          engineCylinders: 4,
        ),
      );
      expect(missing, [CreateListingQuickChoiceKind.drivetrain]);
    });

    test('body and fuel alone still offer every quick-choice field', () {
      expect(
        createListingMissingQuickChoices(
          const CreateListingQuickChoiceValues(),
        ),
        CreateListingQuickChoiceKind.values,
      );
    });

    test('a filled field is not asked again', () {
      final missing = createListingMissingQuickChoices(
        const CreateListingQuickChoiceValues(
          drivetrain: ListingDrivetrain.fwd,
          transmissionType: ListingTransmissionType.manual,
          doors: 2,
          seats: 2,
          engineCylinders: 6,
        ),
      );
      expect(missing, isEmpty);
    });

    test('visibility follows step, identity, resolve, and gaps', () {
      const gap = [CreateListingQuickChoiceKind.drivetrain];
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: true,
          vinConfirmed: true,
          manualIdentityReady: false,
          resolving: false,
          missing: gap,
        ),
        isTrue,
      );
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: true,
          vinConfirmed: false,
          manualIdentityReady: true,
          resolving: false,
          missing: gap,
        ),
        isTrue,
      );
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: false,
          vinConfirmed: true,
          manualIdentityReady: true,
          resolving: false,
          missing: gap,
        ),
        isFalse,
      );
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: true,
          vinConfirmed: false,
          manualIdentityReady: false,
          resolving: false,
          missing: gap,
        ),
        isFalse,
      );
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: true,
          vinConfirmed: true,
          manualIdentityReady: false,
          resolving: true,
          missing: gap,
        ),
        isFalse,
      );
      expect(
        createListingQuickChoicesVisible(
          onCharacteristicsStep: true,
          vinConfirmed: true,
          manualIdentityReady: false,
          resolving: false,
          missing: const [],
        ),
        isFalse,
      );
    });

    test(
      'one or two questions stay visible and a longer tail stays counted',
      () {
        const one = [CreateListingQuickChoiceKind.drivetrain];
        const two = [
          CreateListingQuickChoiceKind.drivetrain,
          CreateListingQuickChoiceKind.transmission,
        ];
        final five = CreateListingQuickChoiceKind.values;

        expect(createListingVisibleQuickChoices(one, extrasOpen: false), one);
        expect(createListingHiddenQuickChoiceCount(two, extrasOpen: false), 0);
        expect(
          createListingVisibleQuickChoices(five, extrasOpen: false),
          five.take(2).toList(),
        );
        expect(createListingHiddenQuickChoiceCount(five, extrasOpen: false), 3);
        expect(createListingVisibleQuickChoices(five, extrasOpen: true), five);
        expect(createListingHiddenQuickChoiceCount(five, extrasOpen: true), 0);
      },
    );

    test('common counts stay inside the database ranges', () {
      bool inside(List<int> values, int max) =>
          values.every((n) => n >= 1 && n <= max);
      expect(inside(kCreateListingCommonCylinders, 16), isTrue);
      expect(inside(kCreateListingCommonDoors, 6), isTrue);
      expect(inside(kCreateListingCommonSeats, 15), isTrue);
      expect(kCreateListingCommonCylinders, isNot(contains(16)));
      expect(kCreateListingCommonDoors, isNot(contains(1)));
      expect(kCreateListingCommonSeats, contains(5));
      expect(
        createListingQuickCountMax(CreateListingQuickChoiceKind.cylinders),
        16,
      );
      expect(createListingQuickCountMax(CreateListingQuickChoiceKind.doors), 6);
      expect(
        createListingQuickCountMax(CreateListingQuickChoiceKind.seats),
        15,
      );
    });
  });

  group('CreateListingCharacteristicQuickPicks', () {
    Future<void> pumpHost(
      WidgetTester tester, {
      ThemeData? theme,
      Locale locale = const Locale('ru'),
      Size size = const Size(390, 800),
      bool enabled = true,
      ListingDrivetrain? drivetrain,
      ListingTransmissionType? transmission,
      int? doors,
      int? seats,
      int? cylinders,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _QuickPickHost(
              key: ValueKey(
                '${theme?.brightness}-${locale.languageCode}-$size-'
                '${drivetrain?.name}-${transmission?.name}-'
                '$doors-$seats-$cylinders',
              ),
              enabled: enabled,
              drivetrain: drivetrain,
              transmission: transmission,
              doors: doors,
              seats: seats,
              cylinders: cylinders,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows one or two questions immediately', (tester) async {
      await pumpHost(
        tester,
        transmission: ListingTransmissionType.cvt,
        doors: 4,
        seats: 5,
        cylinders: 4,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(find.text(ru.createListingQuickChoiceHint), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
        findsOneWidget,
      );

      await pumpHost(tester, doors: 4, seats: 5, cylinders: 4);
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskTransmission),
        findsOneWidget,
      );
      expect(find.text(ru.createListingQuickChoiceHint), findsNothing);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
        findsNothing,
      );
    });

    testWidgets('three or more questions keep a counted tail', (tester) async {
      await pumpHost(tester, seats: 5, cylinders: 4);
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskTransmission),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(1)),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_choices_collapse')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
        findsNothing,
      );
    });

    testWidgets('one tap removes that question and keeps the value', (
      tester,
    ) async {
      await pumpHost(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsNothing,
      );
      expect(find.text(ru.listingDrivetrainFwd), findsNothing);
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_transmission_cvt')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_doors_4')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );
    });

    testWidgets('count picker offers every supported cylinder', (tester) async {
      await pumpHost(tester);
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
      );
      await tester.pumpAndSettle();
      final more = find.byKey(
        const ValueKey('create_listing_quick_cylinders_more'),
      );
      await tester.scrollUntilVisible(more, 120);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_16')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_17')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_count_16')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_cylinders')),
        findsNothing,
      );
    });

    testWidgets('Romanian copy and both themes stay inside narrow widths', (
      tester,
    ) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        for (final width in [320.0, 375.0, 390.0]) {
          await pumpHost(
            tester,
            theme: theme,
            locale: const Locale('ro'),
            size: Size(width, 700),
          );
          expect(
            find.text(ro.createListingQuickChoiceAskDrivetrain),
            findsOneWidget,
          );
          expect(
            find.text(ro.createListingQuickChoicesMoreCount(3)),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('create_listing_quick_choices_more')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final chip = find.byKey(
            const ValueKey('create_listing_quick_drivetrain_fwd'),
          );
          expect(chip, findsOneWidget);
          final label = tester.widget<Text>(
            find.descendant(of: chip, matching: find.byType(Text)),
          );
          expect(label.style?.color, isNot(theme.colorScheme.primary));
          final action = tester.widget<Text>(
            find.descendant(
              of: find.byKey(
                const ValueKey('create_listing_quick_choices_collapse'),
              ),
              matching: find.text(ro.createListingQuickChoicesCollapse),
            ),
          );
          expect(action.style?.color, isNot(theme.colorScheme.primary));
        }
      }
    });
  });

  group('CreateListingPage quick choices', () {
    late _MockCreateCubit createCubit;
    late _MockAuthCubit authCubit;
    late MockManualSmartFillCubit smartFill;
    late FakeVehicleModelCatalogRepository catalog;
    late StreamController<CreateListingState> states;
    late StreamController<ManualSmartFillState> smartFillEvents;

    setUp(() async {
      await sl.reset();
      catalog = FakeVehicleModelCatalogRepository(
        modelsByMake: {
          ...FakeVehicleModelCatalogRepository.defaults,
          'skoda': ['Fabia', 'Octavia'],
        },
      );
      smartFillEvents = StreamController<ManualSmartFillState>.broadcast();
      createCubit = _MockCreateCubit();
      authCubit = _MockAuthCubit();
      states = StreamController<CreateListingState>();
      when(() => createCubit.state).thenReturn(const CreateListingState.idle());
      whenListen(
        createCubit,
        states.stream,
        initialState: const CreateListingState.idle(),
      );
      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.authenticated(user));
      whenListen(
        authCubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );
      stubCreateListingVinResolve(createCubit, registerSmartFill: false);
      smartFill = registerIdleManualSmartFillCubit(
        states: smartFillEvents.stream,
      );
      CreateListingPage.debugRevealAllSteps = false;
      sl.registerFactory<CreateListingCubit>(() => createCubit);
    });

    tearDown(() async {
      CreateListingPage.debugRevealAllSteps = false;
      await states.close();
      await smartFillEvents.close();
      await sl.reset();
    });

    Widget wrap() {
      return MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: CreateListingPage(vehicleModelCatalog: catalog),
        ),
      );
    }

    Future<void> pump(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
    }

    Future<void> emit(
      WidgetTester tester,
      CreateListingState state, {
      bool settle = true,
    }) async {
      when(() => createCubit.state).thenReturn(state);
      states.add(state);
      if (!settle) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        return;
      }
      await tester.pumpAndSettle();
    }

    Future<void> tapContinue(WidgetTester tester) async {
      await tester.tap(
        find.byKey(const ValueKey('create_listing_step_continue')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> revealExtras(WidgetTester tester) async {
      final more = find.byKey(
        const ValueKey('create_listing_quick_choices_more'),
      );
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
    }

    CreateListingState resolveOf({
      required VehicleResolveResult suggestion,
      bool confirmed = true,
      CreateListingVinResolveStatus status =
          CreateListingVinResolveStatus.resolved,
      int applyRevision = 1,
    }) {
      final vehicle = suggestion.vehicle;
      return CreateListingState(
        vehicleResolve: CreateListingVehicleResolve(
          status: status,
          normalizedVin: '5YFEPMAE9NP386546',
          suggestion: suggestion,
          confirmed: confirmed,
          applyRevision: applyRevision,
          confirmedIdentity: ConfirmedVehicleIdentity(
            make: vehicle.make!,
            model: vehicle.model!,
            year: vehicle.year!,
            variant: vehicle.trim,
          ),
        ),
      );
    }

    testWidgets('Corolla asks only for drivetrain and keeps a seller FWD', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );
      await emit(tester, resolveOf(suggestion: _corolla));
      await tapContinue(tester);

      expect(
        find.byKey(const ValueKey('create_listing_characteristics_section')),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromVinAndSeller),
        findsNothing,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(find.text(ru.createListingQuickChoiceHint), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices_more')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.byType(Text),
        ),
        findsNWidgets(12),
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingTransmissionCvt),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_seats')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_cylinders')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingDrivetrainFwd),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromVinAndSeller),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.byType(Text),
        ),
        findsNWidgets(14),
      );

      await emit(
        tester,
        resolveOf(suggestion: _corollaWith(driveType: 'AWD'), applyRevision: 2),
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingDrivetrainFwd),
        ),
        findsOneWidget,
      );
      expect(find.text(ru.listingDrivetrainAwd), findsNothing);

      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_price_field')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingDrivetrainFwd),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sparse VIN offers the missing fields and can be skipped', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _sparse));
      await tapContinue(tester);
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskTransmission),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(3)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );
      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_price_field')),
        findsOneWidget,
      );
      expect(find.text(ru.validationRequired), findsNothing);
    });

    testWidgets('manual transmission survives a late catalog fill', (
      tester,
    ) async {
      final gate = Completer<Result<ManualSmartFillResult>>();
      when(
        () => smartFill.peekIdentityConsensus(
          make: any(named: 'make'),
          model: any(named: 'model'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) => gate.future);

      await pump(tester);
      await emit(tester, resolveOf(suggestion: _sparse));
      await tapContinue(tester);
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_transmission_manual')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(2)),
        findsOneWidget,
      );

      gate.complete(
        const Success(
          ManualSmartFillResult(
            resolution: ManualSmartFillResolution.ok,
            identity: ManualSmartFillIdentity(
              makeKey: 'toyota',
              modelKey: 'corolla',
              year: 2022,
            ),
            consensus: ManualSmartFillConsensusSpecs(
              transmissionType: 'automatic',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingTransmissionManual),
        ),
        findsOneWidget,
      );
      expect(find.text(ru.listingTransmissionAutomatic), findsNothing);
    });

    testWidgets('clearing a count brings that choice back', (tester) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _sparse));
      await tapContinue(tester);
      await revealExtras(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_doors_4')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_doors_4')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );

      final edit = find.byKey(
        const ValueKey('create_listing_edit_characteristics'),
      );
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final doors = find.byKey(const ValueKey('create_listing_doors_field'));
      await tester.ensureVisible(doors);
      await tester.enterText(doors, '');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
    });

    testWidgets('hides while unconfirmed, resolving, or already complete', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _sparse));
      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsOneWidget,
      );

      await emit(
        tester,
        resolveOf(
          suggestion: _sparse,
          status: CreateListingVinResolveStatus.resolving,
        ),
        settle: false,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );

      await emit(
        tester,
        resolveOf(
          suggestion: _sparse,
          confirmed: false,
          status: CreateListingVinResolveStatus.manual,
        ),
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );
      await tapContinue(tester);

      await emit(tester, resolveOf(suggestion: _complete, applyRevision: 2));
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromVinAndSeller),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
          ),
          matching: find.text(ru.listingDrivetrainFwd),
        ),
        findsOneWidget,
      );
    });

    Future<void> emitSmartFill(ManualSmartFillState next) async {
      when(() => smartFill.state).thenReturn(next);
      smartFillEvents.add(next);
    }

    Future<void> chooseFabia2025(WidgetTester tester) async {
      await openCreateListingManualIdentity(tester);
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Skoda'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('create_listing_model_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Fabia')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
      await tester.pumpAndSettle();
      final newest = DateTime.now().year + 1;
      final picker = find.byType(CupertinoPicker);
      await tester.drag(picker, Offset(0, -40.0 * (newest - 2025)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.commonDone));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_year_field')),
          matching: find.text('2025'),
        ),
        findsOneWidget,
      );
    }

    ManualSmartFillState fabiaFilled({
      String? body = 'wagon',
      String? fuel = 'petrol',
      double? liters = 1,
      int? hp = 60,
      String? transmission,
      List<ManualSmartFillRefinementAnswer> answers = const [
        ManualSmartFillRefinementAnswer(
          kind: ManualSmartFillRefinementKind.body,
          optionId: 'body-wagon',
        ),
        ManualSmartFillRefinementAnswer(
          kind: ManualSmartFillRefinementKind.engine,
          optionId: 'eng-60',
        ),
      ],
      int applyRevision = 1,
      ManualSmartFillStatus status = ManualSmartFillStatus.filled,
    }) {
      return ManualSmartFillState(
        status: status,
        query: const ManualSmartFillQuery(
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
        ),
        answers: answers,
        result: ManualSmartFillResult(
          resolution: ManualSmartFillResolution.ok,
          identity: const ManualSmartFillIdentity(
            makeKey: 'skoda',
            modelKey: 'fabia',
            year: 2025,
          ),
          consensus: ManualSmartFillConsensusSpecs(
            bodyType: body,
            fuelType: fuel,
            engineDisplacementLiters: liters,
            enginePowerHp: hp,
            transmissionType: transmission,
          ),
        ),
        applyRevision: applyRevision,
      );
    }

    Finder summaryText(String text) {
      return find.descendant(
        of: find.byKey(
          const ValueKey('create_listing_characteristics_summary'),
        ),
        matching: find.text(text),
      );
    }

    testWidgets('manual Fabia shows catalog facts and seller quick choices', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices')),
        findsNothing,
      );
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsNothing,
      );
      await tapContinue(tester);

      final engine =
          '${formatListingFuelType(ru, ListingFuelType.petrol)} · ${formatEngineDisplacementForDisplay(ru, 1)}';
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
      expect(summaryText(engine), findsOneWidget);
      expect(summaryText(formatEnginePowerHpDisplay(ru, 60)), findsOneWidget);
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskTransmission),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(3)),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromCatalogAndSeller),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromVinAndSeller),
        findsNothing,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.pumpAndSettle();
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsNothing,
      );
      expect(summaryText(engine), findsOneWidget);
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(2)),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromCatalogAndSeller),
        findsOneWidget,
      );

      await revealExtras(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_cylinders_more')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_cylinders_more')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_count_16')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_count_3')),
      );
      await tester.pumpAndSettle();
      expect(summaryText('3'), findsOneWidget);

      await tapContinue(tester);
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(summaryText('3'), findsOneWidget);
      expect(
        find.text(ru.createListingCharacteristicsFilledFromCatalogAndSeller),
        findsOneWidget,
      );

      await emitSmartFill(fabiaFilled(body: 'sedan', applyRevision: 2));
      await tester.pumpAndSettle();
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsNothing,
      );

      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_price_field')),
        findsOneWidget,
      );
      expect(find.text(ru.validationRequired), findsNothing);
    });

    testWidgets('catalog transmission is not asked again', (tester) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(fabiaFilled(transmission: 'manual'));
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_transmission')),
        findsNothing,
      );
      expect(
        summaryText(
          formatListingTransmissionType(ru, ListingTransmissionType.manual),
        ),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingQuickChoiceAskDrivetrain),
        findsOneWidget,
      );
    });

    testWidgets('no catalog match still offers every quick choice', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(
        const ManualSmartFillState(
          status: ManualSmartFillStatus.noData,
          query: ManualSmartFillQuery(
            make: 'Skoda',
            model: 'Fabia',
            year: 2025,
          ),
          result: ManualSmartFillResult(
            resolution: ManualSmartFillResolution.noData,
            identity: ManualSmartFillIdentity(
              makeKey: 'skoda',
              modelKey: 'fabia',
              year: 2025,
            ),
            consensus: ManualSmartFillConsensusSpecs(),
          ),
          applyRevision: 1,
        ),
      );
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(
        find.text(ru.createListingQuickChoicesMoreCount(3)),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsNothing,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromCatalogAndSeller),
        findsNothing,
      );
      await tapContinue(tester);
      expect(find.text(ru.validationRequired), findsNothing);
    });

    testWidgets('skipped Smart Fill body is not invented', (tester) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(
        fabiaFilled(
          body: null,
          fuel: 'petrol',
          liters: 1,
          hp: 60,
          answers: const [],
          status: ManualSmartFillStatus.filled,
        ),
      );
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsOneWidget,
      );
    });

    testWidgets('a different manual identity drops Smart Fill choices', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('create_listing_model_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledFromCatalogAndSeller),
        findsNothing,
      );
    });

    testWidgets(
      'same VIN keeps a Smart Fill body and a different VIN drops it',
      (tester) async {
        await pump(tester);
        await chooseFabia2025(tester);
        await emitSmartFill(fabiaFilled());
        await tester.pumpAndSettle();
        await tapContinue(tester);
        expect(
          summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
          findsOneWidget,
        );

        await emit(
          tester,
          CreateListingState(
            vehicleResolve: CreateListingVehicleResolve(
              status: CreateListingVinResolveStatus.resolved,
              normalizedVin: 'TMBJB7NE5E0000001',
              confirmed: true,
              applyRevision: 1,
              suggestion: const VehicleResolveResult(
                resolution: VehicleResolveResolution.resolved,
                vehicle: VehicleResolveSuggestion(
                  make: 'Skoda',
                  model: 'Fabia',
                  year: 2025,
                  bodyType: 'Sedan',
                  fuelType: 'Gasoline',
                ),
                completeness: 0.8,
                warnings: [],
              ),
              confirmedIdentity: const ConfirmedVehicleIdentity(
                make: 'Skoda',
                model: 'Fabia',
                year: 2025,
              ),
            ),
          ),
        );
        expect(
          summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
          findsOneWidget,
        );
        expect(
          summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
          findsNothing,
        );

        await emit(
          tester,
          const CreateListingState(
            vehicleResolve: CreateListingVehicleResolve(
              status: CreateListingVinResolveStatus.resolved,
              normalizedVin: '5YFEPMAE9NP386546',
              confirmed: true,
              applyRevision: 2,
              suggestion: VehicleResolveResult(
                resolution: VehicleResolveResolution.resolved,
                vehicle: VehicleResolveSuggestion(
                  make: 'Toyota',
                  model: 'Corolla',
                  year: 2022,
                  bodyType: 'Sedan',
                ),
                completeness: 0.8,
                warnings: [],
              ),
              confirmedIdentity: ConfirmedVehicleIdentity(
                make: 'Toyota',
                model: 'Corolla',
                year: 2022,
              ),
            ),
          ),
        );
        expect(
          summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
          findsNothing,
        );
        expect(
          summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
          findsOneWidget,
        );
      },
    );

    Future<void> selectFwd(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.tap(
        find.byKey(const ValueKey('create_listing_quick_drivetrain_fwd')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> goBack(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
    }

    Future<void> chooseCorolla(WidgetTester tester) async {
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('create_listing_model_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
      await tester.pumpAndSettle();
    }

    String textOf(WidgetTester tester, String key, {bool skipOffstage = true}) {
      return tester
              .widget<TextFormField>(
                find.byKey(ValueKey(key), skipOffstage: skipOffstage),
              )
              .controller
              ?.text ??
          '';
    }

    Future<void> openCharacteristicsEditor(WidgetTester tester) async {
      final edit = find.byKey(
        const ValueKey('create_listing_edit_characteristics'),
      );
      await tester.ensureVisible(edit.last);
      await tester.tap(edit.last);
      await tester.pumpAndSettle();
    }

    CreateListingState confirmedIdentity({
      required String vin,
      required String make,
      required String model,
      required int year,
      required int revision,
      String? bodyType,
      String? fuelType,
      String? driveType,
      String? displacement,
      String? transmission,
      String? doors,
      String? cylinders,
      String? seats,
    }) {
      return CreateListingState(
        vehicleResolve: CreateListingVehicleResolve(
          status: CreateListingVinResolveStatus.resolved,
          normalizedVin: vin,
          confirmed: true,
          applyRevision: revision,
          suggestion: VehicleResolveResult(
            resolution: VehicleResolveResolution.resolved,
            vehicle: VehicleResolveSuggestion(
              make: make,
              model: model,
              year: year,
              bodyType: bodyType,
              fuelType: fuelType,
              driveType: driveType,
              displacement: displacement,
              transmission: transmission,
              doors: doors,
              cylinders: cylinders,
              seats: seats,
            ),
            completeness: 0.8,
            warnings: [],
          ),
          confirmedIdentity: ConfirmedVehicleIdentity(
            make: make,
            model: model,
            year: year,
          ),
        ),
      );
    }

    testWidgets('manual Fabia to manual Corolla drops technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      final variant = find.byKey(
        const ValueKey('create_listing_variant_field'),
      );
      await tester.ensureVisible(variant);
      await tester.enterText(variant, 'Monte Carlo');
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      await selectFwd(tester);
      await openCharacteristicsEditor(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_doors_field')),
        '5',
      );
      await tester.pumpAndSettle();
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );

      await goBack(tester);
      await chooseCorolla(tester);
      await tapContinue(tester);

      expect(summaryText(ru.listingDrivetrainFwd), findsNothing);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
      expect(textOf(tester, 'create_listing_doors_field'), isEmpty);
      expect(
        textOf(tester, 'create_listing_variant_field', skipOffstage: false),
        isEmpty,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsOneWidget,
      );
      await emitSmartFill(fabiaFilled(applyRevision: 2));
      await tester.pumpAndSettle();
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
    });

    testWidgets('manual year change drops technical facts', (tester) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.commonDone));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_year_field')),
          matching: find.text('2024'),
        ),
        findsOneWidget,
      );
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsNothing);
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsOneWidget,
      );
    });

    testWidgets('manual model change drops technical facts', (tester) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      await tester.tap(
        find.byKey(const ValueKey('create_listing_model_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Octavia')));
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsNothing);
    });

    testWidgets('manual make change drops technical facts', (tester) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('create_listing_characteristics_summary'),
            skipOffstage: false,
          ),
          matching: find.text(ru.listingDrivetrainFwd, skipOffstage: false),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('matching confirmed VIN keeps seller technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      await selectFwd(tester);
      await emit(
        tester,
        confirmedIdentity(
          vin: 'TMBJB7NE5E0000001',
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
          revision: 1,
          bodyType: 'Sedan',
          driveType: 'AWD',
        ),
      );
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsNothing,
      );
      expect(find.text(ru.listingDrivetrainAwd), findsNothing);
    });

    testWidgets('different confirmed VIN replaces manual technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      await selectFwd(tester);
      await emit(tester, resolveOf(suggestion: _corolla));
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsNothing);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
      expect(
        find.text(ru.createListingCharacteristicsFilledAutomatically),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_drivetrain')),
        findsOneWidget,
      );
    });

    testWidgets('different VIN with the same make model year still resets', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await emit(
        tester,
        confirmedIdentity(
          vin: 'TMBJB7NE5E0000001',
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
          revision: 1,
          bodyType: 'Hatchback',
        ),
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      await emit(
        tester,
        confirmedIdentity(
          vin: 'TMBJB7NE5E0000002',
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
          revision: 2,
          bodyType: 'Sedan',
          doors: '4',
        ),
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsNothing);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
      expect(summaryText('4'), findsOneWidget);
    });

    testWidgets('same VIN re-resolution keeps seller facts', (tester) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _corolla));
      await tapContinue(tester);
      await selectFwd(tester);
      await expandCreateListingAdditionalDetails(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_doors_field')),
        '3',
      );
      await tester.pumpAndSettle();
      await emit(
        tester,
        resolveOf(suggestion: _corollaWith(driveType: 'AWD'), applyRevision: 2),
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(find.text(ru.listingDrivetrainAwd), findsNothing);
      expect(textOf(tester, 'create_listing_doors_field'), '3');
    });

    void expectNoSmartFillRestart() {
      verifyNever(
        () => smartFill.lookup(
          make: any(named: 'make'),
          model: any(named: 'model'),
          year: any(named: 'year'),
        ),
      );
      verifyNever(smartFill.reset);
    }

    testWidgets('reselecting the same make keeps model year and facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      final variant = find.byKey(
        const ValueKey('create_listing_variant_field'),
      );
      await tester.ensureVisible(variant);
      await tester.enterText(variant, 'Monte Carlo');
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      await selectFwd(tester);
      await openCharacteristicsEditor(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_doors_field')),
        '5',
      );
      await tester.pumpAndSettle();
      await goBack(tester);
      clearInteractions(smartFill);
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Skoda'));
      await tester.pumpAndSettle();
      expectNoSmartFillRestart();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_model_field')),
          matching: find.text('Fabia'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_year_field')),
          matching: find.text('2025'),
        ),
        findsOneWidget,
      );
      expect(textOf(tester, 'create_listing_variant_field'), 'Monte Carlo');
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
      expect(textOf(tester, 'create_listing_doors_field'), '5');
    });

    testWidgets('reselecting the same year keeps technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await emitSmartFill(fabiaFilled());
      await tester.pumpAndSettle();
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      clearInteractions(smartFill);
      await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.commonDone));
      await tester.pumpAndSettle();
      expectNoSmartFillRestart();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_year_field')),
          matching: find.text('2025'),
        ),
        findsOneWidget,
      );
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsOneWidget,
      );
    });

    testWidgets('same manual identity re-entry keeps technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      final variant = find.byKey(
        const ValueKey('create_listing_variant_field'),
      );
      await tester.ensureVisible(variant);
      await tester.enterText(variant, 'Monte Carlo');
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      clearInteractions(smartFill);
      await tester.tap(
        find.byKey(const ValueKey('create_listing_model_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Fabia')));
      await tester.pumpAndSettle();
      expectNoSmartFillRestart();
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      expect(
        textOf(tester, 'create_listing_variant_field', skipOffstage: false),
        'Monte Carlo',
      );
    });

    testWidgets('failed VIN resolution keeps existing technical facts', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await goBack(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_vin_field')),
        'TMBJB7NE5E0000001',
      );
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      await emit(
        tester,
        const CreateListingState(
          vehicleResolve: CreateListingVehicleResolve(
            status: CreateListingVinResolveStatus.failure,
            normalizedVin: 'TMBJB7NE5E0000001',
            confirmed: false,
          ),
        ),
      );
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
    });

    testWidgets('step navigation keeps technical facts and offer values', (
      tester,
    ) async {
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await tapContinue(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_price_field')),
        '9000',
      );
      await tester.pumpAndSettle();
      await goBack(tester);
      expect(summaryText(ru.listingDrivetrainFwd), findsOneWidget);
      await tapContinue(tester);
      expect(textOf(tester, 'create_listing_price_field'), '9000');
    });

    testWidgets('late old catalog result is ignored', (tester) async {
      var peeks = 0;
      final late = Completer<Result<ManualSmartFillResult>>();
      when(
        () => smartFill.peekIdentityConsensus(
          make: any(named: 'make'),
          model: any(named: 'model'),
          year: any(named: 'year'),
        ),
      ).thenAnswer((_) {
        peeks += 1;
        if (peeks == 1) return late.future;
        return Future<Result<ManualSmartFillResult>>.value(
          const Success(
            ManualSmartFillResult(
              resolution: ManualSmartFillResolution.noData,
              identity: ManualSmartFillIdentity(
                makeKey: 'toyota',
                modelKey: 'corolla',
                year: 2022,
              ),
              consensus: ManualSmartFillConsensusSpecs(),
            ),
          ),
        );
      });
      await pump(tester);
      await emit(
        tester,
        confirmedIdentity(
          vin: 'TMBJB7NE5E0000001',
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
          revision: 1,
        ),
      );
      await tapContinue(tester);
      expect(peeks, 1);
      await emit(tester, resolveOf(suggestion: _corolla, applyRevision: 2));
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
      late.complete(
        const Success(
          ManualSmartFillResult(
            resolution: ManualSmartFillResolution.ok,
            identity: ManualSmartFillIdentity(
              makeKey: 'skoda',
              modelKey: 'fabia',
              year: 2025,
            ),
            consensus: ManualSmartFillConsensusSpecs(bodyType: 'wagon'),
          ),
        ),
      );
      await tester.pump();
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
    });

    testWidgets('late old VIN result is ignored', (tester) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _corolla, applyRevision: 2));
      await tapContinue(tester);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
      expect(summaryText(ru.listingTransmissionCvt), findsOneWidget);
      await emit(
        tester,
        confirmedIdentity(
          vin: 'TMBJB7NE5E0000001',
          make: 'Skoda',
          model: 'Fabia',
          year: 2025,
          revision: 1,
          bodyType: 'Wagon',
        ),
      );
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.sedan)),
        findsOneWidget,
      );
      expect(summaryText(ru.listingTransmissionCvt), findsOneWidget);
      expect(
        summaryText(formatListingBodyType(ru, ListingBodyType.wagon)),
        findsNothing,
      );
    });

    testWidgets('preview and submission keep only the current vehicle', (
      tester,
    ) async {
      when(
        () => createCubit.submit(
          listingInput: any(named: 'listingInput'),
          orderedPhotos: any(named: 'orderedPhotos'),
        ),
      ).thenAnswer((_) async {});
      CreateListingPage.debugRevealAllSteps = true;
      await pump(tester);
      await chooseFabia2025(tester);
      await tapContinue(tester);
      await selectFwd(tester);
      await expandCreateListingAdditionalDetails(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_doors_field')),
        '5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_description_field')),
        'Оставить описание',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_price_field')),
        '9000',
      );
      await revealCreateListingMileageField(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_mileage_field')),
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
      await tester.pumpAndSettle();
      await emit(tester, resolveOf(suggestion: _corolla));
      expect(
        textOf(tester, 'create_listing_description_field'),
        'Оставить описание',
      );
      expect(textOf(tester, 'create_listing_price_field'), '9000');
      final specs = tester.widget<Text>(
        find.byKey(ListingPreviewCard.specsKey),
      );
      expect(specs.data, isNot(contains(ru.listingDrivetrainFwd)));
      expect(
        specs.data,
        contains(formatListingBodyType(ru, ListingBodyType.sedan)),
      );
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
      expect(submitted.make, 'Toyota');
      expect(submitted.model, 'Corolla');
      expect(submitted.drivetrain, isNull);
      expect(submitted.doors, 4);
      expect(submitted.bodyType, ListingBodyType.sedan);
      expect(submitted.description, 'Оставить описание');
      expect(submitted.priceEur, 9000);
    });

    testWidgets('expansion survives a step change', (tester) async {
      await pump(tester);
      await emit(tester, resolveOf(suggestion: _sparse));
      await tapContinue(tester);
      await revealExtras(tester);
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
      await tapContinue(tester);
      expect(
        find.byKey(const ValueKey('create_listing_price_field')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create_listing_quick_field_doors')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_quick_choices_collapse')),
        findsOneWidget,
      );
    });
  });
}

const _corolla = VehicleResolveResult(
  resolution: VehicleResolveResolution.resolved,
  vehicle: VehicleResolveSuggestion(
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    trim: 'LE',
    bodyType: 'Sedan/Saloon',
    fuelType: 'Gasoline',
    displacement: '1.8',
    transmission: 'Continuously Variable Transmission (CVT)',
    driveType: '4x2',
    cylinders: '4',
    doors: '4',
    seats: '5',
  ),
  completeness: 0.9,
  warnings: [],
);

VehicleResolveResult _corollaWith({required String driveType}) {
  final vehicle = _corolla.vehicle;
  return VehicleResolveResult(
    resolution: _corolla.resolution,
    completeness: _corolla.completeness,
    warnings: _corolla.warnings,
    vehicle: VehicleResolveSuggestion(
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      trim: vehicle.trim,
      bodyType: vehicle.bodyType,
      fuelType: vehicle.fuelType,
      displacement: vehicle.displacement,
      transmission: vehicle.transmission,
      driveType: driveType,
      cylinders: vehicle.cylinders,
      doors: vehicle.doors,
      seats: vehicle.seats,
    ),
  );
}

const _sparse = VehicleResolveResult(
  resolution: VehicleResolveResolution.resolved,
  vehicle: VehicleResolveSuggestion(
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    bodyType: 'Sedan',
    fuelType: 'Gasoline',
  ),
  completeness: 0.4,
  warnings: [],
);

const _complete = VehicleResolveResult(
  resolution: VehicleResolveResolution.resolved,
  vehicle: VehicleResolveSuggestion(
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    trim: 'LE',
    bodyType: 'Sedan',
    fuelType: 'Gasoline',
    displacement: '1.8',
    transmission: 'Continuously Variable Transmission (CVT)',
    driveType: 'Front-Wheel Drive',
    cylinders: '4',
    doors: '4',
    seats: '5',
  ),
  completeness: 1,
  warnings: [],
);

class _QuickPickHost extends StatefulWidget {
  const _QuickPickHost({
    super.key,
    this.enabled = true,
    this.drivetrain,
    this.transmission,
    this.doors,
    this.seats,
    this.cylinders,
  });

  final bool enabled;
  final ListingDrivetrain? drivetrain;
  final ListingTransmissionType? transmission;
  final int? doors;
  final int? seats;
  final int? cylinders;

  @override
  State<_QuickPickHost> createState() => _QuickPickHostState();
}

class _QuickPickHostState extends State<_QuickPickHost> {
  late ListingDrivetrain? _drivetrain = widget.drivetrain;
  late ListingTransmissionType? _transmission = widget.transmission;
  late int? _doors = widget.doors;
  late int? _seats = widget.seats;
  late int? _cylinders = widget.cylinders;

  @override
  Widget build(BuildContext context) {
    final missing = createListingMissingQuickChoices(
      CreateListingQuickChoiceValues(
        drivetrain: _drivetrain,
        transmissionType: _transmission,
        doors: _doors,
        seats: _seats,
        engineCylinders: _cylinders,
      ),
    );
    if (missing.isEmpty) return const SizedBox.shrink();
    return ListView(
      children: [
        CreateListingCharacteristicQuickPicks(
          missing: missing,
          enabled: widget.enabled,
          onDrivetrain: (value) => setState(() => _drivetrain = value),
          onTransmission: (value) => setState(() => _transmission = value),
          onDoors: (value) => setState(() => _doors = value),
          onSeats: (value) => setState(() => _seats = value),
          onCylinders: (value) => setState(() => _cylinders = value),
        ),
      ],
    );
  }
}
