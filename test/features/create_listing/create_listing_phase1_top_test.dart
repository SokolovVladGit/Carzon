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

  testWidgets('photo 0 is the cover tile in the 3x3 grid', (tester) async {
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
    expect((cover.width - side.width).abs(), lessThan(2));
    expect((cover.height - side.height).abs(), lessThan(2));
    expect((cover.width - cover.height).abs(), lessThan(2));
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

  testWidgets('empty gallery renders all nine positions', (tester) async {
    await tester.pumpWidget(
      mediaHost(
        photos: const <CreateListingPhotoDraft>[],
        onAdd: () {},
        onRemove: (_) {},
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('create_listing_add_photo')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_photo_placeholder')),
      findsNWidgets(8),
    );
    expect(find.text(l10n.createListingCoverBadge), findsNothing);
    final section = tester.getRect(
      find.byKey(CreateListingMediaSection.phase3TestKey),
    );
    final add = tester.getRect(
      find.byKey(const ValueKey('create_listing_add_photo')),
    );
    expect(add.left, closeTo(section.left, 1));
    expect(add.top, closeTo(section.top, 1));
    expect((add.width - add.height).abs(), lessThan(2));
    expect(section.height, closeTo(add.height * 3 + 16, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nine photos fill a 3x3 grid', (tester) async {
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

    expect(photo1.left, greaterThan(cover.right - 1));
    expect(photo2.left, greaterThan(photo1.right - 1));
    expect((photo1.top - cover.top).abs(), lessThan(2));
    expect((photo2.top - cover.top).abs(), lessThan(2));
    expect(photo3.top, greaterThan(cover.bottom - 1));
    expect(photo4.left, greaterThan(photo3.right - 1));
    expect((photo4.top - photo3.top).abs(), lessThan(2));
    expect(photo5.left, greaterThan(photo4.right - 1));
    expect((photo5.top - photo3.top).abs(), lessThan(2));
    expect(photo8.top, greaterThan(photo5.bottom - 1));
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
    expect((photo5.width - cover.width).abs(), lessThan(2));
    expect(photo6.left, closeTo(cover.left, 1));
    expect(photo7.left - photo6.right, closeTo(photo8.left - photo7.right, 1));
    expect(
      find.byKey(const ValueKey('create_listing_add_photo')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('open slots stay in the 3x3 at the same size', (tester) async {
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
    expect((add.width - cover.width).abs(), lessThan(2));
    expect(add.top, greaterThan(secondary.bottom - 1));
    expect(add.left, closeTo(cover.left, 1));
    expect(add.right, lessThan(side.right));
    expect(
      find.byKey(const ValueKey('create_listing_photo_placeholder')),
      findsNWidgets(2),
    );

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
    final second = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_6')),
    );
    final addSlot = tester.getRect(
      find.byKey(const ValueKey('create_listing_add_photo')),
    );
    final last = tester.getRect(
      find.byKey(const ValueKey('create_listing_photo_placeholder')),
    );
    expect(second.left, closeTo(cover.left, 1));
    expect(addSlot.left, greaterThan(second.right - 1));
    expect(last.right, closeTo(fullRight.right, 1));
    expect((second.width - addSlot.width).abs(), lessThan(2));
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
    expect(find.byKey(CreateListingVinCard.heroKey), findsOneWidget);
    expect(find.byType(Image), findsNothing);
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

  testWidgets('17-character VIN fits beside scan at 375 and 390', (
    tester,
  ) async {
    const vinText = '1HGBH41JXMN109186';
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [375.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      final controller = TextEditingController(text: vinText);
      addTearDown(controller.dispose);
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
                controller: controller,
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
      expect(tester.takeException(), isNull);
      final field = tester.getRect(
        find.byKey(const ValueKey('create_listing_vin_field')),
      );
      final scan = tester.getRect(
        find.byKey(const ValueKey('create_listing_scan_vin')),
      );
      expect(field.right, lessThanOrEqualTo(scan.left + 1));
      expect((field.center.dy - scan.center.dy).abs(), lessThan(8));
      expect(field.width, greaterThan(190));
      expect(scan.width, inInclusiveRange(76, 112));
      expect(scan.height, greaterThanOrEqualTo(44));
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_vin_field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.controller.text, vinText);
      expect(editable.style.fontSize, 15);
      expect(editable.style.letterSpacing, lessThanOrEqualTo(0.35));
      expect(
        editable.style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      // Real-device cap width is well under the test font. 9px × 17 leaves
      // the field's content box (padding 12 + 8) with room at 375.
      expect(field.width - 20, greaterThan(17 * 9));
    }
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
