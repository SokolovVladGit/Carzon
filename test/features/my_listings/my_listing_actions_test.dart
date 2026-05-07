import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/my_listings/presentation/widgets/my_listing_tile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  group('allowedStatusActions', () {
    test('active → sold, hide, archive', () {
      expect(allowedStatusActions(ListingStatus.active), const [
        MyListingAction.markSold,
        MyListingAction.hide,
        MyListingAction.archive,
      ]);
    });

    test('hidden → reactivate, sold, archive', () {
      expect(allowedStatusActions(ListingStatus.hidden), const [
        MyListingAction.reactivate,
        MyListingAction.markSold,
        MyListingAction.archive,
      ]);
    });

    test('sold → reactivate, archive', () {
      expect(allowedStatusActions(ListingStatus.sold), const [
        MyListingAction.reactivate,
        MyListingAction.archive,
      ]);
    });

    test('archived → reactivate only', () {
      expect(allowedStatusActions(ListingStatus.archived), const [
        MyListingAction.reactivate,
      ]);
    });

    test('edit is never included in the status transition set', () {
      for (final s in ListingStatus.values) {
        expect(allowedStatusActions(s), isNot(contains(MyListingAction.edit)));
      }
    });

    test(
      'deletePermanently is never included in the status transition set '
      '(it is a destructive action, handled separately from status updates)',
      () {
        for (final s in ListingStatus.values) {
          expect(
            allowedStatusActions(s),
            isNot(contains(MyListingAction.deletePermanently)),
          );
        }
      },
    );
  });

  group('statusTargetFor', () {
    test('edit returns null because it is navigation, not a status change', () {
      expect(statusTargetFor(MyListingAction.edit), isNull);
    });

    test(
      'deletePermanently returns null because it is not a status change',
      () {
        expect(statusTargetFor(MyListingAction.deletePermanently), isNull);
      },
    );

    test('maps status actions to their target ListingStatus', () {
      expect(statusTargetFor(MyListingAction.reactivate), ListingStatus.active);
      expect(statusTargetFor(MyListingAction.markSold), ListingStatus.sold);
      expect(statusTargetFor(MyListingAction.hide), ListingStatus.hidden);
      expect(statusTargetFor(MyListingAction.archive), ListingStatus.archived);
    });
  });

  group('statusActionLabel', () {
    test('labels cover every MyListingAction value', () {
      for (final a in MyListingAction.values) {
        expect(statusActionLabel(l10n, a), isNotEmpty);
      }
    });

    test('deletePermanently renders with the localized "Delete permanently" '
        'label', () {
      expect(
        statusActionLabel(l10n, MyListingAction.deletePermanently),
        l10n.actionDeletePermanently,
      );
    });
  });
}
