import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/create_listing/presentation/models/listing_preview_data.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compose_layout.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_vin_card.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_media_section.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
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
      final sheens = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_add_photo')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final highlight = sheens
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>()
          .singleWhere((gradient) => gradient.colors.last.a == 0);
      expect(highlight.colors.first.a, closeTo(0.07, 0.001));
      expect(highlight.colors.first.r, greaterThan(0.9));
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
      expect(
        find.byKey(const ValueKey('create_listing_vin_field')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text(l10n.createListingHeroTitle), findsNothing);
      final decoration = tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const ValueKey('create_listing_vin_field')),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration;
      expect(decoration.fillColor, const Color(0xFF1C1916));
      expect(decoration.enabledBorder!.dimensions, EdgeInsets.zero);
      expect(decoration.focusedBorder!.dimensions, EdgeInsets.zero);
      expect(decoration.enabledBorder, isNot(isA<OutlineInputBorder>()));
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('create_listing_vin_field')),
                matching: find.byType(TextField),
              ),
            )
            .style
            ?.color,
        const Color(0xFFF4EDE4),
      );
      expect(
        decoration.hintStyle?.color,
        const Color(0xFFF4EDE4).withValues(alpha: 0.68),
      );
      expect(tester.takeException(), isNull);
    });

    test('dark photo slots keep their fill and pick up a stronger edge', () {
      Border edge(ThemeData theme, {required bool prominent}) {
        return createListingCeramicPlaceholderDecoration(
              theme,
              prominent: prominent,
              radius: 16,
            ).border!
            as Border;
      }

      expect(
        edge(AppTheme.light(), prominent: true).top.color,
        const Color(0xFFD9CBBA),
      );
      expect(
        edge(AppTheme.light(), prominent: false).top.color,
        const Color(0xFFF0E6DC),
      );
      expect(
        edge(AppTheme.dark(), prominent: true).top.color.a,
        closeTo(0.26, 0.001),
      );
      expect(
        edge(AppTheme.dark(), prominent: false).top.color.a,
        closeTo(0.18, 0.001),
      );
    });

    testWidgets('dark preview facts get one extra wrap line', (tester) async {
      const data = ListingPreviewData(
        make: 'BMW',
        model: 'X5',
        submissionTitle: 'BMW X5',
        priceAmount: 20000,
        currency: ListingCurrency.eur,
        marketRegion: MarketRegion.transnistria,
        listingType: ListingType.sale,
        bodyType: ListingBodyType.suv,
        fuelType: ListingFuelType.diesel,
        engineDisplacementLiters: 3,
        enginePowerHp: 249,
        transmissionType: ListingTransmissionType.automatic,
        drivetrain: ListingDrivetrain.awd,
        engineCylinders: 6,
        doors: 5,
        seats: 5,
      );

      Future<void> pump(ThemeData theme) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            themeAnimationDuration: Duration.zero,
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ListingPreviewCard(data: data, l10n: l10n)),
          ),
        );
        await tester.pump();
      }

      await pump(AppTheme.light());
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).maxLines,
        2,
      );
      await pump(AppTheme.dark());
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).maxLines,
        3,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.detailKey)).maxLines,
        3,
      );
      expect(
        tester
            .widget<Text>(find.byKey(ListingPreviewCard.specsKey))
            .style
            ?.height,
        1.35,
      );
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
