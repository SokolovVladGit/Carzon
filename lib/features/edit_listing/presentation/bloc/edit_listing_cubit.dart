import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../create_listing/domain/entities/cover_image_upload.dart';
import '../../../create_listing/domain/repositories/create_listing_repository.dart';
import '../../../create_listing/domain/usecases/upload_listing_cover_image.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/usecases/get_listing_by_id.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/usecases/update_listing_cover_image.dart';
import '../../domain/usecases/update_listing_details.dart';
import 'edit_listing_state.dart';

/// Owns the edit-listing screen:
///   * loads the existing listing to seed the form
///   * stages a pending cover-image change (replace or remove) locally
///   * on save, applies details and cover changes in a deterministic
///     order and surfaces friendly error messages
///
/// Cover change is staged via [stageCoverReplacement] / [stageCoverRemoval]
/// and only committed when [save] is invoked. The cubit never mutates
/// the backend at picker time.
///
/// Save order:
///   1. Update details (`update_listing_details` RPC). If this fails,
///      neither the upload nor the cover RPC is attempted — the cover
///      must not change if the rest of the edit was rejected.
///   2. If a replacement is staged, upload the new image to Storage.
///   3. Call `update_listing_cover_image` with the new URL (or null
///      for removal).
///   4. Best-effort cleanup:
///        - if the cover RPC failed after a successful upload, delete
///          the new orphan object
///        - if the cover RPC succeeded and there was an old cover,
///          delete the old object
///      All cleanup is scoped to the caller's own storage folder via
///      [ListingImageRepository.deleteByPublicUrl] and never fails the
///      user operation.
class EditListingCubit extends Cubit<EditListingState> {
  EditListingCubit({
    required GetListingById getListingById,
    required UpdateListingDetails updateListingDetails,
    required UpdateListingCoverImage updateListingCoverImage,
    required UploadListingCoverImage uploadListingCoverImage,
    required ListingImageRepository listingImageRepository,
  })  : _getListingById = getListingById,
        _updateListingDetails = updateListingDetails,
        _updateListingCoverImage = updateListingCoverImage,
        _uploadListingCoverImage = uploadListingCoverImage,
        _listingImageRepository = listingImageRepository,
        super(const EditListingState.initial());

  final GetListingById _getListingById;
  final UpdateListingDetails _updateListingDetails;
  final UpdateListingCoverImage _updateListingCoverImage;
  final UploadListingCoverImage _uploadListingCoverImage;
  final ListingImageRepository _listingImageRepository;

  Future<void> load(String id) async {
    emit(const EditListingState.loading());
    final result = await _getListingById(id);
    result.fold(
      (_) => emit(const EditListingState.loadFailure()),
      (listing) => emit(EditListingState.ready(listing)),
    );
  }

  /// Stages a locally-picked replacement image. The image is not
  /// uploaded until the user taps Save. Calling this while a removal
  /// is staged clears the removal flag — the two states are mutually
  /// exclusive.
  void stageCoverReplacement(CoverImageUpload upload) {
    if (state.listing == null) return;
    emit(state.copyWith(
      pendingCoverReplacement: upload,
      pendingCoverRemoval: false,
    ));
  }

  /// Marks the existing cover for removal on the next Save. Clears any
  /// staged replacement.
  void stageCoverRemoval() {
    if (state.listing == null) return;
    emit(state.copyWith(
      clearPendingCoverReplacement: true,
      pendingCoverRemoval: true,
    ));
  }

  /// Clears any staged cover change, reverting to "cover unchanged".
  void clearCoverChange() {
    if (state.listing == null) return;
    emit(state.copyWith(
      clearPendingCoverReplacement: true,
      pendingCoverRemoval: false,
    ));
  }

