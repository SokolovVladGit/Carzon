import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../create_listing/domain/constants/listing_gallery_limits.dart';
import '../../../create_listing/domain/entities/uploaded_listing_image.dart';
import '../../../create_listing/domain/repositories/create_listing_repository.dart';
import '../../../create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../../../create_listing/domain/usecases/upload_listing_images_sequential.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../../../listings/domain/usecases/get_listing_by_id.dart';
import '../../../listings/domain/usecases/get_listing_images.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';
import '../../domain/usecases/get_owner_listing_vin_for_edit.dart';
import '../../domain/usecases/get_owner_listing_vin_report_status_for_edit.dart';
import '../../domain/usecases/get_owner_listing_vin_source_results_for_edit.dart';
import '../../domain/usecases/replace_listing_images.dart';
import '../../domain/usecases/update_listing_details_v2.dart';
import '../models/edit_listing_gallery_slot.dart';
import '../utils/edit_listing_gallery_initializer.dart';
import 'edit_listing_state.dart';

/// Owns the edit-listing screen (Phase 4C):
/// * loads listing + prefetches ordered `listing_images` (trusted replace gate)
/// * saves details through `update_listing_details_v2`
/// * optionally uploads new blobs sequentially and calls `replace_listing_images`
class EditListingCubit extends Cubit<EditListingState> {
  EditListingCubit({
    required GetListingById getListingById,
    required GetListingImages getListingImages,
    required GetOwnerListingVinForEdit getOwnerListingVinForEdit,
    required GetOwnerListingVinReportStatusForEdit
    getOwnerListingVinReportStatusForEdit,
    required GetOwnerListingVinSourceResultsForEdit
    getOwnerListingVinSourceResultsForEdit,
    required UpdateListingDetailsV2 updateListingDetailsV2,
    required ReplaceListingImages replaceListingImages,
    required UploadListingImagesSequential uploadListingImagesSequential,
    required DeleteUploadedListingImagesBestEffort
    deleteUploadedListingImagesBestEffort,
    required ListingImageRepository listingImageRepository,
  }) : _getListingById = getListingById,
       _getListingImages = getListingImages,
       _getOwnerListingVinForEdit = getOwnerListingVinForEdit,
       _getOwnerListingVinReportStatusForEdit =
           getOwnerListingVinReportStatusForEdit,
       _getOwnerListingVinSourceResultsForEdit =
           getOwnerListingVinSourceResultsForEdit,
       _updateListingDetailsV2 = updateListingDetailsV2,
       _replaceListingImages = replaceListingImages,
       _uploadSequential = uploadListingImagesSequential,
       _deleteStagingUseCase = deleteUploadedListingImagesBestEffort,
       _listingImageRepository = listingImageRepository,
       super(const EditListingState.initial());

  final GetListingById _getListingById;
  final GetListingImages _getListingImages;
  final GetOwnerListingVinForEdit _getOwnerListingVinForEdit;
  final GetOwnerListingVinReportStatusForEdit
  _getOwnerListingVinReportStatusForEdit;
  final GetOwnerListingVinSourceResultsForEdit
  _getOwnerListingVinSourceResultsForEdit;
  final UpdateListingDetailsV2 _updateListingDetailsV2;
  final ReplaceListingImages _replaceListingImages;
  final UploadListingImagesSequential _uploadSequential;
  final DeleteUploadedListingImagesBestEffort _deleteStagingUseCase;
  final ListingImageRepository _listingImageRepository;

