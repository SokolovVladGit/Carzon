import 'package:carzon/features/listings/domain/listing_submit_title.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  test('auto title without variant stays make model year', () {
    expect(
      resolvedListingTitleForSubmit(
        trimmedUserTitle: '',
        make: 'BMW',
        model: '3 Series',
        year: 2022,
        l10n: l10n,
      ),
      'BMW 3 Series, 2022',
    );
  });

  test('auto title includes variant once', () {
    expect(
      resolvedListingTitleForSubmit(
        trimmedUserTitle: '',
        make: 'BMW',
        model: '3 Series',
        year: 2022,
        l10n: l10n,
        variant: 'M340i',
      ),
      'BMW 3 Series M340i, 2022',
    );
    expect(
      resolvedListingTitleForSubmit(
        trimmedUserTitle: '',
        make: 'Mercedes-Benz',
        model: 'C-Class',
        year: 2021,
        l10n: l10n,
        variant: 'C 63 AMG',
      ),
      'Mercedes-Benz C-Class C 63 AMG, 2021',
    );
  });

  test('blank variant does not add extra spaces', () {
    expect(
      resolvedListingTitleForSubmit(
        trimmedUserTitle: '',
        make: 'Honda',
        model: 'CR-V',
        year: 2025,
        l10n: l10n,
        variant: '   ',
      ),
      'Honda CR-V, 2025',
    );
  });

  test('custom title is unchanged even when variant is set', () {
    expect(
      resolvedListingTitleForSubmit(
        trimmedUserTitle: 'My special car',
        make: 'BMW',
        model: '3 Series',
        year: 2022,
        l10n: l10n,
        variant: 'M340i',
      ),
      'My special car',
    );
  });
}
