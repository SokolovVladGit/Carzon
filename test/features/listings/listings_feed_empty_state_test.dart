import 'package:carzon/features/listings/presentation/widgets/listings_feed_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Widget _host({
  required bool hasFilters,
  bool includeBodyFilterEmptyHint = false,
  VoidCallback? onResetFilters,
  Future<void> Function()? onRefresh,
}) {
  return localizedApp(
    home: Scaffold(
      body: ListingsFeedEmptyState(
        hasFilters: hasFilters,
        includeBodyFilterEmptyHint: includeBodyFilterEmptyHint,
        onResetFilters: onResetFilters ?? () {},
        onRefresh: onRefresh ?? () async {},
      ),
    ),
  );
}

void main() {
  final l10n = ruStrings();

  group('ListingsFeedEmptyState', () {
    testWidgets('renders the no-filters copy and no reset action', (
      tester,
    ) async {
      await tester.pumpWidget(_host(hasFilters: false));
      await tester.pump();

      expect(find.text(l10n.listingsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.listingsEmptyBody), findsOneWidget);
      expect(find.text(l10n.listingsEmptyFilteredBody), findsNothing);
      // No reset-filters button when no filters are active.
      expect(
        find.widgetWithText(OutlinedButton, l10n.listingsEmptyResetFilters),
        findsNothing,
      );
    });

    testWidgets(
      'renders the filter-active copy and an OutlinedButton reset action',
      (tester) async {
        await tester.pumpWidget(_host(hasFilters: true));
        await tester.pump();

        expect(find.text(l10n.listingsEmptyTitle), findsOneWidget);
        expect(find.text(l10n.listingsEmptyFilteredBody), findsOneWidget);
        expect(find.text(l10n.listingsEmptyBody), findsNothing);
        expect(
          find.widgetWithText(OutlinedButton, l10n.listingsEmptyResetFilters),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'with body-chip context, appends localized note about NULL body_type',
      (tester) async {
        await tester.pumpWidget(
          _host(hasFilters: true, includeBodyFilterEmptyHint: true),
        );
        await tester.pump();

        expect(
          find.text(
            '${l10n.listingsEmptyFilteredBody}\n\n'
            '${l10n.listingsEmptyBodyTypeFilterNote}',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping the reset-filters action fires the callback', (
      tester,
    ) async {
      var fired = 0;
      await tester.pumpWidget(
        _host(hasFilters: true, onResetFilters: () => fired += 1),
      );
      await tester.pump();

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.listingsEmptyResetFilters),
      );
      await tester.pump();

      expect(fired, 1);
    });
  });
}
