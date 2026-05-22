import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/usecases/get_listing_by_id.dart';
import '../../../listings/domain/usecases/get_listing_images.dart';
import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_resolved_slot.dart';
import 'compare_page_state.dart';

/// Resolves full [Listing] data for vehicles on the compare screen.
class ComparePageCubit extends Cubit<ComparePageState> {
  ComparePageCubit({
    required GetListingById getListingById,
    required GetListingImages getListingImages,
  }) : _getListingById = getListingById,
       _getListingImages = getListingImages,
       super(const ComparePageState.idle());

  final GetListingById _getListingById;
  final GetListingImages _getListingImages;

  int _resolveGeneration = 0;

  /// Fetches listings for [items] in parallel (max 3).
  ///
  /// Overlapping calls invalidate older work via [_resolveGeneration] so stale
  /// results never emit after remove/clear or a newer resolve.
  Future<void> resolve(List<CompareItem> items) async {
    if (items.length < 2) {
      _resolveGeneration++;
      if (!isClosed) {
        emit(const ComparePageState.idle());
      }
      return;
    }

    final generation = ++_resolveGeneration;
    if (!isClosed) {
      emit(ComparePageState.resolving(items));
    }

    final slots = await Future.wait(items.map(_resolveSlot));
    if (isClosed || generation != _resolveGeneration) return;

    emit(ComparePageState(slots: slots, isResolving: false));
  }

  Future<CompareResolvedSlot> _resolveSlot(CompareItem item) async {
    final listingRes = await _getListingById(item.listingId);
    switch (listingRes) {
      case FailureResult():
        return CompareResolvedSlot(
          item: item,
          phase: CompareSlotPhase.unavailable,
        );
      case Success(:final value):
        final photoCount = await _loadPhotoCount(value.id);
        final phase = value.status == ListingStatus.active
            ? CompareSlotPhase.ready
            : CompareSlotPhase.inactive;
        return CompareResolvedSlot(
          item: item,
          phase: phase,
          listing: value,
          photoCount: photoCount,
        );
    }
  }

  Future<int?> _loadPhotoCount(String listingId) async {
    final imagesRes = await _getListingImages(listingId);
    return switch (imagesRes) {
      Success(:final value) => value.isEmpty ? null : value.length,
      FailureResult() => null,
    };
  }
}
