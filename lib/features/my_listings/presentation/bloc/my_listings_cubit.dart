import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/repositories/listings_repository.dart';
import '../../../listings/domain/usecases/delete_listing.dart';
import '../../../listings/domain/usecases/get_listings.dart';
import '../../../listings/domain/usecases/set_listing_status.dart';
import 'my_listings_state.dart';

/// Reuses the listings use cases with a sellerId-scoped query for reads
/// and the narrow `set_listing_status` RPC for owner status changes.
class MyListingsCubit extends Cubit<MyListingsState> {
  MyListingsCubit({
    required GetListings getListings,
    required SetListingStatus setListingStatus,
    required DeleteListing deleteListing,
  })  : _getListings = getListings,
        _setListingStatus = setListingStatus,
        _deleteListing = deleteListing,
        super(const MyListingsState.initial());

  final GetListings _getListings;
  final SetListingStatus _setListingStatus;
  final DeleteListing _deleteListing;

  static const int _pageSize = 50;

  int _errorSeq = 0;

  Future<void> load(String sellerId) async {
    emit(const MyListingsState.loading());
    final result = await _getListings(
      ListingsQuery(sellerId: sellerId, page: 0, pageSize: _pageSize),
    );
    result.fold(
      (_) => emit(const MyListingsState.failure()),
      (items) => emit(MyListingsState.success(items)),
    );
  }

  /// Owner status change. Swallows duplicate taps while an update for
  /// the same listing is already in flight. On success the affected
  /// item is replaced in-place so the rest of the list does not flicker.
  /// On failure a one-shot [ActionError] is emitted for the page to
  /// display via snackbar.
  Future<void> updateStatus(String listingId, ListingStatus newStatus) async {
    if (state.pendingStatusIds.contains(listingId)) return;
    final existing =
        state.items.any((l) => l.id == listingId && l.status == newStatus);
    if (existing) return;

    emit(state.copyWith(
      pendingStatusIds: {...state.pendingStatusIds, listingId},
    ));

    final result = await _setListingStatus(listingId, newStatus);
    final nextPending = {...state.pendingStatusIds}..remove(listingId);

    result.fold(
      (failure) {
        _errorSeq += 1;
        emit(state.copyWith(
          pendingStatusIds: nextPending,
          lastActionError: ActionError(
            id: _errorSeq,
            kind: _statusFailureKind(failure),
          ),
        ));
      },
      (updated) {
        final updatedItems = [
          for (final item in state.items)
            if (item.id == listingId) updated else item,
        ];
        emit(state.copyWith(
          items: updatedItems,
          pendingStatusIds: nextPending,
        ));
      },
    );
  }

  /// Owner-only permanent delete. Wraps the `delete_listing` RPC. The
  /// same pending/duplicate-tap semantics as [updateStatus] apply: a
  /// second call for a listing that already has a delete in flight is
  /// a no-op, and success removes the listing from [state.items] while
  /// failure surfaces a one-shot [ActionError] for the page snackbar.
  Future<void> deleteListing(String listingId) async {
    if (state.pendingDeleteIds.contains(listingId)) return;
    if (!state.items.any((l) => l.id == listingId)) return;

    emit(state.copyWith(
      pendingDeleteIds: {...state.pendingDeleteIds, listingId},
    ));

    final result = await _deleteListing(listingId);
    final nextPending = {...state.pendingDeleteIds}..remove(listingId);

    result.fold(
      (failure) {
        _errorSeq += 1;
        emit(state.copyWith(
          pendingDeleteIds: nextPending,
          lastActionError: ActionError(
            id: _errorSeq,
            kind: _deleteFailureKind(failure),
          ),
        ));
      },
      (_) {
        final updatedItems = [
          for (final item in state.items)
            if (item.id != listingId) item,
        ];
        emit(state.copyWith(
          items: updatedItems,
          pendingDeleteIds: nextPending,
        ));
      },
    );
  }

  /// Called by the page after it has shown the snackbar for the current
  /// [ActionError]. Keeps the one-shot semantics clean.
  void acknowledgeActionError() {
    if (state.lastActionError == null) return;
    emit(state.copyWith(clearLastActionError: true));
  }

  /// Maps a [Failure] from the owner status update path into a
  /// categorized [MyListingActionFailureKind]. The raw Postgrest
  /// message is not shown to users; the page resolves the kind to a
  /// localized snackbar string. Matching is done by substring on the
  /// lower-cased failure message because [Failure] does not expose the
  /// underlying Postgres SQLSTATE — surfacing errcodes would require a
  /// broader error-model change and is out of scope here.
  static MyListingActionFailureKind _statusFailureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('not authenticated') ||
        raw.contains('not owned') ||
        raw.contains('not allowed') ||
        raw.contains('permission denied') ||
        raw.contains('insufficient privilege')) {
      return MyListingActionFailureKind.statusNotAllowed;
    }
    if (raw.contains('invalid listing status')) {
      return MyListingActionFailureKind.statusInvalid;
    }
    return MyListingActionFailureKind.statusGeneric;
  }

  /// Delete-specific error mapping. Mirrors [_statusFailureKind] for the
  /// status path: ownership / auth problems become
  /// [MyListingActionFailureKind.deleteNotAllowed] and "not found" goes
  /// to [MyListingActionFailureKind.deleteNotFound]; everything else is
  /// [MyListingActionFailureKind.deleteGeneric].
  static MyListingActionFailureKind _deleteFailureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('not authenticated') ||
        raw.contains('not owned') ||
        raw.contains('not allowed') ||
        raw.contains('permission denied') ||
        raw.contains('insufficient privilege')) {
      return MyListingActionFailureKind.deleteNotAllowed;
    }
    if (raw.contains('not found')) {
      return MyListingActionFailureKind.deleteNotFound;
    }
    return MyListingActionFailureKind.deleteGeneric;
  }
}
