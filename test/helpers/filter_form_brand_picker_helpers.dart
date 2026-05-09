import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pickListingFilterBrand(
  WidgetTester tester,
  String catalogEnglish,
) async {
  final trigger = find.byKey(
    const ValueKey<String>('listings_filter_make_pick_trigger'),
  );
  await tester.scrollUntilVisible(
    trigger,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(trigger);
  await tester.pumpAndSettle();
  await tester.tap(find.text(catalogEnglish));
  await tester.pumpAndSettle();
}
