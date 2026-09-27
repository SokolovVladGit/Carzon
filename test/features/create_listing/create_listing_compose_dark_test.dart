import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compose_layout.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_vin_card.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_media_section.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  group('Create listing compose dark editorial', () {
    testWidgets('flattened section renders heading and photo block', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: createListingCanvasColor(AppTheme.dark()),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CreateListingFormSection(
                title: l10n.createListingMediaTitle,
                child: CreateListingMediaSection(
                  photos: const [],
                  pickingImage: false,
                  disabled: false,
                  onAddPhoto: () {},
                  onRemovePhotoAt: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.createListingMediaTitle), findsOneWidget);
      expect(find.text(l10n.createListingAddPhoto), findsOneWidget);
      expect(
        find.byKey(CreateListingMediaSection.phase3TestKey),
        findsOneWidget,
      );
    });

    testWidgets('vin hero uses car background in dark theme', (tester) async {
      final vin = TextEditingController();
      addTearDown(vin.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CreateListingVinCard(
              l10n: l10n,
              theme: AppTheme.dark(),
              controller: vin,
              enabled: true,
              scanning: false,
              onScan: () {},
              onChanged: (_) {},
              validator: (_) => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(CreateListingVinCard.heroKey), findsOneWidget);
      final image = tester.widget<Image>(
        find.byKey(CreateListingVinCard.imageKey),
      );
      expect(image.fit, BoxFit.cover);
      expect(
        (image.image as AssetImage).assetName,
        'assets/bg/car_bg_listing.png',
      );
      expect(find.text(l10n.createListingHeroTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppTheme editorial dark helpers', () {
    test('light mode returns null for dark-only decorations', () {
      final scheme = AppTheme.light().colorScheme;
      expect(AppTheme.editorialDarkHeroCard(scheme), isNull);
      expect(
        AppTheme.editorialDarkSectionCard(scheme, borderRadius: 20),
        isNull,
      );
      expect(AppTheme.editorialDarkPhotoFrame(scheme), isNull);
    });

    test('dark mode provides editorial decorations', () {
      final scheme = AppTheme.dark().colorScheme;
      expect(AppTheme.editorialDarkHeroCard(scheme), isNotNull);
      expect(
        AppTheme.editorialDarkSectionCard(scheme, borderRadius: 20),
        isNotNull,
      );
      expect(AppTheme.editorialDarkStepBadge(scheme), isNotNull);
      expect(AppTheme.editorialDarkPhotoFrame(scheme), isNotNull);
    });
  });
}
