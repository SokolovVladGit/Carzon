import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/models/create_listing_characteristics_summary.dart';
import 'package:carzon/features/create_listing/presentation/models/listing_preview_data.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
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

        // Editor collapsed, yet description is a first-class visible field.
        expect(bodyTypeField(), findsNothing);
        expect(
          find.byKey(const ValueKey('create_listing_description_field')),
          findsOneWidget,
        );

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

        expect(
          tester.widget<Text>(summary()).data,
          ru.createListingCharacteristicsEmpty,
        );

        await expandCreateListingAdditionalDetails(tester);
        final power = find.byKey(
          const ValueKey('create_listing_engine_power_field'),
        );
        await tester.ensureVisible(power);
        await tester.enterText(power, '150');
        await tester.pump();

        expect(
          tester.widget<Text>(summary()).data,
          formatEnginePowerHpDisplay(ru, 150),
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
      'drivetrain shows not-specified and is selectable without expanding',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        // Editor still collapsed while drivetrain is directly available.
        expect(bodyTypeField(), findsNothing);
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
        // Detailed editor was never expanded.
        expect(bodyTypeField(), findsNothing);
      },
    );

    testWidgets('preview reflects a drivetrain selected in characteristics', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await selectFourWheelDrivetrain(tester);

      await tester.scrollUntilVisible(
        find.byKey(ListingPreviewCard.specsKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
        contains(ru.listingDrivetrainFourWheel),
      );
    });
  });
}
