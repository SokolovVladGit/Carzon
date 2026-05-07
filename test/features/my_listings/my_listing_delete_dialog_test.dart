import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/my_listings/presentation/pages/my_listings_page.dart';
import 'package:carzon/features/my_listings/presentation/widgets/my_listing_tile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Listing _listing({ListingStatus status = ListingStatus.active}) => Listing(
  id: 'l1',
  title: 'title',
  make: 'Make',
  model: 'Model',
  year: 2020,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  status: status,
  sellerId: 's1',
);

Widget _tileHost({
  required ValueChanged<MyListingAction> onAction,
  ListingStatus status = ListingStatus.active,
}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MyListingTile(
        listing: _listing(status: status),
        onAction: onAction,
      ),
    ),
  );
}

void main() {
  final l10n = ruStrings();

  group('MyListingTile owner menu — Delete permanently', () {
    testWidgets(
      'menu exposes the localized delete entry for every listing status',
      (tester) async {
        for (final status in ListingStatus.values) {
          await tester.pumpWidget(_tileHost(onAction: (_) {}, status: status));

          await tester.tap(find.byType(PopupMenuButton<MyListingAction>));
          await tester.pumpAndSettle();

          expect(
            find.text(l10n.actionDeletePermanently),
            findsOneWidget,
            reason: 'Expected delete entry for status=$status',
          );

          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'picking the delete entry dispatches the deletePermanently action',
      (tester) async {
        MyListingAction? picked;
        await tester.pumpWidget(_tileHost(onAction: (a) => picked = a));

        await tester.tap(find.byType(PopupMenuButton<MyListingAction>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.actionDeletePermanently));
        await tester.pumpAndSettle();

        expect(picked, MyListingAction.deletePermanently);
      },
    );
  });

  group('showDeleteListingDialog', () {
    Widget dialogHost(void Function(bool) onResult) {
      return MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showDeleteListingDialog(ctx);
                  onResult(confirmed);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the localized destructive-confirmation copy', (
      tester,
    ) async {
      await tester.pumpWidget(dialogHost((_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteDialogTitle), findsOneWidget);
      expect(find.text(l10n.deleteDialogBody), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, l10n.commonCancel),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, l10n.commonDelete),
        findsOneWidget,
      );
    });

    testWidgets('Cancel resolves the future to false', (tester) async {
      bool? confirmed;
      await tester.pumpWidget(dialogHost((v) => confirmed = v));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets('Delete resolves the future to true', (tester) async {
      bool? confirmed;
      await tester.pumpWidget(dialogHost((v) => confirmed = v));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, l10n.commonDelete));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });
}
