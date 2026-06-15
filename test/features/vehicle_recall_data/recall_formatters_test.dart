import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/presentation/utils/recall_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();

  group('readRecallText', () {
    test('returns null for blank values', () {
      expect(readRecallText(null), isNull);
      expect(readRecallText(''), isNull);
      expect(readRecallText('   '), isNull);
    });

    test('trims non-empty text', () {
      expect(readRecallText('  Airbag  '), 'Airbag');
    });
  });

  group('formatRecallDateString', () {
    test('formats ISO date strings', () {
      expect(
        formatRecallDateString('2020-05-15T00:00:00.000Z'),
        '15.05.2020',
      );
    });

    test('returns trimmed raw text when not parseable', () {
      expect(formatRecallDateString('May 2020'), 'May 2020');
    });
  });

  group('formatRecallCampaignCountLabel', () {
    test('includes localized count prefix', () {
      expect(
        formatRecallCampaignCountLabel(ru, 2),
        '${ru.listingRecallCampaignCount}: 2',
      );
    });
  });

  group('resolveRecallSourceLabel', () {
    test('falls back to NHTSA badge when source label missing', () {
      expect(resolveRecallSourceLabel(ru, null), ru.listingRecallSourceBadge);
      expect(resolveRecallSourceLabel(ru, '  '), ru.listingRecallSourceBadge);
    });

    test('uses provided source label when present', () {
      expect(resolveRecallSourceLabel(ru, 'NHTSA Recalls'), 'NHTSA Recalls');
    });
  });

  group('buildRecallCampaignFieldRows', () {
    test('omits blank fields', () {
      final rows = buildRecallCampaignFieldRows(
        ru,
        const BuyerListingRecallCampaign(
          campaignNumber: '20TA01',
          summary: 'Airbag inflator may rupture',
          component: '  ',
          consequence: null,
        ),
      );

      expect(rows.map((r) => r.label), [
        ru.listingRecallCampaignNumber,
        ru.listingRecallSummary,
      ]);
      expect(rows.first.value, '20TA01');
    });

    test('includes bool flags when true', () {
      final rows = buildRecallCampaignFieldRows(
        ru,
        const BuyerListingRecallCampaign(
          component: 'Airbag',
          parkIt: true,
          parkOutside: true,
          overTheAirUpdate: true,
        ),
      );

      expect(rows.map((r) => r.label), [
        ru.listingRecallParkIt,
        ru.listingRecallParkOutside,
        ru.listingRecallOverTheAirUpdate,
      ]);
      expect(rows.first.value, ru.listingRecallFlagYes);
    });
  });

  group('buildRecallCampaignCollapsedMetaRows', () {
    test('includes campaign number, report date, and manufacturer only', () {
      final rows = buildRecallCampaignCollapsedMetaRows(
        ru,
        const BuyerListingRecallCampaign(
          campaignNumber: '20TA01',
          reportReceivedDate: '2020-03-15',
          manufacturer: 'Toyota',
          summary: 'Long summary text',
          consequence: 'Risk',
        ),
      );

      expect(rows.map((r) => r.label), [
        ru.listingRecallCampaignNumber,
        ru.listingRecallReportReceivedDate,
        ru.listingRecallManufacturer,
      ]);
    });
  });

  group('buildRecallCampaignDetailRows', () {
    test('includes long text fields and flags but not campaign number', () {
      final rows = buildRecallCampaignDetailRows(
        ru,
        const BuyerListingRecallCampaign(
          campaignNumber: '20TA01',
          summary: 'Summary text',
          consequence: 'Consequence text',
          remedy: 'Remedy text',
          notes: 'Notes text',
          parkIt: true,
        ),
      );

      expect(rows.map((r) => r.label), [
        ru.listingRecallSummary,
        ru.listingRecallConsequence,
        ru.listingRecallRemedy,
        ru.listingRecallNotes,
        ru.listingRecallParkIt,
      ]);
    });
  });

  group('recallCampaignPreviewText', () {
    test('returns truncated summary when distinct from headline', () {
      final longSummary = 'A' * 200;
      final preview = recallCampaignPreviewText(
        BuyerListingRecallCampaign(
          component: 'Airbag inflator',
          summary: longSummary,
        ),
      );

      expect(preview, isNotNull);
      expect(preview!.length, lessThan(longSummary.length));
      expect(preview.endsWith('…'), isTrue);
    });

    test('returns null when summary matches headline', () {
      expect(
        recallCampaignPreviewText(
          const BuyerListingRecallCampaign(
            summary: 'Only headline',
          ),
        ),
        isNull,
      );
    });
  });

  group('recallCampaignHasUiDisplayableContent', () {
    test('returns false for make/model/year metadata only', () {
      expect(
        recallCampaignHasUiDisplayableContent(
          const BuyerListingRecallCampaign(
            make: 'Toyota',
            model: 'Camry',
            modelYear: 2020,
          ),
        ),
        isFalse,
      );
    });
  });

  group('recallCampaignsForDisplay', () {
    test('caps campaigns at 10', () {
      final campaigns = List.generate(
        12,
        (i) => BuyerListingRecallCampaign(campaignNumber: 'C$i'),
      );
      final result = BuyerListingRecallSourceResult(
        campaigns: campaigns,
        campaignCount: 12,
      );

      expect(recallCampaignsForDisplay(result), hasLength(10));
    });
  });

  group('recallCampaignHeadline', () {
    test('prefers component then summary then campaign number', () {
      expect(
        recallCampaignHeadline(
          const BuyerListingRecallCampaign(
            component: 'Airbag',
            summary: 'Summary',
            campaignNumber: '20TA01',
          ),
        ),
        'Airbag',
      );
      expect(
        recallCampaignHeadline(
          const BuyerListingRecallCampaign(
            summary: 'Summary',
            campaignNumber: '20TA01',
          ),
        ),
        'Summary',
      );
      expect(
        recallCampaignHeadline(
          const BuyerListingRecallCampaign(campaignNumber: '20TA01'),
        ),
        '20TA01',
      );
    });
  });
}
