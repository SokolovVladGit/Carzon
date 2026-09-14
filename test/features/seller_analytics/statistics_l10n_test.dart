import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

const _keys = [
  'statisticsTitle',
  'statisticsSignInRequired',
  'statisticsPeriodSelectorLabel',
  'statisticsPeriod7',
  'statisticsPeriod30',
  'statisticsPeriod90',
  'statisticsMetricViews',
  'statisticsMetricFavorites',
  'statisticsMetricInquiries',
  'statisticsMetricConversion',
  'statisticsValueUnavailable',
  'statisticsActiveListings',
  'statisticsSoldListings',
  'statisticsYourListings',
  'statisticsEmptyTitle',
  'statisticsEmptyBody',
  'statisticsEmptyCta',
  'statisticsLoadFailed',
  'statisticsProfessionalLabel',
  'statisticsInventoryTotal',
  'statisticsTopListings',
  'statisticsTopListingsEmpty',
  'statisticsInventoryPerformance',
  'statisticsSortMostInquiries',
  'statisticsSortMostViewed',
  'statisticsSortMostFavorited',
  'statisticsSortNewest',
  'statisticsSortLongestListed',
  'statisticsFilterAll',
  'statisticsFilterActive',
  'statisticsFilterSold',
  'statisticsInterestFunnel',
  'statisticsFunnelImpressions',
  'statisticsFunnelViews',
  'statisticsFunnelInquiries',
  'statisticsContactActions',
  'statisticsContactActionsTotal',
  'statisticsMetricPhone',
  'statisticsMetricWhatsapp',
  'statisticsMetricTelegram',
  'statisticsMetricShares',
  'statisticsListingImpressions',
  'statisticsListingContactActions',
  'statisticsListingShares',
  'statisticsDemandTitle',
  'statisticsDemandExplanation',
  'statisticsDemandMatchingUsers',
  'statisticsDemandInsufficient',
  'statisticsDemandPrivacyBody',
  'statisticsDemandZeroBody',
  'statisticsDemandTop',
  'statisticsDemandUnavailable',
  'statisticsDemandLoading',
  'statisticsListingDemandVisible',
  'statisticsListingDemandSuppressed',
  'statisticsListingDemandZero',
  'sellerModeTitle',
  'sellerModeRowHint',
  'sellerModeLoadFailed',
  'sellerModeSaveFailed',
  'sellerModePrivateTitle',
  'sellerModePrivateBody',
  'sellerModeProfessionalTitle',
  'sellerModeProfessionalBody',
  'sellerModeVerified',
];

void main() {
  test('RU/RO statistics keys exist, differ, and are not English', () {
    final ruArb =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final roArb =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ru = ruStrings();
    final ro = roStrings();

    for (final key in _keys) {
      expect(ruArb[key], isA<String>(), reason: key);
      expect(roArb[key], isA<String>(), reason: key);
      expect((ruArb[key] as String).trim(), isNotEmpty, reason: key);
      expect((roArb[key] as String).trim(), isNotEmpty, reason: key);
    }

    expect(ru.statisticsTitle, 'Статистика');
    expect(ro.statisticsTitle, 'Statistici');
    expect(ru.statisticsMetricFavorites, 'В избранном');
    expect(ro.statisticsMetricFavorites, isNot(ru.statisticsMetricFavorites));
    expect(ru.statisticsValueUnavailable, '—');
    expect(ro.statisticsValueUnavailable, '—');
    expect(ru.statisticsTitle.toLowerCase(), isNot('statistics'));
    expect(ro.statisticsTitle.toLowerCase(), isNot('statistics'));
    expect(ru.statisticsInterestFunnel, 'Воронка интереса');
    expect(ro.statisticsInterestFunnel, 'Pâlnie de interes');
    expect(ru.statisticsContactActionsTotal, contains('действия'));
    expect(ro.statisticsContactActionsTotal.toLowerCase(), contains('acțiuni'));
    expect(ru.statisticsDemandTitle, 'Спрос покупателей');
    expect(ro.statisticsDemandTitle, 'Cererea cumpărătorilor');
    expect(ru.statisticsDemandInsufficient, 'Недостаточно данных');
    expect(ro.statisticsDemandInsufficient, 'Date insuficiente');
    expect(ru.statisticsDemandTitle.toLowerCase(), isNot('buyer demand'));
    expect(ru.sellerTypeDealer, 'Профессиональный продавец');
    expect(ro.sellerTypeDealer, 'Vânzător profesionist');
    expect(ru.sellerTypeDealer, isNot('Дилер'));
    expect(ro.sellerTypeDealer, isNot('Dealer'));
  });

  test('presentation dart files do not hardcode RU/RO copy', () {
    final root = Directory('lib/features/seller_analytics/presentation');
    final cyrillic = RegExp(r'[А-Яа-яЁё]');
    final romanianMarks = RegExp(r'[ăâîșțĂÂÎȘȚ]');
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      expect(source, isNot(contains(cyrillic)), reason: file.path);
      expect(source, isNot(contains(romanianMarks)), reason: file.path);
    }
  });
}
