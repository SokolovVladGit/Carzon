import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/repositories/recall_data_repository.dart';
import 'package:carzon/features/vehicle_recall_data/domain/usecases/get_listing_recalls_for_buyer.dart';
import 'package:carzon/features/vehicle_recall_data/presentation/widgets/listing_details_recall_section.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

class _FakeRecallRepository implements RecallDataRepository {
  @override
  Future<Result<BuyerListingRecallSourceResult>> getListingRecallsForBuyer(
    String listingId,
  ) async {
    return const Success(
      BuyerListingRecallSourceResult(
        sourceLabel: 'NHTSA',
        campaignCount: 1,
        limitationCodes: ['us_market_data_only'],
        campaigns: [
          BuyerListingRecallCampaign(
            campaignNumber: '20TA01',
            component: 'Airbag inflator',
          ),
        ],
      ),
    );
  }
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerFactory<GetListingRecallsForBuyer>(
      () => GetListingRecallsForBuyer(_FakeRecallRepository()),
    );
  });

  testWidgets('renders in dark mode with visible card and text', (tester) async {
    final ru = ruStrings();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ListingDetailsRecallSection(listingId: 'l1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listing_recall_section')), findsOneWidget);
    expect(find.text(ru.listingRecallTitle), findsOneWidget);
    expect(find.text('NHTSA'), findsOneWidget);

    final titleStyle = tester.widget<Text>(find.text(ru.listingRecallTitle)).style;
    expect(titleStyle?.color, isNotNull);
  });
}
