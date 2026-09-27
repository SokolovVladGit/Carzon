import 'dart:convert';
import 'dart:typed_data';

import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/create_listing/domain/constants/listing_gallery_limits.dart';
import 'package:carzon/features/create_listing/presentation/models/create_listing_photo_draft.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_media_section.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_vin_card.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();
  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  CreateListingPhotoDraft photo(int n) => CreateListingPhotoDraft(
    bytes: png,
    contentType: 'image/png',
    fileName: '$n.png',
  );

  Widget mediaHost({
    required List<CreateListingPhotoDraft> photos,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
    ThemeData? theme,
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: size.width - 32,
              child: CreateListingMediaSection(
                photos: photos,
                pickingImage: false,
                disabled: false,
                onAddPhoto: onAdd,
                onRemovePhotoAt: onRemove,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('photo 0 is the large cover tile', (tester) async {
    await tester.pumpWidget(
      mediaHost(
        photos: [photo(0), photo(1), photo(2)],
        onAdd: () {},
        onRemove: (_) {},
      ),
    );
    await tester.pump();

    final cover = tester.getSize(
      find.byKey(CreateListingMediaSection.coverKey),
    );
    final side = tester.getSize(
      find.byKey(const ValueKey('create_listing_photo_1')),
    );
    expect(cover.width, greaterThan(side.width));
    expect(cover.height, greaterThan(side.height * 1.5));
    expect(
      tester.getTopLeft(find.byKey(CreateListingMediaSection.coverKey)).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('create_listing_photo_1')))
            .dx,
      ),
    );
    expect(find.text(l10n.createListingCoverBadge), findsOneWidget);
    expect(
      tester
          .widget<Image>(
            find.descendant(
              of: find.byKey(CreateListingMediaSection.coverKey),
              matching: find.byType(Image),
            ),
          )
          .fit,
      BoxFit.cover,
    );
  });

  testWidgets('photos 1-4 sit in the right grid and 5-8 in the strip', (
    tester,
  ) async {
    await tester.pumpWidget(
      mediaHost(
        photos: [for (var i = 0; i < 9; i++) photo(i)],
        onAdd: () {},
        onRemove: (_) {},
      ),
    );
    await tester.pump();

    final cover = tester.getRect(
      find.byKey(CreateListingMediaSection.coverKey),
    );
    final photo1 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_1')),
    );
    final photo2 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_2')),
    );
    final photo3 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_3')),
    );
    final photo4 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_4')),
    );
    final photo5 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_5')),
    );
    final photo8 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_8')),
    );

    expect(photo1.left, greaterThan(cover.left));
    expect(photo2.left, greaterThan(photo1.left));
    expect((photo1.top - photo2.top).abs(), lessThan(2));
    expect(photo3.top, greaterThan(photo1.top));
    expect(photo4.left, greaterThan(photo3.left));
    expect(photo4.top, greaterThan(photo2.bottom - 2));
    expect(photo5.top, greaterThan(cover.bottom - 1));
    expect(photo8.top, greaterThan(cover.bottom - 1));
    expect(photo5.left, closeTo(cover.left, 1));
    expect(photo8.right, closeTo(photo2.right, 1));
    final photo6 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_6')),
    );
    final photo7 = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_7')),
    );
    expect(photo5.width, closeTo(photo6.width, 1));
    expect(photo6.width, closeTo(photo7.width, 1));
    expect(photo7.width, closeTo(photo8.width, 1));
    expect(photo5.width, greaterThan(76));
    expect(photo6.left - photo5.right, closeTo(photo8.left - photo7.right, 1));
    expect(
      find.byKey(const ValueKey('create_listing_add_photo')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial secondary row stays constrained until three cells', (
    tester,
  ) async {
    await tester.pumpWidget(
      mediaHost(
        photos: [for (var i = 0; i < 6; i++) photo(i)],
        onAdd: () {},
        onRemove: (_) {},
      ),
    );
    await tester.pump();
    final cover = tester.getRect(
      find.byKey(CreateListingMediaSection.coverKey),
    );
    final side = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_2')),
    );
    final secondary = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_5')),
    );
    final add = tester.getRect(
      find.byKey(const ValueKey('create_listing_add_photo')),
    );
    expect(secondary.width, 76);
    expect(add.width, 76);
    expect(add.right, lessThan(side.right - 40));
    expect(secondary.left, closeTo(cover.left, 1));

    await tester.pumpWidget(
      mediaHost(
        photos: [for (var i = 0; i < 7; i++) photo(i)],
        onAdd: () {},
        onRemove: (_) {},
      ),
    );
    await tester.pump();
    final fullRight = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_2')),
    );
    final first = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_5')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_6')),
    );
    final addSlot = tester.getRect(
      find.byKey(const ValueKey('create_listing_add_photo')),
    );
    expect(first.left, closeTo(cover.left, 1));
    expect(addSlot.right, closeTo(fullRight.right, 1));
    expect(first.width, closeTo(second.width, 1));
    expect(second.width, closeTo(addSlot.width, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery keeps the 9-photo contract and add/remove callbacks', (
    tester,
  ) async {
    expect(kMaxListingPhotos, 9);
    var added = 0;
    int? removed;
    await tester.pumpWidget(
      mediaHost(
        photos: [photo(0)],
        onAdd: () => added++,
        onRemove: (index) => removed = index,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create_listing_add_photo')));
    await tester.tap(
      find.byKey(const ValueKey('create_listing_remove_photo_0')),
    );
    expect(added, 1);
    expect(removed, 0);

    await tester.pumpWidget(
      mediaHost(
        photos: [for (var i = 0; i < 9; i++) photo(i)],
        onAdd: () => added++,
        onRemove: (_) {},
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('create_listing_add_photo')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photo_8')),
      findsOneWidget,
    );
    expect(added, 1);
  });

  testWidgets('vin field and scan stay wired at a narrow width', (
    tester,
  ) async {
    final vin = TextEditingController();
    addTearDown(vin.dispose);
    String? changed;
    var scanned = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 700)),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CreateListingVinCard(
                  l10n: l10n,
                  theme: AppTheme.light(),
                  controller: vin,
                  enabled: true,
                  scanning: false,
                  onScan: () => scanned++,
                  onChanged: (value) => changed = value,
                  validator: (_) => null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      (tester.widget<Image>(find.byKey(CreateListingVinCard.imageKey)).image
              as AssetImage)
          .assetName,
      'assets/bg/car_bg_listing.png',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      'WVWZZZ',
    );
    expect(changed, 'WVWZZZ');
    await tester.tap(find.byKey(const ValueKey('create_listing_scan_vin')));
    expect(scanned, 1);
    expect(find.text(l10n.createListingManualVehicleTitle), findsNothing);
  });

  testWidgets('vin input and scan share one row at iPhone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vin = TextEditingController();
    addTearDown(vin.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CreateListingVinCard(
              l10n: l10n,
              theme: AppTheme.light(),
              controller: vin,
              enabled: true,
              scanning: false,
              onScan: () {},
              onChanged: (_) {},
              validator: (_) => null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.getTopLeft(
      find.byKey(const ValueKey('create_listing_vin_field')),
    );
    final scan = tester.getTopLeft(
      find.byKey(const ValueKey('create_listing_scan_vin')),
    );
    expect((field.dy - scan.dy).abs(), lessThan(8));
    expect(field.dx, lessThan(scan.dx));
    expect(find.text(l10n.createListingScanVinShort), findsOneWidget);
    final scanBox = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('create_listing_scan_vin')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final scanDecoration = scanBox.decoration as BoxDecoration;
    final scanBorder = scanDecoration.border! as Border;
    expect(scanDecoration.color, const Color(0xFF3A424C));
    expect(scanBorder.top.width, 1.25);
    expect(scanBorder.top.color.a, greaterThan(0.4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark gallery does not throw', (tester) async {
    await tester.pumpWidget(
      mediaHost(
        photos: [photo(0), photo(1)],
        onAdd: () {},
        onRemove: (_) {},
        theme: AppTheme.dark(),
        size: const Size(320, 700),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(CreateListingMediaSection.coverKey), findsOneWidget);
  });
}
