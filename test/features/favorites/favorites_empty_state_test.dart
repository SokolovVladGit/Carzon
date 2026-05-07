import 'package:carzon/features/favorites/presentation/widgets/favorites_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Widget _host({
  VoidCallback? onBrowseListings,
  Future<void> Function()? onRefresh,
}) {
  return localizedApp(
    home: Scaffold(
      body: FavoritesEmptyState(
        onRefresh: onRefresh ?? () async {},
        onBrowseListings: onBrowseListings ?? () {},
      ),
    ),
  );
}

void main() {
  final l10n = ruStrings();

  group('FavoritesEmptyState', () {
    testWidgets('renders localized title, body, and primary action', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      expect(find.text(l10n.favoritesEmptyTitle), findsOneWidget);
      expect(find.text(l10n.favoritesEmptyBody), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.favoritesEmptyBrowse),
        findsOneWidget,
      );
    });

    testWidgets('tapping the browse action fires the callback', (tester) async {
      var fired = 0;
      await tester.pumpWidget(_host(onBrowseListings: () => fired += 1));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.favoritesEmptyBrowse),
      );
      await tester.pump();

      expect(fired, 1);
    });
  });
}
