import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/create_listing/presentation/models/create_listing_characteristics_summary.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_characteristics_facts.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:carzon/features/create_listing/presentation/models/listing_preview_data.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  group('createListingCharacteristicsSummary', () {
    test('joins known values in a stable order and includes engine power', () {
      expect(
        createListingCharacteristicsSummary(
          ru,
          bodyType: ListingBodyType.suv,
          fuelType: ListingFuelType.petrol,
          engineDisplacementLiters: 2.0,
          enginePowerHp: 150,
          transmissionType: ListingTransmissionType.automatic,
        ),
        listingPreviewJoin([
          formatListingBodyType(ru, ListingBodyType.suv),
          formatListingFuelType(ru, ListingFuelType.petrol),
          formatEngineDisplacementForDisplay(ru, 2.0),
          formatEnginePowerHpDisplay(ru, 150),
          formatListingTransmissionType(ru, ListingTransmissionType.automatic),
        ]),
      );
    });

    test('omits unknown values without inventing defaults', () {
      expect(
        createListingCharacteristicsSummary(
          ru,
          fuelType: ListingFuelType.diesel,
          enginePowerHp: 190,
        ),
        listingPreviewJoin([
          formatListingFuelType(ru, ListingFuelType.diesel),
          formatEnginePowerHpDisplay(ru, 190),
        ]),
      );
    });

    test('returns empty string when nothing is known', () {
      expect(createListingCharacteristicsSummary(ru), isEmpty);
    });

    test('keeps one-decimal liters on 1.0 and 2.0', () {
      expect(
        formatEngineDisplacementForDisplay(ru, 1.0),
        '1.0 ${ru.listingEngineDisplacementLitersSuffix}',
      );
      expect(
        formatEngineDisplacementForDisplay(ru, 1),
        '1.0 ${ru.listingEngineDisplacementLitersSuffix}',
      );
      expect(
        formatEngineDisplacementForDisplay(ru, 2.0),
        '2.0 ${ru.listingEngineDisplacementLitersSuffix}',
      );
      expect(
        createListingCharacteristicsSummary(
          ru,
          fuelType: ListingFuelType.petrol,
          engineDisplacementLiters: 1.0,
          enginePowerHp: 60,
        ),
        listingPreviewJoin([
          formatListingFuelType(ru, ListingFuelType.petrol),
          '1.0 ${ru.listingEngineDisplacementLitersSuffix}',
          formatEnginePowerHpDisplay(ru, 60),
        ]),
      );
    });
  });

  group('CreateListingPage characteristics & description', () {
    late _MockCreateCubit createCubit;
    late _MockAuthCubit authCubit;
    late FakeVehicleModelCatalogRepository catalog;

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
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.authenticated(user));
      whenListen(
        authCubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      stubCreateListingVinResolve(createCubit);
      sl.registerFactory<CreateListingCubit>(() => createCubit);
    });

    tearDown(() async {
      await sl.reset();
    });

    Widget wrap() => MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(vehicleModelCatalog: catalog),
      ),
    );

    Finder summary() =>
        find.byKey(const ValueKey('create_listing_characteristics_summary'));
    Finder bodyTypeField() =>
        find.byKey(const ValueKey('create_listing_body_type_field'));
    Finder drivetrainField() =>
        find.byKey(const ValueKey('create_listing_drivetrain_field'));

    testWidgets(
      'description is visible without expanding and sits before the preview',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        expect(bodyTypeField(), findsNothing);
        final description = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const ValueKey('create_listing_description_field')),
            matching: find.byType(EditableText),
          ),
        );
        expect(description.minLines, 4);
        expect(find.textContaining('/ 8000'), findsOneWidget);

        final descriptionSection = find.byKey(
          const ValueKey('create_listing_description_section'),
        );
        final publishSection = find.byKey(
          const ValueKey('create_listing_publish_section'),
        );
        expect(
          tester.getTopLeft(descriptionSection).dy,
          lessThan(tester.getTopLeft(publishSection).dy),
        );
      },
    );

    testWidgets(
      'summary starts empty and reflects a seller engine-power edit',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        expect(summary(), findsNothing);
        expect(
          find.text(ru.createListingCharacteristicsAutoHelper),
          findsOneWidget,
        );
        expect(
          find.text(ru.createListingCharacteristicsEnterManually),
          findsOneWidget,
        );

        await expandCreateListingAdditionalDetails(tester);
        final power = find.byKey(
          const ValueKey('create_listing_engine_power_field'),
        );
        await tester.ensureVisible(power);
        await tester.enterText(power, '150');
        await tester.pump();

        expect(
          find.descendant(
            of: summary(),
            matching: find.text(formatEnginePowerHpDisplay(ru, 150)),
          ),
          findsOneWidget,
        );
      },
    );

    Future<void> selectFourWheelDrivetrain(WidgetTester tester) async {
      // Tall viewport so the whole picker sheet fits without inner scrolling.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      tester.testTextInput.hide();
      await tester.scrollUntilVisible(
        drivetrainField(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(drivetrainField());
      await tester.pumpAndSettle();
      await tester.tap(drivetrainField());
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.listingDrivetrainFourWheel));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'drivetrain shows not-specified and is selectable after expanding',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        await expandCreateListingAdditionalDetails(tester);
        expect(bodyTypeField(), findsOneWidget);
        expect(
          find.descendant(
            of: drivetrainField(),
            matching: find.text(ru.createListingDrivetrainNotSpecified),
          ),
          findsOneWidget,
        );

        await selectFourWheelDrivetrain(tester);

        expect(
          find.descendant(
            of: drivetrainField(),
            matching: find.text(ru.listingDrivetrainFourWheel),
          ),
          findsOneWidget,
        );
        expect(bodyTypeField(), findsOneWidget);
      },
    );

    testWidgets('preview reflects a drivetrain selected in characteristics', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await expandCreateListingAdditionalDetails(tester);
      await selectFourWheelDrivetrain(tester);

      await tester.scrollUntilVisible(
        find.byKey(ListingPreviewCard.detailKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.detailKey)).data,
        contains(ru.listingDrivetrainFourWheel),
      );
    });
  });

  testWidgets('technical fact grid stays a 2x2 without overflow', (
    tester,
  ) async {
    Future<void> pumpFacts({
      required ThemeData theme,
      required double width,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: CreateListingCharacteristicsFacts(
                  facts: [
                    CreateListingCharacteristicFact(
                      icon: Icons.directions_car_outlined,
                      label: ru.listingFieldBodyType,
                      value: ru.listingBodyTypeSedan,
                    ),
                    CreateListingCharacteristicFact(
                      icon: CarzonIcons.gauge,
                      label: ru.compareRowEngine,
                      value: '3.5 л · ${ru.listingFuelTypePetrol}',
                    ),
                    CreateListingCharacteristicFact(
                      icon: CarzonIcons.swap,
                      label: ru.compareRowDrivetrain,
                      value: ru.listingDrivetrainAwd,
                    ),
                    CreateListingCharacteristicFact(
                      icon: CarzonIcons.settings,
                      label: ru.compareRowTransmission,
                      value: ru.listingTransmissionAutomatic,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final width in [358.0, 343.0, 288.0]) {
      await pumpFacts(theme: AppTheme.light(), width: width);
      expect(tester.takeException(), isNull);
      final body = tester.getRect(find.text(ru.listingFieldBodyType));
      final gearbox = tester.getRect(find.text(ru.compareRowTransmission));
      if (width >= 280) {
        expect(gearbox.left, greaterThan(body.left));
        expect(gearbox.top, greaterThan(body.top));
      }
    }
    await pumpFacts(theme: AppTheme.dark(), width: 358);
    expect(tester.takeException(), isNull);
    expect(find.text(ru.listingTransmissionAutomatic), findsOneWidget);
  });

  test('every non-null characteristic is shown', () {
    List<String> labels({
      ListingTransmissionType? transmission,
      int? power,
      ListingFuelType? fuel = ListingFuelType.petrol,
      double? liters = 2,
    }) {
      return buildCreateListingTechnicalFacts(
        ru,
        bodyType: ListingBodyType.pickup,
        displacementLiters: liters,
        fuelType: fuel,
        drivetrain: ListingDrivetrain.awd,
        transmissionType: transmission,
        powerHp: power,
      ).map((fact) => fact.label).toList();
    }

    expect(
      labels(transmission: ListingTransmissionType.automatic, power: 200),
      [
        ru.listingFieldBodyType,
        ru.compareRowEngine,
        ru.compareRowDrivetrain,
        ru.compareRowTransmission,
        ru.compareRowPower,
      ],
    );
    expect(labels(power: 200), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
      ru.compareRowPower,
    ]);
    expect(labels(), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
    ]);
    final full = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.sedan,
      fuelType: ListingFuelType.petrol,
      displacementLiters: 2,
      powerHp: 150,
      transmissionType: ListingTransmissionType.automatic,
      drivetrain: ListingDrivetrain.fwd,
      engineCylinders: 4,
      doors: 4,
      seats: 5,
      registration: 'MD',
    );
    expect(full.map((fact) => fact.label), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
      ru.compareRowTransmission,
      ru.compareRowPower,
      ru.listingEngineCylinders,
      ru.listingDoors,
      ru.listingSeats,
      ru.compareRowRegistration,
    ]);
    expect(full.map((fact) => fact.label), isNot(contains(ru.listingFuelType)));
    expect(
      full.firstWhere((fact) => fact.label == ru.listingEngineCylinders).value,
      '4',
    );
    expect(
      full.firstWhere((fact) => fact.label == ru.listingDoors).value,
      '4',
    );
    expect(
      full.firstWhere((fact) => fact.label == ru.listingSeats).value,
      '5',
    );
  });

  test('fuel and displacement share one engine fact', () {
    final combined = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.pickup,
      displacementLiters: 2,
      fuelType: ListingFuelType.petrol,
      drivetrain: ListingDrivetrain.awd,
      transmissionType: ListingTransmissionType.automatic,
    );
    expect(combined.map((fact) => fact.label), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
      ru.compareRowTransmission,
    ]);
    expect(
      combined.firstWhere((fact) => fact.label == ru.compareRowEngine).value,
      '${ru.listingFuelTypePetrol} · ${formatEngineDisplacementForDisplay(ru, 2)}',
    );
    expect(
      combined.map((fact) => fact.label),
      isNot(contains(ru.listingFuelType)),
    );
    expect(combined.map((fact) => fact.value).join(' '), isNot(contains('—')));
    expect(combined.map((fact) => fact.value), isNot(contains('Неизвестно')));

    final fuelOnly = buildCreateListingTechnicalFacts(
      ru,
      fuelType: ListingFuelType.petrol,
    );
    expect(fuelOnly, hasLength(1));
    expect(fuelOnly.single.label, ru.compareRowEngine);
    expect(fuelOnly.single.value, ru.listingFuelTypePetrol);

    final displacementOnly = buildCreateListingTechnicalFacts(
      ru,
      displacementLiters: 2,
    );
    expect(displacementOnly, hasLength(1));
    expect(displacementOnly.single.label, ru.compareRowEngine);
    expect(
      displacementOnly.single.value,
      formatEngineDisplacementForDisplay(ru, 2),
    );

    final electric = buildCreateListingTechnicalFacts(
      ru,
      fuelType: ListingFuelType.electric,
    );
    expect(electric.single.label, ru.compareRowEngine);
    expect(electric.single.value, ru.listingFuelTypeElectric);
    expect(
      electric.map((fact) => fact.label),
      isNot(contains(ru.listingFuelType)),
    );

    expect(
      buildCreateListingTechnicalFacts(
        ru,
        fuelType: ListingFuelType.diesel,
        displacementLiters: 2,
      ).single.value,
      '${ru.listingFuelTypeDiesel} · ${formatEngineDisplacementForDisplay(ru, 2)}',
    );
    expect(
      buildCreateListingTechnicalFacts(
        ru,
        fuelType: ListingFuelType.hybrid,
        displacementLiters: 2.5,
      ).single.value,
      '${ru.listingFuelTypeHybrid} · ${formatEngineDisplacementForDisplay(ru, 2.5)}',
    );
    expect(
      buildCreateListingTechnicalFacts(
        ru,
        fuelType: ListingFuelType.diesel,
      ).single.value,
      ru.listingFuelTypeDiesel,
    );

    final bodyOnly = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.pickup,
    );
    expect(bodyOnly.map((fact) => fact.label), [ru.listingFieldBodyType]);
  });

  test('Ford Maverick VIN facts skip missing transmission doors and seats', () {
    final facts = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.pickup,
      fuelType: ListingFuelType.petrol,
      displacementLiters: 2,
      drivetrain: ListingDrivetrain.awd,
      engineCylinders: 4,
    );
    expect(facts.map((fact) => fact.label), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
      ru.listingEngineCylinders,
    ]);
    expect(
      facts.firstWhere((fact) => fact.label == ru.compareRowEngine).value,
      '${ru.listingFuelTypePetrol} · ${formatEngineDisplacementForDisplay(ru, 2)}',
    );
    expect(
      facts.firstWhere((fact) => fact.label == ru.listingEngineCylinders).value,
      '4',
    );
    expect(
      facts.map((fact) => fact.value).join(' '),
      isNot(contains('цилиндр')),
    );
    expect(facts.map((fact) => fact.label), isNot(contains(ru.listingFuelType)));
    expect(
      facts.map((fact) => fact.label),
      isNot(contains(ru.compareRowTransmission)),
    );
  });

  test('missing drivetrain still shows the combined engine and year', () {
    final facts = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.sedan,
      displacementLiters: 1.8,
      fuelType: ListingFuelType.petrol,
      year: 2018,
    );
    expect(facts, hasLength(3));
    expect(facts.map((fact) => fact.label), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowYear,
    ]);
    expect(
      facts.firstWhere((fact) => fact.label == ru.compareRowEngine).value,
      '${ru.listingFuelTypePetrol} · ${formatEngineDisplacementForDisplay(ru, 1.8)}',
    );
    expect(
      facts.firstWhere((fact) => fact.label == ru.compareRowYear).value,
      '2018',
    );
    expect(facts.map((fact) => fact.value), isNot(contains('Неизвестно')));
  });

  test('missing transmission falls back to year without inventing a value', () {
    final facts = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.sedan,
      displacementLiters: 1.8,
      drivetrain: ListingDrivetrain.fwd,
      year: 2020,
    );
    expect(facts, hasLength(4));
    expect(facts.map((fact) => fact.label), [
      ru.listingFieldBodyType,
      ru.compareRowEngine,
      ru.compareRowDrivetrain,
      ru.compareRowYear,
    ]);
    expect(
      facts.map((fact) => fact.label),
      isNot(contains(ru.compareRowTransmission)),
    );

    final withoutYear = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.sedan,
      displacementLiters: 1.8,
      drivetrain: ListingDrivetrain.fwd,
    );
    expect(
      withoutYear.map((fact) => fact.label),
      isNot(contains(ru.compareRowYear)),
    );
    expect(withoutYear, hasLength(3));
  });

  test('registration is the last real fallback and blank text is omitted', () {
    final facts = buildCreateListingTechnicalFacts(
      ru,
      year: 2016,
      registration: '  Тирасполь  ',
    );
    expect(facts.map((fact) => fact.label), [
      ru.compareRowYear,
      ru.compareRowRegistration,
    ]);
    expect(facts.last.value, 'Тирасполь');

    final blank = buildCreateListingTechnicalFacts(ru, registration: '   ');
    expect(blank, isEmpty);
  });

  testWidgets('2x2 grid fits AWD at 320, 375 and 390 without a divider', (
    tester,
  ) async {
    Future<void> pumpAt(double width, ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: CreateListingCharacteristicsFacts(
                  facts: buildCreateListingTechnicalFacts(
                    ru,
                    bodyType: ListingBodyType.pickup,
                    displacementLiters: 2,
                    fuelType: ListingFuelType.petrol,
                    drivetrain: ListingDrivetrain.awd,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    void expectFits(String value) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
      expect(paragraph.didExceedMaxLines, isFalse);
    }

    for (final width in [264.0, 319.0, 334.0]) {
      await pumpAt(width, AppTheme.light());
      expect(tester.takeException(), isNull);
      final body = tester.getRect(find.text(ru.listingFieldBodyType));
      final engine = tester.getRect(find.text(ru.compareRowEngine));
      final drive = tester.getRect(find.text(ru.compareRowDrivetrain));
      expect(find.text(ru.listingFuelType), findsNothing);
      expect(engine.left, greaterThan(body.left));
      expect((body.top - engine.top).abs(), lessThan(2));
      expect(drive.top, greaterThan(body.bottom));
      expect((drive.left - body.left).abs(), lessThan(2));
      expect((drive.width - body.width).abs(), lessThan(2));
      expect(drive.right, lessThan(body.right + body.width));
      expectFits(ru.listingDrivetrainAwd);
      expectFits(
        '${ru.listingFuelTypePetrol} · ${formatEngineDisplacementForDisplay(ru, 2)}',
      );
      final cells = tester
          .renderObjectList<RenderBox>(find.byType(DecoratedBox))
          .map((cell) => cell.size)
          .where((size) => size.width > 40)
          .toList();
      expect(cells, hasLength(3));
      expect(cells.map((size) => size.height).toSet(), hasLength(1));
      expect(cells.map((size) => size.width).toSet(), hasLength(1));
    }
    await pumpAt(334, AppTheme.dark());
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        '${ru.listingFuelTypePetrol} · ${formatEngineDisplacementForDisplay(ru, 2)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('odd fact counts stay left-aligned in the two-column flow', (
    tester,
  ) async {
    Future<void> pumpCount(int count) async {
      final facts = buildCreateListingTechnicalFacts(
        ru,
        bodyType: ListingBodyType.pickup,
        fuelType: count >= 2 ? ListingFuelType.petrol : null,
        displacementLiters: count >= 2 ? 2 : null,
        drivetrain: count >= 3 ? ListingDrivetrain.awd : null,
        transmissionType: count >= 4
            ? ListingTransmissionType.automatic
            : null,
        powerHp: count >= 5 ? 250 : null,
        engineCylinders: count >= 6 ? 4 : null,
        doors: count >= 7 ? 4 : null,
        seats: count >= 8 ? 5 : null,
      );
      expect(facts, hasLength(count));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: CreateListingCharacteristicsFacts(facts: facts),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final body = tester.getRect(find.text(ru.listingFieldBodyType));
      final last = tester.getRect(find.text(facts.last.label));
      if (count.isOdd) {
        expect((last.left - body.left).abs(), lessThan(2));
        expect((last.width - body.width).abs(), lessThan(2));
      } else {
        expect(last.left, greaterThan(body.left));
        expect((last.width - body.width).abs(), lessThan(2));
      }
    }

    for (final count in [4, 5, 6, 7, 8]) {
      await pumpCount(count);
    }
  });

  testWidgets('all nine facts render without clipping or a fuel tile', (
    tester,
  ) async {
    final facts = buildCreateListingTechnicalFacts(
      ru,
      bodyType: ListingBodyType.pickup,
      fuelType: ListingFuelType.petrol,
      displacementLiters: 2,
      drivetrain: ListingDrivetrain.awd,
      transmissionType: ListingTransmissionType.automatic,
      powerHp: 250,
      engineCylinders: 4,
      doors: 4,
      seats: 5,
      registration: 'MD',
    );
    expect(facts, hasLength(9));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: CreateListingCharacteristicsFacts(facts: facts),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(ru.listingFuelType), findsNothing);
    final seen = <String>{};
    for (final fact in facts) {
      if (!seen.add(fact.value)) continue;
      final matches = find.text(fact.value);
      expect(matches, findsWidgets);
      for (final element in matches.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
      }
    }
    final body = tester.getRect(find.text(ru.listingFieldBodyType));
    final power = tester.getRect(find.text(ru.compareRowPower));
    final doors = tester.getRect(find.text(ru.listingDoors));
    final registration = tester.getRect(find.text(ru.compareRowRegistration));
    expect((power.left - body.left).abs(), lessThan(2));
    expect((doors.left - body.left).abs(), lessThan(2));
    expect((registration.left - body.left).abs(), lessThan(2));
    expect((power.width - body.width).abs(), lessThan(2));
    expect((registration.width - body.width).abs(), lessThan(2));
  });
}
