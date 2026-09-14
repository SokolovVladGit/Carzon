import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_daily_point.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_views_sparkline.dart';
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
      home: Scaffold(
        body: StatisticsViewsSparkline(points: points, semanticLabel: 'chart'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('7 and 90 populated points layout without exception', (
    tester,
  ) async {
    await _pump(tester, [
      for (var i = 0; i < 7; i++)
        SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1 + i), views: i + 1),
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
