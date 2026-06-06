import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_card.dart';
import 'package:carzon/features/my_listings/presentation/widgets/my_listing_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Listing _seed({ListingStatus status = ListingStatus.active}) => Listing(
  id: 'l1',
  title: 'BMW 320',
  make: 'BMW',
  model: '320',
  year: 2018,
  priceEur: 12000,
  mileageKm: 80000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 1, 1),
  status: status,
  sellerId: 's1',
);

void main() {
  final l10n = ruStrings();

  group('MyListingTile visual contract', () {
    testWidgets('renders the content of the redesigned ListingCard', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MyListingTile(listing: _seed(), onAction: (_) {}),
          ),
        ),
      );

      expect(find.byType(ListingCard), findsOneWidget);
      expect(find.text('BMW 320'), findsOneWidget);
      expect(find.text('€12 000'), findsOneWidget);
      expect(find.text('80 000 ${l10n.commonKilometersShort}'), findsOneWidget);
      expect(find.text('2018'), findsOneWidget);
      expect(find.text('Chișinău'), findsOneWidget);
      expect(find.text(l10n.regionMoldova), findsOneWidget);
    });

    testWidgets(
      'surfaces the localized status pill for every ListingStatus value',
      (tester) async {
        const expected = {
          ListingStatus.active: 'statusActive',
          ListingStatus.hidden: 'statusHidden',
          ListingStatus.sold: 'statusSold',
          ListingStatus.archived: 'statusArchived',
        };
        for (final entry in expected.entries) {
          await pumpLocalizedWidget(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                child: MyListingTile(
                  listing: _seed(status: entry.key),
                  onAction: (_) {},
                ),
              ),
            ),
          );

          final label = switch (entry.key) {
            ListingStatus.active => l10n.statusActive,
            ListingStatus.hidden => l10n.statusHidden,
            ListingStatus.sold => l10n.statusSold,
            ListingStatus.archived => l10n.statusArchived,
          };
          expect(
            find.text(label),
            findsOneWidget,
            reason: 'expected ${entry.value} badge for status ${entry.key}',
          );
        }
      },
    );

    testWidgets(
      'exposes the owner action menu button when onAction is supplied',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: MyListingTile(listing: _seed(), onAction: (_) {}),
            ),
          ),
        );

        expect(find.byType(PopupMenuButton<MyListingAction>), findsOneWidget);
      },
    );

    testWidgets(
      'shows a pending spinner in place of the actions menu when isPending',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: MyListingTile(
                listing: _seed(),
                isPending: true,
                onAction: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(PopupMenuButton<MyListingAction>), findsNothing);
      },
    );
  });
}
