import 'package:carzon/features/my_listings/presentation/widgets/my_listings_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Widget _host({VoidCallback? onCreate}) {
  return localizedApp(
    home: Scaffold(body: MyListingsEmptyState(onCreate: onCreate ?? () {})),
  );
}

void main() {
  final l10n = ruStrings();

  group('MyListingsEmptyState', () {
    testWidgets('renders localized title, body, and primary action', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      expect(find.text(l10n.myListingsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.myListingsEmptyBody), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.myListingsSellCta),
        findsOneWidget,
      );
    });

    testWidgets('tapping the primary action fires the callback', (
      tester,
    ) async {
      var fired = 0;
      await tester.pumpWidget(_host(onCreate: () => fired += 1));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.myListingsSellCta),
      );
      await tester.pump();

      expect(fired, 1);
    });
  });
}
