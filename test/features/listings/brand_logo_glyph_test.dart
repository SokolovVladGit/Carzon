import 'dart:io';

import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/shared/brands/brand_icon_resolver.dart';
import 'package:carzon/shared/brands/brand_logo_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kPackagedBrandIconSlugs', () {
    test('every packaged slug has a matching SVG file on disk', () {
      for (final slug in kPackagedBrandIconSlugs) {
        expect(
          File(packagedBrandIconAssetPath(slug)).existsSync(),
          isTrue,
          reason: slug,
        );
      }
    });

    test('active packaged SVGs avoid flutter_svg risky constructs', () {
      const forbiddenPatterns = [
        '<image',
        'data:image',
        'base64',
        '<style',
        'class=',
      ];
      for (final slug in kPackagedBrandIconSlugs) {
        final svg = File('assets/brands/svg/$slug.svg').readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          expect(
            svg.contains(pattern),
            isFalse,
            reason: '$slug.svg contains $pattern',
          );
        }
      }
    });
  });

  group('getBrandIconPath', () {
    test('packaged slug resolves to brand SVG', () {
      expect(getBrandIconPath('Toyota'), endsWith('/toyota.svg'));
    });

    test('Volvo resolves to canonical packaged SVG', () {
      expect(getBrandIconPath('Volvo'), endsWith('/volvo.svg'));
      expect(
        isBrandIconDefaultAssetPath(getBrandIconPath('Volvo')),
        isFalse,
      );
    });

    test('newly packaged aliases resolve to brand SVG', () {
      expect(getBrandIconPath('BYD'), endsWith('/byd.svg'));
      expect(getBrandIconPath('Cupra'), endsWith('/cupra.svg'));
      expect(getBrandIconPath('Citroen'), endsWith('/citroen.svg'));
    });

    test('Daihatsu resolves to packaged SVG slug', () {
      expect(getBrandIconPath('Daihatsu'), endsWith('/daihatsu.svg'));
      expect(
        isBrandIconDefaultAssetPath(getBrandIconPath('Daihatsu')),
        isFalse,
      );
    });

    test('newly activated vector brands resolve to packaged SVG slugs', () {
      const cases = {
        'Chevrolet': '/chevrolet.svg',
        'Hongqi': '/hongqi.svg',
        'Subaru': '/subaru.svg',
        'Tank': '/tank.svg',
        'VinFast': '/vinfast.svg',
        'DS Automobiles': '/ds-automobiles.svg',
        'Bestune': '/bestune.svg',
        'FAW': '/faw.svg',
      };
      for (final entry in cases.entries) {
        expect(
          getBrandIconPath(entry.key),
          endsWith(entry.value),
          reason: entry.key,
        );
        expect(
          isBrandIconDefaultAssetPath(getBrandIconPath(entry.key)),
          isFalse,
          reason: entry.key,
        );
      }
    });

    test('GMC and Ram resolve to packaged SVG slugs', () {
      expect(getBrandIconPath('GMC'), endsWith('/gmc.svg'));
      expect(getBrandIconPath('Ram'), endsWith('/ram.svg'));
    });

    test('cleaned feed brands resolve to packaged SVG slugs', () {
      const cases = {
        'Seres': '/seres.svg',
        'Voyah': '/voyah.svg',
        'Foton': '/foton.svg',
        'Cadillac': '/cadillac.svg',
        'Porsche': '/porsche.svg',
        'Wey': '/wey.svg',
        'KGM': '/kgm.svg',
        'Ram': '/ram.svg',
        'Li Auto': '/li-auto.svg',
        'Fiat': '/fiat.svg',
        'Hyundai': '/hyundai.svg',
        'Nissan': '/nissan.svg',
        'MG': '/mg.svg',
        'Omoda': '/omoda.svg',
      };
      for (final entry in cases.entries) {
        expect(
          getBrandIconPath(entry.key),
          endsWith(entry.value),
          reason: entry.key,
        );
        expect(
          isBrandIconDefaultAssetPath(getBrandIconPath(entry.key)),
          isFalse,
          reason: entry.key,
        );
      }
    });

    test('Isuzu resolves to packaged SVG slug', () {
      expect(getBrandIconPath('Isuzu'), endsWith('/isuzu.svg'));
      expect(brandIconSlugFromAssetPath(getBrandIconPath('Isuzu')), 'isuzu');
      expect(isBrandIconDefaultAssetPath(getBrandIconPath('Isuzu')), isFalse);
    });
  });

  group('isBrandIconMonochromeAssetPath', () {
    test('Toyota is monochrome', () {
      expect(
        isBrandIconMonochromeAssetPath(getBrandIconPath('Toyota')),
        isTrue,
      );
    });

    test('BMW is not monochrome', () {
      expect(isBrandIconMonochromeAssetPath(getBrandIconPath('BMW')), isFalse);
    });

    test('complex feed marks are not listing-card monochrome tint targets', () {
      for (final make in ['Nissan', 'Chevrolet', 'Cupra', 'Ford']) {
        expect(
          isBrandIconMonochromeAssetPath(getBrandIconPath(make)),
          isFalse,
          reason: make,
        );
      }
    });

    test('multicolor feed brands keep native rendering path', () {
      for (final make in [
        'BMW',
        'Mercedes-Benz',
        'Audi',
        'Volkswagen',
        'Skoda',
        'Porsche',
        'Volvo',
      ]) {
        expect(
          isBrandIconMonochromeAssetPath(getBrandIconPath(make)),
          isFalse,
          reason: make,
        );
      }
    });
  });

  group('isBrandIconDiscoveryFeedSimpleTintAssetPath', () {
    test('simple emblems may use feed metallic tint', () {
      for (final make in ['Toyota', 'Honda', 'Mazda']) {
        expect(
          isBrandIconDiscoveryFeedSimpleTintAssetPath(getBrandIconPath(make)),
          isTrue,
          reason: make,
        );
      }
    });

    test('wordmark and complex marks stay native on feed', () {
      for (final make in [
        'Nissan',
        'Ford',
        'Chevrolet',
        'Volkswagen',
        'BMW',
        'Mercedes-Benz',
        'Audi',
        'Skoda',
        'Volvo',
      ]) {
        expect(
          isBrandIconDiscoveryFeedSimpleTintAssetPath(getBrandIconPath(make)),
          isFalse,
          reason: make,
        );
      }
    });
  });

  group('isBrandIconDiscoveryFeedLightBackplateAssetPath', () {
    test('simple emblem marks skip porcelain backplate on feed', () {
      for (final make in [
        'Toyota',
        'Honda',
        'Mazda',
      ]) {
        expect(
          isBrandIconDiscoveryFeedLightBackplateAssetPath(
            getBrandIconPath(make),
          ),
          isFalse,
          reason: make,
        );
      }
    });

    test('complex and multicolor marks use porcelain backplate on feed', () {
      for (final make in [
        'Volvo',
        'BMW',
        'Mercedes-Benz',
        'Audi',
        'Skoda',
        'Porsche',
        'Tesla',
        'Nissan',
        'Ford',
        'Chevrolet',
        'Volkswagen',
        'Opel',
        'Fiat',
      ]) {
        expect(
          isBrandIconDiscoveryFeedLightBackplateAssetPath(
            getBrandIconPath(make),
          ),
          isTrue,
          reason: make,
        );
      }
    });
  });

  group('brandIconDiscoveryFeedBackplateInnerFraction', () {
    test('Volvo uses boosted inner fraction on porcelain backplate', () {
      expect(
        brandIconDiscoveryFeedBackplateInnerFraction(getBrandIconPath('Volvo')),
        0.90,
      );
    });

    test('balanced brands keep default inner fraction', () {
      for (final make in ['Audi', 'BMW', 'Toyota', 'Ford', 'Fiat']) {
        expect(
          brandIconDiscoveryFeedBackplateInnerFraction(getBrandIconPath(make)),
          kBrandIconDiscoveryFeedBackplateInnerFractionDefault,
          reason: make,
        );
      }
    });

    test('override map keys match packaged slugs', () {
      for (final slug
          in kBrandIconDiscoveryFeedBackplateInnerFractionBySlug.keys) {
        expect(kPackagedBrandIconSlugs, contains(slug));
      }
    });
  });

  group('BrandLogoGlyph', () {
    testWidgets('dark mode wraps known brand SVG in contrast well', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Toyota'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkWellKey), findsOneWidget);
    });

    testWidgets('dark mode tints monochrome Toyota SVG', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Toyota'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkTintKey), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNotNull);
    });

    testWidgets('dark mode does not tint colored BMW SVG', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('BMW'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('light mode does not add dark well or tint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Toyota'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkWellKey), findsNothing);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('dark mode unknown brand uses icon without well', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('TotallyUnknownMakeXYZ'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkWellKey), findsNothing);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('tintMonochromeInDarkMode false disables tint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Toyota'),
                size: 32,
                tintMonochromeInDarkMode: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('dark mode keeps Nissan native without flattening tint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Nissan'),
                size: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('discovery feed tints simple Toyota emblem moderately', (
      tester,
    ) async {
      final scheme = AppTheme.dark().colorScheme;
      final feedTint = AppTheme.discoveryFeedBrandLogoColor(scheme);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Toyota'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: feedTint,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        ColorFilter.mode(feedTint, BlendMode.srcIn),
      );
      expect(feedTint.a, closeTo(0.90, 0.01));
    });

    testWidgets('discovery feed keeps Ford native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Ford'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('discovery feed keeps Nissan native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Nissan'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('discovery feed keeps Chevrolet native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Chevrolet'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('discovery feed keeps Opel native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Opel'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('discovery feed keeps BMW native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('BMW'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('discovery feed keeps Skoda native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Skoda'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets(
      'discovery feed keeps Mercedes-Benz native with porcelain backplate',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Center(
                child: BrandLogoGlyph(
                  assetPath: getBrandIconPath('Mercedes-Benz'),
                  size: 34,
                  discoveryFeedPresentation: true,
                  darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                    AppTheme.dark().colorScheme,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
        expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      },
    );

    testWidgets('discovery feed keeps Audi native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Audi'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('discovery feed keeps Volvo native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Volvo'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    testWidgets('Volvo readableOnDark keeps native badge without tint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: BrandLogoGlyph.readableOnDark(
                  context: context,
                  assetPath: getBrandIconPath('Volvo'),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('Volvo readableOnDark uses boosted inner glyph on backplate', (
      tester,
    ) async {
      const outerSize = 32.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: BrandLogoGlyph.readableOnDark(
                  context: context,
                  assetPath: getBrandIconPath('Volvo'),
                  size: outerSize,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final volvoSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        volvoSvg.width,
        outerSize *
            brandIconDiscoveryFeedBackplateInnerFraction(
              getBrandIconPath('Volvo'),
            ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: BrandLogoGlyph.readableOnDark(
                  context: context,
                  assetPath: getBrandIconPath('BMW'),
                  size: outerSize,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bmwSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        bmwSvg.width,
        outerSize *
            brandIconDiscoveryFeedBackplateInnerFraction(
              getBrandIconPath('BMW'),
            ),
      );
      expect(volvoSvg.width, greaterThan(bmwSvg.width!));
    });

    test('Volvo is not classified for simple feed tint', () {
      expect(
        isBrandIconDiscoveryFeedSimpleTintAssetPath(getBrandIconPath('Volvo')),
        isFalse,
      );
      expect(
        isBrandIconMonochromeAssetPath(getBrandIconPath('Volvo')),
        isFalse,
      );
      expect(getBrandIconPath('Toyota'), endsWith('/toyota.svg'));
      expect(
        isBrandIconDiscoveryFeedSimpleTintAssetPath(getBrandIconPath('Toyota')),
        isTrue,
      );
    });

    testWidgets('discovery feed keeps Fiat native with porcelain backplate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: BrandLogoGlyph(
                assetPath: getBrandIconPath('Fiat'),
                size: 34,
                discoveryFeedPresentation: true,
                darkTintColorOverride: AppTheme.discoveryFeedBrandLogoColor(
                  AppTheme.dark().colorScheme,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('readableOnDark uses porcelain backplate for Audi', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: BrandLogoGlyph.readableOnDark(
                  context: context,
                  assetPath: getBrandIconPath('Audi'),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsNothing);
    });

    testWidgets('readableOnDark light mode stays flat without plate', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: BrandLogoGlyph.readableOnDark(
                  context: context,
                  assetPath: getBrandIconPath('Audi'),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsNothing);
      expect(find.byKey(brandLogoDarkWellKey), findsNothing);
    });
  });
}
