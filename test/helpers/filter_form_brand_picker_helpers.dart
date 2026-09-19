import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vertical form ListView, not a TextField inner editable Scrollable.
Finder listingFilterFormVerticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Future<void> pickListingFilterBrand(
  WidgetTester tester,
  String catalogEnglish,
) async {
  final trigger = find.byKey(
    const ValueKey<String>('listings_filter_make_pick_trigger'),
  );
  await tester.ensureVisible(trigger);
  await tester.pumpAndSettle();
  await tester.tap(trigger);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, catalogEnglish);
  await tester.pumpAndSettle();
  await tester.tap(find.text(catalogEnglish).last);
  await tester.pumpAndSettle();
}
