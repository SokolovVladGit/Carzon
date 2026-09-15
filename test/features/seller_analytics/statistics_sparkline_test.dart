import 'package:carzon/core/l10n/app_localizations_x.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_daily_point.dart';
import 'package:carzon/features/seller_analytics/presentation/utils/statistics_formatters.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_views_sparkline.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<SellerAnalyticsDailyPoint> _points(int count, {int views = 0}) {
  return [
    for (var i = 0; i < count; i++)
      SellerAnalyticsDailyPoint(
        date: DateTime(2026, 7, 1).add(Duration(days: i)),
        views: views,
      ),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  List<SellerAnalyticsDailyPoint> points,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return StatisticsViewsSparkline(
              points: points,
              semanticLabel: 'chart',
              localeName: context.l10n.localeName,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('zero maps to the plot baseline, not the vertical center', () {
    const scale = StatisticsViewsChartScale(dataMax: 10, plotMax: 11.2);
    expect(scale.yFor(0, topY: 0, bottomY: 100), 100);
    expect(scale.yFor(11.2, topY: 0, bottomY: 100), 0);
    expect(scale.yFor(10, topY: 0, bottomY: 100), lessThan(20));
  });

  test('all-zero series uses a unit plot max and keeps zero at the bottom', () {
    final scale = StatisticsViewsChartScale.fromViews(const [0, 0, 0]);
    expect(scale.dataMax, 0);
    expect(scale.plotMax, 1);
    expect(scale.yFor(0, topY: 8, bottomY: 100), 100);
  });

  test('equal non-zero values sit near the top, not the mid-line', () {
    final scale = StatisticsViewsChartScale.fromViews(const [4, 4, 4]);
    final y = scale.yFor(4, topY: 0, bottomY: 100);
    expect(y, lessThan(20));
    expect(y, greaterThan(0));
  });

  test('label indices stay sparse for 7/30/90', () {
    expect(statisticsChartLabelIndices(7), [0, 3, 6]);
    expect(statisticsChartLabelIndices(30), [0, 10, 19, 29]);
    expect(statisticsChartLabelIndices(90).length, 4);
    expect(statisticsChartLabelIndices(90).first, 0);
    expect(statisticsChartLabelIndices(90).last, 89);
  });

  test('micro ticks are denser than date labels', () {
    expect(statisticsChartMicroTickIndices(7), [0, 1, 2, 3, 4, 5, 6]);
    expect(statisticsChartMicroTickIndices(30).length, 30);
    expect(statisticsChartMicroTickIndices(90).length, 90);
  });

  testWidgets('all-zero points paint without exception', (tester) async {
    await _pump(tester, _points(7));
    expect(tester.takeException(), isNull);
    expect(find.byKey(StatisticsViewsSparkline.chartKey), findsOneWidget);
  });

  testWidgets('single and few populated points paint safely', (tester) async {
    await _pump(tester, [
      SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1), views: 4),
    ]);
    expect(tester.takeException(), isNull);

    await _pump(tester, [
      SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1), views: 1),
      SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 2), views: 1),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('7, 30 and 90 populated points layout without exception', (
    tester,
  ) async {
    await _pump(tester, [
      for (var i = 0; i < 7; i++)
        SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1 + i), views: i + 1),
    ]);
    expect(tester.takeException(), isNull);

    await _pump(tester, [
      for (var i = 0; i < 30; i++)
        SellerAnalyticsDailyPoint(
          date: DateTime(2026, 8, 1).add(Duration(days: i)),
          views: i.isEven ? 0 : 2,
        ),
    ]);
    expect(tester.takeException(), isNull);

    await _pump(tester, [
      for (var i = 0; i < 90; i++)
        SellerAnalyticsDailyPoint(
          date: DateTime(2026, 6, 1).add(Duration(days: i)),
          views: i.isEven ? 0 : 3,
        ),
    ]);
    expect(tester.takeException(), isNull);
    expect(find.byType(StatisticsViewsSparkline), findsOneWidget);
  });
}
