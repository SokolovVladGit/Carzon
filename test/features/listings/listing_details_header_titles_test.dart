import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_details_header_titles.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing({
  required String title,
  required String make,
  required String model,
  int year = 2020,
}) => Listing(
  id: 'x',
  title: title,
  make: make,
  model: model,
  year: year,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: '',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('listingDetailsVehicleIdentityLine', () {
    test('strips repeated leading make token from model', () {
      expect(
        listingDetailsVehicleIdentityLine('Toyota', 'Toyota RAV4 Hybrid'),
        'Toyota RAV4 Hybrid',
      );
    });

    test('joins make and model when model does not repeat make', () {
      expect(
        listingDetailsVehicleIdentityLine('Toyota', 'RAV4 Hybrid'),
        'Toyota RAV4 Hybrid',
      );
    });

    test('strips case-insensitive leading make token', () {
      expect(
        listingDetailsVehicleIdentityLine('BMW', 'BMW M340i'),
        'BMW M340i',
      );
      expect(
        listingDetailsVehicleIdentityLine('MINI', 'Mini Cooper'),
        'MINI Cooper',
      );
    });

    test('does not strip hyphen-glued longer make in model', () {
      expect(
        listingDetailsVehicleIdentityLine('Mercedes-Benz', 'C-Class'),
        'Mercedes-Benz C-Class',
      );
      expect(
        listingDetailsVehicleIdentityLine('Mercedes', 'Mercedes-Benz C-Class'),
        'Mercedes Mercedes-Benz C-Class',
      );
    });

    test('does not strip when make is glued to model without space', () {
      expect(
        listingDetailsVehicleIdentityLine('BMW', 'BMWX5'),
        'BMW BMWX5',
      );
    });

    test('collapses whitespace and handles empty sides', () {
      expect(
        listingDetailsVehicleIdentityLine('  Toyota  ', '  RAV4   Hybrid  '),
        'Toyota RAV4 Hybrid',
      );
      expect(listingDetailsVehicleIdentityLine('', 'RAV4'), 'RAV4');
      expect(listingDetailsVehicleIdentityLine('Toyota', ''), 'Toyota');
      expect(listingDetailsVehicleIdentityLine('', ''), '');
    });

    test('returns make only when model equals make', () {
      expect(listingDetailsVehicleIdentityLine('Toyota', 'Toyota'), 'Toyota');
      expect(listingDetailsVehicleIdentityLine('Toyota', 'toyota'), 'Toyota');
    });
  });

  group('listingDetailsDisplayPrimaryTitle', () {
    test('drops trailing comma + listing year when title is identity-only', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'Mercedes-Benz AMG C-Class Coupe, 2023',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        'Mercedes-Benz AMG C-Class Coupe',
      );
    });

    test('drops middle dot separator before listing year', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'Mercedes-Benz AMG C-Class Coupe · 2023',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        'Mercedes-Benz AMG C-Class Coupe',
      );
    });

    test('drops em dash separator before listing year', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'Mercedes-Benz AMG C-Class Coupe — 2023',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        'Mercedes-Benz AMG C-Class Coupe',
      );
    });

    test('drops space before listing year', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'Mercedes-Benz AMG C-Class Coupe 2023',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        'Mercedes-Benz AMG C-Class Coupe',
      );
    });

    test('keeps trailing year inside custom prose', () {
      final t =
          '''В идеальном состоянии, 2023'''; // intentional comma before year is prose
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: t,
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        t.trim(),
      );
    });

    test('does not strip year glued to wording after model', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'AMG C-Class Coupe 2023 срочно',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        ),
        'AMG C-Class Coupe 2023 срочно',
      );
    });

    test('does not strip year welded to Coupe without separator', () {
      expect(
        listingDetailsDisplayPrimaryTitle(
          _listing(
            title: 'Merc Test Coupe2023',
            make: 'Merc Test',
            model: 'Coupe',
            year: 2023,
          ),
        ),
        'Merc Test Coupe2023',
      );
    });
  });

  group('ListingDetailsHeaderDisplay.fromListing', () {
    test('primary line is seller title without redundant year stripping', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: 'white beast', make: 'Audi', model: 'A5'),
      );
      expect(d.primaryLine, 'white beast');
      expect(d.tagline, 'Audi A5 · 2020');
    });

    test(
      'no subtitle when title normalizes equal to vehicle identity line',
      () {
        final d = ListingDetailsHeaderDisplay.fromListing(
          _listing(title: '  audi   A5 ', make: 'Audi', model: 'A5'),
        );
        expect(d.primaryLine, 'audi A5');
        expect(d.tagline, isNull);
      },
    );

    test(
      'identity title + trailing year collapses headline to identity; chip covers year',
      () {
        final d = ListingDetailsHeaderDisplay.fromListing(
          _listing(
            title: 'Mercedes-Benz AMG C-Class Coupe, 2023',
            make: 'Mercedes-Benz',
            model: 'AMG C-Class Coupe',
            year: 2023,
          ),
        );
        expect(d.primaryLine, 'Mercedes-Benz AMG C-Class Coupe');
        expect(d.tagline, isNull);
      },
    );

    test('subtitle when custom title lacks structured identity', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(
          title: 'В идеальном состоянии',
          make: 'Mercedes-Benz',
          model: 'AMG C-Class Coupe',
          year: 2023,
        ),
      );
      expect(d.primaryLine, 'В идеальном состоянии');
      expect(d.tagline, 'Mercedes-Benz AMG C-Class Coupe · 2023');
    });

    test('hyphen punctuation does not force redundant subtitle', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(
          title: 'Mercedes Benz AMG C-Class Coupe',
          make: 'Mercedes-Benz',
          model: 'AMG C-Class Coupe',
          year: 2024,
        ),
      );
      expect(d.tagline, isNull);
    });

    test(
      'missing make/model: primary is title only; no structured subtitle',
      () {
        final d = ListingDetailsHeaderDisplay.fromListing(
          _listing(title: 'mystery car', make: '', model: ''),
        );
        expect(d.primaryLine, 'mystery car');
        expect(d.tagline, isNull);
      },
    );

    test('missing model: subtitle uses make-only identity', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: 'seller note', make: 'BMW', model: '', year: 2019),
      );
      expect(d.primaryLine, 'seller note');
      expect(d.tagline, 'BMW · 2019');
    });

    test('empty title: primary falls back to vehicle line; no tagline', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: '   ', make: 'Audi', model: 'A5'),
      );
      expect(d.primaryLine, 'Audi A5');
      expect(d.tagline, isNull);
    });

    test('custom title with trailing year still shows structured subtitle', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(
          title: 'В идеальном состоянии, 2023',
          make: 'Mercedes-Benz',
          model: 'AMG C-Class Coupe',
          year: 2023,
        ),
      );
      expect(d.primaryLine, 'В идеальном состоянии, 2023');
      expect(d.tagline, 'Mercedes-Benz AMG C-Class Coupe · 2023');
    });

    test('tagline dedupes make repeated in model field', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(
          title: 'Low mileage hybrid',
          make: 'Toyota',
          model: 'Toyota RAV4 Hybrid',
          year: 2018,
        ),
      );
      expect(d.primaryLine, 'Low mileage hybrid');
      expect(d.tagline, 'Toyota RAV4 Hybrid · 2018');
    });

    test('empty title uses deduped vehicle line as primary', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(
          title: '',
          make: 'Toyota',
          model: 'Toyota RAV4 Hybrid',
          year: 2018,
        ),
      );
      expect(d.primaryLine, 'Toyota RAV4 Hybrid');
      expect(d.tagline, isNull);
    });
  });

  group('listingDetailsTitleAlreadyEmbedsStructuredIdentity', () {
    test('true when normalized title embeds normalized identity substring', () {
      expect(
        listingDetailsTitleAlreadyEmbedsStructuredIdentity(
          rawTitle: 'Продаю Mercedes-Benz AMG C-Class Coupe срочно',
          vehicleLine: 'Mercedes-Benz AMG C-Class Coupe',
          year: 2023,
        ),
        isTrue,
      );
    });

    test('false for unrelated custom headline', () {
      expect(
        listingDetailsTitleAlreadyEmbedsStructuredIdentity(
          rawTitle: 'Честная цена без навесов',
          vehicleLine: 'Audi Q5',
          year: 2021,
        ),
        isFalse,
      );
    });
  });
}
