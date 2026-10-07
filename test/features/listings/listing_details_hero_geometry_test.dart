import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingDetailsHeroHeightForWidth', () {
    test('uses 16:9 height on representative phone widths', () {
      expect(listingDetailsHeroHeightForWidth(375), closeTo(210.9375, 1e-9));
      expect(listingDetailsHeroHeightForWidth(390), closeTo(219.375, 1e-9));
      expect(listingDetailsHeroHeightForWidth(430), closeTo(241.875, 1e-9));
    });

    test('falls back to the 390 px 16:9 height when width is not usable', () {
      expect(listingDetailsHeroHeightForWidth(0), closeTo(219.375, 1e-9));
      expect(
        listingDetailsHeroHeightForWidth(double.infinity),
        closeTo(219.375, 1e-9),
      );
    });
  });
}
