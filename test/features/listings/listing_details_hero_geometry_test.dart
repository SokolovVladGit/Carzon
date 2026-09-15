import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingDetailsHeroHeightForWidth', () {
    test('uses 4:3 height on a typical iPhone width', () {
      expect(listingDetailsHeroHeightForWidth(390), closeTo(292.5, 1e-9));
    });

    test('clamps compact widths so overlay controls still fit', () {
      expect(listingDetailsHeroHeightForWidth(320), 270);
    });

    test('clamps wide phones so the hero stays landscape', () {
      expect(listingDetailsHeroHeightForWidth(430), 320);
    });

    test('falls back when width is not usable', () {
      expect(listingDetailsHeroHeightForWidth(0), 292.5);
      expect(listingDetailsHeroHeightForWidth(double.infinity), 292.5);
    });
  });
}
