import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

CompareItem _compareItem(String id) => CompareItem(
  snapshot: CompareListingSnapshot(
    listingId: id,
    addedAt: DateTime.utc(2026, 5, 1),
    coverImageUrl: 'https://example.com/$id.jpg',
    make: 'Audi',
    model: 'A4',
  ),
);

void main() {
  final ru = ruStrings();

  Future<void> pumpTray(
    WidgetTester tester, {
    required List<CompareItem> items,
    VoidCallback? onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CompareFloatingTray(
            items: items,
            onOpenCompare: onOpen ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows one-vehicle title and add-more hint', (tester) async {
    await pumpTray(tester, items: [_compareItem('a')]);

    expect(find.text(ru.compareTrayOneVehicle), findsOneWidget);
    expect(find.text(ru.compareTrayAddOneMore), findsOneWidget);
    expect(find.text(ru.compareTrayOpen), findsNothing);
  });

  testWidgets('shows count title and compare hint for two vehicles', (
    tester,
  ) async {
    await pumpTray(
      tester,
      items: [_compareItem('a'), _compareItem('b')],
    );

    expect(find.text(ru.compareTrayVehicleCount(2)), findsOneWidget);
    expect(find.text(ru.compareTrayOpen), findsOneWidget);
    expect(find.text(ru.compareTrayAddOneMore), findsNothing);
  });

  testWidgets('shows three thumbnails and compare hint for three vehicles', (
    tester,
  ) async {
    await pumpTray(
      tester,
      items: [
        _compareItem('a'),
        _compareItem('b'),
        _compareItem('c'),
      ],
    );

    expect(find.text(ru.compareTrayVehicleCount(3)), findsOneWidget);
    expect(find.text(ru.compareTrayOpen), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('tray thumbnails do not use ListingCoverImage', (tester) async {
    await pumpTray(tester, items: [_compareItem('a')]);

    expect(find.byType(ListingCoverImage), findsNothing);
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.width, 44);
      expect(image.height, 44);
      expect(image.fit, BoxFit.cover);
    }
  });

  testWidgets('thumbnail stack clips overflowing children', (tester) async {
    await pumpTray(
      tester,
      items: [_compareItem('a'), _compareItem('b'), _compareItem('c')],
    );

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(CompareFloatingTray),
        matching: find.byType(Stack),
      ).first,
    );
    expect(stack.clipBehavior, Clip.hardEdge);
  });

  testWidgets('tap invokes open compare callback', (tester) async {
    var opened = false;
    await pumpTray(
      tester,
      items: [_compareItem('a')],
      onOpen: () => opened = true,
    );

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pump();

    expect(opened, isTrue);
  });
}
