import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:carzon/features/vehicle_model_data/domain/repositories/model_data_repository.dart';
import 'package:carzon/features/vehicle_model_data/domain/usecases/get_listing_model_data_for_buyer.dart';
import 'package:carzon/features/vehicle_model_data/presentation/widgets/listing_details_model_passport_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

class _FakeModelDataRepository implements ModelDataRepository {
  _FakeModelDataRepository(this._result);

  final Result<List<BuyerListingModelDataSourceResult>> _result;

  @override
  Future<Result<List<BuyerListingModelDataSourceResult>>>
  getListingModelDataForBuyer(String listingId) async => _result;
}

Future<void> _registerUseCase(Result<List<BuyerListingModelDataSourceResult>> result) async {
  await sl.reset();
  sl.registerFactory<GetListingModelDataForBuyer>(
    () => GetListingModelDataForBuyer(_FakeModelDataRepository(result)),
  );
}

BuyerListingModelDataSourceResult _fullEpaRow() {
  return BuyerListingModelDataSourceResult(
    sourceId: 'epa_fueleconomy',
    status: 'succeeded',
    sourceLabel: 'EPA · FuelEconomy.gov',
    fetchedAt: DateTime.utc(2026, 5, 1),
    normalizedSummary: {
      'combined_l_per_100km': 7.35,
      'city_l_per_100km': 8.12,
      'highway_l_per_100km': 6.78,
      'co2_g_per_km': 175.6,
      'fuel_type': 'Regular Gasoline',
      'transmission': 'Automatic',
      'drive': 'FWD',
      'engine_descriptor': '2.5L',
      'provider_vehicle_id': '99999',
      'combined_mpg': 32,
    },
    limitationCodes: const ['us_market_data_only'],
  );
}

void main() {
  final ru = ruStrings();

  testWidgets('renders source badge, metrics, and section title', (tester) async {
    await _registerUseCase(Success([_fullEpaRow()]));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_section')), findsOneWidget);
    expect(find.text(ru.listingModelPassportSectionTitle), findsOneWidget);
    expect(find.text('EPA · FuelEconomy.gov'), findsOneWidget);
    expect(find.textContaining('7.4 ${ru.listingModelPassportUnitLPer100km}'), findsOneWidget);
    expect(find.textContaining('8.1 ${ru.listingModelPassportUnitLPer100km}'), findsOneWidget);
    expect(find.textContaining('6.8 ${ru.listingModelPassportUnitLPer100km}'), findsOneWidget);
    expect(find.textContaining('176 ${ru.listingModelPassportUnitGPerKm}'), findsOneWidget);
    expect(find.text(ru.listingModelPassportFuelRegularGasoline), findsOneWidget);
    expect(find.text('Regular Gasoline'), findsNothing);
    expect(find.text('regular_gasoline'), findsNothing);
  });

  testWidgets('hides on empty success', (tester) async {
    await _registerUseCase(const Success([]));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_hidden')), findsOneWidget);
    expect(find.text(ru.listingModelPassportSectionTitle), findsNothing);
  });

  testWidgets('hides on repository failure', (tester) async {
    await _registerUseCase(
      const FailureResult(UnknownFailure('Failed to load listing model data.')),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_hidden')), findsOneWidget);
  });

  testWidgets('does not show forbidden v1 fields', (tester) async {
    await _registerUseCase(Success([_fullEpaRow()]));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('MPG', findRichText: true), findsNothing);
    expect(find.textContaining('Automatic'), findsNothing);
    expect(find.textContaining('FWD'), findsNothing);
    expect(find.textContaining('2.5L'), findsNothing);
    expect(find.textContaining('99999'), findsNothing);
    expect(find.textContaining('VIN', findRichText: true), findsNothing);
  });

  testWidgets('hides when EPA row has only forbidden summary fields', (tester) async {
    await _registerUseCase(
      Success([
        BuyerListingModelDataSourceResult(
          sourceId: 'epa_fueleconomy',
          status: 'succeeded',
          normalizedSummary: const {
            'transmission': 'Automatic',
            'drive': 'FWD',
            'engine_descriptor': '2.5L',
            'provider_vehicle_id': '12345',
            'combined_mpg': 32,
          },
        ),
      ]),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_model_passport_hidden')), findsOneWidget);
    expect(find.text(ru.listingModelPassportSectionTitle), findsNothing);
  });

  testWidgets('handles malformed summary without throwing', (tester) async {
    await _registerUseCase(
      Success([
        BuyerListingModelDataSourceResult(
          sourceId: 'epa_fueleconomy',
          status: 'succeeded',
          normalizedSummary: const {},
        ),
      ]),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('listing_model_passport_hidden')), findsOneWidget);
  });

  testWidgets('limitations are collapsed by default', (tester) async {
    await _registerUseCase(
      Success([
        BuyerListingModelDataSourceResult(
          sourceId: 'epa_fueleconomy',
          status: 'succeeded',
          normalizedSummary: const {'combined_l_per_100km': 7.4},
          limitationCodes: const ['us_market_data_only'],
        ),
      ]),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingModelPassportLimitationsTitle), findsOneWidget);
    expect(find.text(ru.listingModelPassportLimitationUsMarketOnly), findsNothing);
  });

  testWidgets('unknown limitation code shows generic text when expanded', (tester) async {
    await _registerUseCase(
      Success([
        BuyerListingModelDataSourceResult(
          sourceId: 'epa_fueleconomy',
          status: 'succeeded',
          normalizedSummary: const {'combined_l_per_100km': 7.4},
          limitationCodes: const ['totally_unknown_code'],
        ),
      ]),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsModelPassportSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ru.listingModelPassportLimitationsTitle));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingModelPassportLimitationGeneric), findsOneWidget);
    expect(find.textContaining('totally_unknown_code'), findsNothing);
  });
}
