import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/repositories/recall_data_repository.dart';
import 'package:carzon/features/vehicle_recall_data/domain/usecases/get_listing_recalls_for_buyer.dart';
import 'package:carzon/features/vehicle_recall_data/presentation/widgets/listing_details_recall_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

class _FakeRecallRepository implements RecallDataRepository {
  _FakeRecallRepository(this._result);

  final Result<BuyerListingRecallSourceResult> _result;

  @override
  Future<Result<BuyerListingRecallSourceResult>> getListingRecallsForBuyer(
    String listingId,
  ) async =>
      _result;
}

Future<void> _registerUseCase(Result<BuyerListingRecallSourceResult> result) async {
  await sl.reset();
  sl.registerFactory<GetListingRecallsForBuyer>(
    () => GetListingRecallsForBuyer(_FakeRecallRepository(result)),
  );
}

BuyerListingRecallSourceResult _fullResult() {
  return BuyerListingRecallSourceResult(
    sourceId: 'nhtsa_recalls',
    status: 'succeeded',
    sourceLabel: 'NHTSA',
    fetchedAt: DateTime.utc(2026, 5, 1),
    campaignCount: 1,
    limitationCodes: const [
      'us_market_data_only',
      'model_level_not_exact_vehicle',
    ],
    campaigns: const [
      BuyerListingRecallCampaign(
        campaignNumber: '20TA01',
        component: 'Airbag inflator',
        summary: 'Inflator may rupture during deployment.',
        consequence: 'Injury risk during airbag deployment.',
        remedy: 'Dealer will replace inflator free of charge.',
        manufacturer: 'Toyota',
        reportReceivedDate: '2020-03-15',
        parkIt: true,
      ),
    ],
  );
}

void main() {
  final ru = ruStrings();

  testWidgets('renders section title, source badge, and campaign cards', (
    tester,
  ) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_recall_section')), findsOneWidget);
    expect(find.text(ru.listingRecallTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('listing_recall_source_badge')), findsOneWidget);
    expect(find.text('NHTSA'), findsOneWidget);
    expect(find.text(ru.listingRecallCampaignsFound), findsOneWidget);
    expect(find.byKey(const ValueKey('listing_recall_campaign_count')), findsOneWidget);
    expect(find.text('Airbag inflator'), findsOneWidget);
    expect(find.textContaining('20TA01'), findsOneWidget);
  });

  testWidgets('hides while loading', (tester) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('listing_recall_hidden')), findsOneWidget);
    expect(find.text(ru.listingRecallTitle), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('listing_recall_section')), findsOneWidget);
  });

  testWidgets('hides on empty success', (tester) async {
    await _registerUseCase(const Success(BuyerListingRecallSourceResult.empty));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_recall_hidden')), findsOneWidget);
    expect(find.text(ru.listingRecallTitle), findsNothing);
  });

  testWidgets('hides on repository failure', (tester) async {
    await _registerUseCase(
      const FailureResult(UnknownFailure('Failed to load listing recalls.')),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_recall_hidden')), findsOneWidget);
  });

  testWidgets('does not show blank field labels', (tester) async {
    await _registerUseCase(
      Success(
        BuyerListingRecallSourceResult(
          sourceLabel: 'NHTSA',
          campaignCount: 1,
          limitationCodes: const ['us_market_data_only'],
          campaigns: const [
            BuyerListingRecallCampaign(
              campaignNumber: '20TA01',
              summary: 'Only summary shown',
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallComponent), findsNothing);
    expect(find.text(ru.listingRecallManufacturer), findsNothing);
    expect(find.text(ru.listingRecallConsequence), findsNothing);
  });

  testWidgets('does not show forbidden internal keys', (tester) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('cache_key'), findsNothing);
    expect(find.textContaining('source_metadata'), findsNothing);
    expect(find.textContaining('vin_hash'), findsNothing);
    expect(find.textContaining('nhtsa_recalls'), findsNothing);
  });

  testWidgets('limitations are collapsed by default', (tester) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallLimitationsTitle), findsOneWidget);
    expect(
      find.text(ru.listingRecallLimitationModelLevelNotExactVehicle),
      findsNothing,
    );
  });

  testWidgets('unknown limitation code shows generic text when expanded', (
    tester,
  ) async {
    await _registerUseCase(
      Success(
        _fullResult().copyWith(
          limitationCodes: const ['totally_unknown_code'],
        ),
      ),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ru.listingRecallLimitationsTitle));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallLimitationGeneric), findsOneWidget);
    expect(find.textContaining('totally_unknown_code'), findsNothing);
  });

  testWidgets('campaign cards hide long detail fields when collapsed', (
    tester,
  ) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallConsequence), findsNothing);
    expect(find.text(ru.listingRecallRemedy), findsNothing);
    expect(find.text(ru.listingRecallSummary), findsNothing);
    expect(
      find.text('Injury risk during airbag deployment.'),
      findsNothing,
    );
    expect(
      find.text('Dealer will replace inflator free of charge.'),
      findsNothing,
    );
    expect(find.text(ru.listingRecallShowDetails), findsOneWidget);
    expect(find.text(ru.listingRecallParkIt), findsOneWidget);
  });

  testWidgets('tapping show details reveals long fields', (tester) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ru.listingRecallShowDetails));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallSummary), findsOneWidget);
    expect(find.text(ru.listingRecallConsequence), findsOneWidget);
    expect(find.text(ru.listingRecallRemedy), findsOneWidget);
    expect(
      find.text('Injury risk during airbag deployment.'),
      findsOneWidget,
    );
    expect(find.text(ru.listingRecallHideDetails), findsOneWidget);
  });

  testWidgets('tapping hide details collapses long fields again', (
    tester,
  ) async {
    await _registerUseCase(Success(_fullResult()));

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ru.listingRecallShowDetails));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.listingRecallHideDetails));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallConsequence), findsNothing);
    expect(find.text(ru.listingRecallShowDetails), findsOneWidget);
  });

  testWidgets('false safety flags are omitted from collapsed cards', (
    tester,
  ) async {
    await _registerUseCase(
      Success(
        BuyerListingRecallSourceResult(
          sourceLabel: 'NHTSA',
          campaignCount: 1,
          limitationCodes: const ['us_market_data_only'],
          campaigns: const [
            BuyerListingRecallCampaign(
              campaignNumber: '20TA01',
              component: 'Airbag',
              summary: 'Summary only',
              parkIt: false,
              parkOutside: false,
              overTheAirUpdate: false,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: ListingDetailsRecallSection(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingRecallParkIt), findsNothing);
    expect(find.text(ru.listingRecallParkOutside), findsNothing);
    expect(find.text(ru.listingRecallOverTheAirUpdate), findsNothing);
  });
}

extension on BuyerListingRecallSourceResult {
  BuyerListingRecallSourceResult copyWith({
    List<String>? limitationCodes,
  }) {
    return BuyerListingRecallSourceResult(
      sourceId: sourceId,
      status: status,
      campaigns: campaigns,
      campaignCount: campaignCount,
      sourceLabel: sourceLabel,
      sourceUpdatedAt: sourceUpdatedAt,
      fetchedAt: fetchedAt,
      ttlUntil: ttlUntil,
      updatedAt: updatedAt,
      limitationCodes: limitationCodes ?? this.limitationCodes,
      matchQuality: matchQuality,
      market: market,
    );
  }
}