  Future<void> load(String id) async {
    emit(const EditListingState.loading());

    switch (await _getListingById(id)) {
      case FailureResult():
        emit(EditListingState.loadFailure());
      case Success(:final value):
        final listing = value;

        var galleryLoadSucceeded = false;
        var galleryImages = const <ListingImage>[];
        switch (await _getListingImages(id)) {
          case FailureResult():
            galleryLoadSucceeded = false;
          case Success(:final value):
            galleryLoadSucceeded = true;
            galleryImages = value;
        }

        final initialSlots = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: galleryImages,
          galleryLoadSucceeded: galleryLoadSucceeded,
        );

        final vinFuture = _getOwnerListingVinForEdit(id);
        final reportFuture = _getOwnerListingVinReportStatusForEdit(id);
        final sourceFuture = _getOwnerListingVinSourceResultsForEdit(id);

        String? ownerVinNorm;
        var ownerVinFail = false;
        switch (await vinFuture) {
          case Success(:final value):
            ownerVinNorm = value.normalizedVin;
            ownerVinFail = value.fetchFailed;
          case FailureResult():
            ownerVinFail = true;
        }

        final reportOut = await reportFuture;
        final sourceOut = await sourceFuture;

        OwnerListingVinReportStatus? reportStatus;
        var reportFail = false;
        switch (reportOut) {
          case Success(:final value):
            reportFail = value.fetchFailed;
            reportStatus = value.status;
          case FailureResult():
            reportFail = true;
        }

        var sourceFail = false;
        var sourceRows = const <OwnerListingVinSourceResult>[];
        switch (sourceOut) {
          case Success(:final value):
            sourceFail = value.fetchFailed;
            sourceRows = value.results;
          case FailureResult():
            sourceFail = true;
        }

        emit(
          EditListingState.ready(
            listing,
            listingGalleryImages: galleryImages,
            galleryLoadSucceeded: galleryLoadSucceeded,
            initialGallerySlots: initialSlots,
            ownerVinNormalizedForEdit: ownerVinNorm,
            ownerVinLookupFailed: ownerVinFail,
            ownerVinReportStatus: reportStatus,
            ownerVinReportLookupFailed: reportFail,
            ownerVinSourceResults: sourceRows,
            ownerVinSourceResultsLookupFailed: sourceFail,
          ),
        );
    }
  }

  Future<void> save({
    required EditListingInput input,
    required List<EditListingGallerySlot> galleryDraft,
  }) async {
    final mountedListing = state.listing;
    if (mountedListing == null) return;
    if (state.status == EditListingStatus.submitting) return;

    final ownerVinNormalizedForEdit = state.ownerVinNormalizedForEdit;
    final ownerVinLookupFailed = state.ownerVinLookupFailed;
    final ownerVinReportStatus = state.ownerVinReportStatus;
    final ownerVinReportLookupFailed = state.ownerVinReportLookupFailed;
    final ownerVinSourceResults = state.ownerVinSourceResults;
    final ownerVinSourceResultsLookupFailed =
        state.ownerVinSourceResultsLookupFailed;

    if (galleryDraft.length > kMaxListingPhotos) {
      emit(
        EditListingState.saveFailure(
          mountedListing,
          EditListingFailureKind.invalidDetails,
          listingGalleryImages: state.listingGalleryImages,
          galleryLoadSucceeded: state.galleryLoadSucceeded,
          initialGallerySlots: state.initialGallerySlots,
          ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
          ownerVinLookupFailed: ownerVinLookupFailed,
          ownerVinReportStatus: ownerVinReportStatus,
          ownerVinReportLookupFailed: ownerVinReportLookupFailed,
          ownerVinSourceResults: ownerVinSourceResults,
          ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
        ),
      );
      return;
    }

    final baselineSlots = state.initialGallerySlots;
    final galleryDraftChanged = !listingEditGallerySlotsDeepEqual(
      baselineSlots,
      galleryDraft,
    );
    final mayReplaceGallery = state.galleryLoadSucceeded && galleryDraftChanged;

    final localsToUpload = galleryDraft
        .whereType<EditListingGalleryLocalSlot>()
        .map((s) => s.upload)
        .toList(growable: false);

    emit(
      EditListingState.submitting(
        mountedListing,
        listingGalleryImages: state.listingGalleryImages,
        galleryLoadSucceeded: state.galleryLoadSucceeded,
        initialGallerySlots: state.initialGallerySlots,
        ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
        ownerVinLookupFailed: ownerVinLookupFailed,
        ownerVinReportStatus: ownerVinReportStatus,
        ownerVinReportLookupFailed: ownerVinReportLookupFailed,
        ownerVinSourceResults: ownerVinSourceResults,
        ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
      ).copyWith(clearFailureKind: true),
    );

    List<UploadedListingImage>? newlyUploaded;
    if (localsToUpload.isNotEmpty) {
      final uploads = await _uploadSequential(localsToUpload);
      final uploadFailure = uploads.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (uploadFailure != null) {
        emit(
          EditListingState.saveFailure(
            mountedListing,
            _uploadFailureKind(uploadFailure),
            listingGalleryImages: state.listingGalleryImages,
            galleryLoadSucceeded: state.galleryLoadSucceeded,
            initialGallerySlots: state.initialGallerySlots,
            ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
            ownerVinLookupFailed: ownerVinLookupFailed,
            ownerVinReportStatus: ownerVinReportStatus,
            ownerVinReportLookupFailed: ownerVinReportLookupFailed,
            ownerVinSourceResults: ownerVinSourceResults,
            ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
          ),
        );
        return;
      }
      newlyUploaded = uploads.fold<List<UploadedListingImage>>(
        (_) => <UploadedListingImage>[],
        (v) => v,
      );
    }

    final detailsResult = await _updateListingDetailsV2(input);
    switch (detailsResult) {
      case FailureResult(:final failure):
        if (newlyUploaded != null && newlyUploaded.isNotEmpty) {
          await _deleteStaging(newlyUploaded, mountedListing.sellerId);
        }
        emit(
          EditListingState.saveFailure(
            mountedListing,
            _saveFailureKind(failure),
            listingGalleryImages: state.listingGalleryImages,
            galleryLoadSucceeded: state.galleryLoadSucceeded,
            initialGallerySlots: state.initialGallerySlots,
            ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
            ownerVinLookupFailed: ownerVinLookupFailed,
            ownerVinReportStatus: ownerVinReportStatus,
            ownerVinReportLookupFailed: ownerVinReportLookupFailed,
            ownerVinSourceResults: ownerVinSourceResults,
            ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
          ),
        );
      case Success(:final value):
        final listingAfterDetails = value;

        if (!mayReplaceGallery) {
          emit(
            EditListingState.success(
              listingAfterDetails,
              listingGalleryImages: state.listingGalleryImages,
              galleryLoadSucceeded: state.galleryLoadSucceeded,
              initialGallerySlots: state.initialGallerySlots,
              ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
              ownerVinLookupFailed: ownerVinLookupFailed,
              ownerVinReportStatus: ownerVinReportStatus,
              ownerVinReportLookupFailed: ownerVinReportLookupFailed,
              ownerVinSourceResults: ownerVinSourceResults,
              ownerVinSourceResultsLookupFailed:
                  ownerVinSourceResultsLookupFailed,
            ),
          );
          return;
        }

        final replacePayload = buildReplaceListingGalleryPayload(
          galleryDraft,
          newlyUploaded,
        );
        final replaceUrlList = replacePayload.urls;
        final replacePathList = replacePayload.paths;

        final replaceResult = await _replaceListingImages(
          listingId: input.listingId,
          imagePublicUrls: replaceUrlList,
          storagePaths: replacePathList,
        );

        final replaceFailure = replaceResult.fold<Failure?>(
          (failure) => failure,
          (_) => null,
        );

        if (replaceFailure != null) {
          if (newlyUploaded != null && newlyUploaded.isNotEmpty) {
            await _deleteStaging(newlyUploaded, mountedListing.sellerId);
          }
          emit(
            EditListingState.saveFailure(
              listingAfterDetails,
              _galleryReplaceFailureKind(replaceFailure),
              listingGalleryImages: state.listingGalleryImages,
              galleryLoadSucceeded: state.galleryLoadSucceeded,
              initialGallerySlots: state.initialGallerySlots,
              ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
              ownerVinLookupFailed: ownerVinLookupFailed,
              ownerVinReportStatus: ownerVinReportStatus,
              ownerVinReportLookupFailed: ownerVinReportLookupFailed,
              ownerVinSourceResults: ownerVinSourceResults,
              ownerVinSourceResultsLookupFailed:
                  ownerVinSourceResultsLookupFailed,
            ),
          );
          return;
        }

        final finalListing = replaceResult.fold<Listing>(
          (_) => listingAfterDetails,
          (updated) => updated,
        );

        final sid = mountedListing.sellerId;
        if (sid != null && sid.isNotEmpty) {
          final droppedUrls = remoteUrlsDroppedSinceBaseline(
            baseline: baselineSlots,
            finalDraft: galleryDraft,
          );
          for (final url in droppedUrls) {
            await _bestEffortDelete(url, sid);
          }
        }

        emit(
          EditListingState.success(
            finalListing,
            listingGalleryImages: state.listingGalleryImages,
            galleryLoadSucceeded: state.galleryLoadSucceeded,
            initialGallerySlots: state.initialGallerySlots,
            ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
            ownerVinLookupFailed: ownerVinLookupFailed,
            ownerVinReportStatus: ownerVinReportStatus,
            ownerVinReportLookupFailed: ownerVinReportLookupFailed,
            ownerVinSourceResults: ownerVinSourceResults,
            ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
          ),
        );
    }
  }

  /// Internal for tests — pairs each local draft slot with the next sequential upload.
  static ({List<String> urls, List<String?> paths})
  buildReplaceListingGalleryPayload(
    List<EditListingGallerySlot> slots,
    List<UploadedListingImage>? newlyUploaded,
  ) {
    final urls = <String>[];
    final paths = <String?>[];

    final localsCount = slots.whereType<EditListingGalleryLocalSlot>().length;
    if (localsCount != ((newlyUploaded == null) ? 0 : newlyUploaded.length)) {
      throw StateError(
        'Local slots ($localsCount) and uploaded blobs '
        '(${newlyUploaded?.length ?? 0}) are out of sync.',
      );
    }

    var localCursor = 0;
    final staged = newlyUploaded ?? const <UploadedListingImage>[];

    for (final slot in slots) {
      if (slot is EditListingGalleryRemoteSlot) {
        urls.add(slot.publicUrl);
        paths.add(slot.effectiveStoragePath);
      } else if (slot is EditListingGalleryLocalSlot) {
        final blob = staged[localCursor++];
        urls.add(blob.publicUrl);
        paths.add(blob.storagePath);
      }
    }
    return (urls: urls, paths: paths);
  }

  Future<void> _deleteStaging(
    List<UploadedListingImage>? images,
    String? sellerId,
  ) async {
    if (images == null || images.isEmpty) return;
    if (sellerId == null || sellerId.isEmpty) return;
    await _deleteStagingUseCase(images: images, sellerId: sellerId);
  }

  Future<void> _bestEffortDelete(String publicUrl, String? sellerId) async {
    if (sellerId == null || sellerId.isEmpty) return;
    try {
      await _listingImageRepository.deleteByPublicUrl(
        publicUrl: publicUrl,
        sellerId: sellerId,
      );
    } catch (_) {}
  }

  static EditListingFailureKind _uploadFailureKind(Failure failure) {
    if (failure is AuthFailure) {
      return EditListingFailureKind.notAllowed;
    }
    return EditListingFailureKind.uploadFailed;
  }

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

  static EditListingFailureKind _galleryReplaceFailureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('not authenticated') ||
        raw.contains('not owned') ||
        raw.contains('not allowed') ||
        raw.contains('not found or not owned') ||
        raw.contains('permission denied') ||
        raw.contains('insufficient privilege')) {
      return EditListingFailureKind.notAllowed;
    }
    return EditListingFailureKind.galleryReplaceFailed;
  }
}
