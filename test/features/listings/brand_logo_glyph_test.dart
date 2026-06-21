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
          File('assets/brands/svg/$slug.svg').existsSync(),
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
  });
}