  Future<void> save(EditListingInput input) async {
    final current = state.listing;
    if (current == null) return;
    if (state.status == EditListingStatus.submitting) return;

    final pendingReplacement = state.pendingCoverReplacement;
    final pendingRemoval = state.pendingCoverRemoval;
    final previousCoverUrl = current.coverImageUrl;

    emit(state.copyWith(
      status: EditListingStatus.submitting,
      clearFailureKind: true,
    ));

    // 1. Details first. If this fails we do NOT touch the cover — the
    //    user's intent was to apply a bundle of edits atomically from
    //    their perspective, and a stale cover swap against rejected
    //    details would be worse than doing nothing.
    final detailsResult = await _updateListingDetails(input);
    final detailsFailure = detailsResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (detailsFailure != null) {
      emit(EditListingState.saveFailure(
        current,
        _saveFailureKind(detailsFailure),
      ));
      return;
    }
    final detailsListing = detailsResult.fold<Listing>(
      (_) => current,
      (updated) => updated,
    );

    // 2/3. Cover change, if any.
    if (pendingReplacement != null) {
      final uploadResult =
          await _uploadListingCoverImage(pendingReplacement);
      final uploadFailure = uploadResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (uploadFailure != null) {
        emit(EditListingState.saveFailure(
          detailsListing,
          EditListingFailureKind.uploadFailed,
        ).copyWith(
          pendingCoverReplacement: pendingReplacement,
        ));
        return;
      }
      final uploadedUrl = uploadResult.fold<String>(
        (_) => '',
        (url) => url,
      );

      final coverResult = await _updateListingCoverImage(
        listingId: input.listingId,
        coverImageUrl: uploadedUrl,
      );
      final coverFailure = coverResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (coverFailure != null) {
        // 4a. Best-effort: the DB never took this URL, so the newly
        //     uploaded object is orphaned — try to remove it.
        await _bestEffortDelete(uploadedUrl, current.sellerId);
        emit(EditListingState.saveFailure(
          detailsListing,
          _coverFailureKind(coverFailure),
        ).copyWith(
          pendingCoverReplacement: pendingReplacement,
        ));
        return;
      }
      final updatedListing = coverResult.fold<Listing>(
        (_) => detailsListing,
        (listing) => listing,
      );

      // 4b. Best-effort cleanup of the old cover object once the DB
      //     has accepted the new one. Only the caller's own folder is
      //     touched; external URLs and foreign folders are skipped
      //     inside `deleteByPublicUrl`.
      if (previousCoverUrl != null && previousCoverUrl.isNotEmpty) {
        await _bestEffortDelete(previousCoverUrl, current.sellerId);
      }

      emit(EditListingState.success(updatedListing));
      return;
    }

    if (pendingRemoval) {
      final coverResult = await _updateListingCoverImage(
        listingId: input.listingId,
        coverImageUrl: null,
      );
      final coverFailure = coverResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (coverFailure != null) {
        emit(EditListingState.saveFailure(
          detailsListing,
          _coverFailureKind(coverFailure),
        ).copyWith(pendingCoverRemoval: true));
        return;
      }
      final updatedListing = coverResult.fold<Listing>(
        (_) => detailsListing,
        (listing) => listing,
      );
      if (previousCoverUrl != null && previousCoverUrl.isNotEmpty) {
        await _bestEffortDelete(previousCoverUrl, current.sellerId);
      }
      emit(EditListingState.success(updatedListing));
      return;
    }

    // No cover change requested.
    emit(EditListingState.success(detailsListing));
  }

  Future<void> _bestEffortDelete(String publicUrl, String? sellerId) async {
    if (sellerId == null || sellerId.isEmpty) return;
    // Repository never throws and returns a success Result even when
    // the underlying Storage call fails, but we still guard here so a
    // bug in wiring can never crash the save flow.
    try {
      await _listingImageRepository.deleteByPublicUrl(
        publicUrl: publicUrl,
        sellerId: sellerId,
      );
    } catch (_) {
      // Swallow: orphan cleanup is strictly best-effort.
    }
  }

  /// Maps a [Failure] from the `update_listing_details` RPC into a
  /// localized failure kind. Raw Postgrest wording (including the
  /// `raise exception` texts inside the function body) is never
  /// forwarded to the UI. Matching is substring-based on the
  /// lower-cased message because [Failure] does not expose Postgres
  /// SQLSTATE — adding a richer error-code channel would be a broader
  /// change.
  static EditListingFailureKind _saveFailureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('not authenticated') ||
        raw.contains('not owned') ||
        raw.contains('not allowed') ||
        raw.contains('not found or not owned') ||
        raw.contains('permission denied') ||
        raw.contains('insufficient privilege')) {
      return EditListingFailureKind.notAllowed;
    }
    if (raw.contains('invalid') ||
        raw.contains('is required') ||
        raw.contains('check constraint')) {
      return EditListingFailureKind.invalidDetails;
    }
    return EditListingFailureKind.detailsFailed;
  }

  /// Owner/auth failures from the cover RPC map to the same
  /// "not allowed" kind as details saves for consistency; everything
  /// else collapses to a generic cover-update failure.
  static EditListingFailureKind _coverFailureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('not authenticated') ||
        raw.contains('not owned') ||
        raw.contains('not allowed') ||
        raw.contains('not found or not owned') ||
        raw.contains('permission denied') ||
        raw.contains('insufficient privilege')) {
      return EditListingFailureKind.notAllowed;
    }
    return EditListingFailureKind.coverUpdateFailed;
  }
}
