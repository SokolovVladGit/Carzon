import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/shared/brands/brand_icon_resolver.dart';
import 'package:carzon/shared/brands/brand_logo_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
