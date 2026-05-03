import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../../domain/entities/uploaded_listing_image.dart';
import '../../domain/usecases/create_listing_v2.dart';
import '../../domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../../domain/usecases/upload_listing_images_sequential.dart';
import '../utils/create_listing_failure_kind_for.dart';
import 'create_listing_state.dart';

/// Create listing via RPC `create_listing_v2` with optional sequential gallery uploads.
///
/// Order:
/// * Validate on the presentation layer (`Form`).
/// * Upload staged photos sequentially; any failure ⇒ [CreateListingFailureKind.upload].
/// * Call [CreateListingV2]; on failure ⇒ best-effort [DeleteUploadedListingImagesBestEffort]
///   for all uploaded objects. Cleanup failures are swallowed in the repo and never replace
///   the surfaced create failure.
class CreateListingCubit extends Cubit<CreateListingState> {
  CreateListingCubit({
    required CreateListingV2 createListingV2,
    required UploadListingImagesSequential uploadListingImagesSequential,
    required DeleteUploadedListingImagesBestEffort
    deleteUploadedListingImagesBestEffort,
  }) : _createListingV2 = createListingV2,
       _uploadSequential = uploadListingImagesSequential,
       _deleteStaging = deleteUploadedListingImagesBestEffort,
       super(const CreateListingState.idle());

  final CreateListingV2 _createListingV2;
  final UploadListingImagesSequential _uploadSequential;
  final DeleteUploadedListingImagesBestEffort _deleteStaging;

  /// [orderedPhotos]: index 0 = cover; max 9 enforced in the UI layer.
  /// [listingInput] must not include staging URLs — gallery is attached here after upload.
  Future<void> submit({
    required NewListingInput listingInput,
    required List<CoverImageUpload> orderedPhotos,
  }) async {
    if (state.status == CreateListingStatus.submitting) return;
    emit(const CreateListingState.submitting());

    List<UploadedListingImage>? stagedGallery;
    if (orderedPhotos.isNotEmpty) {
      final uploads = await _uploadSequential(orderedPhotos);
      switch (uploads) {
        case FailureResult(:final failure):
          emit(
            CreateListingState.failure(
              _failureKindDuringGalleryUpload(failure),
            ),
          );
          return;
        case Success(:final value):
          stagedGallery = value;
          break;
      }
    }

    final inputForRpc = stagingGalleryAttached(listingInput, stagedGallery);

    final result = await _createListingV2(inputForRpc);
    switch (result) {
      case FailureResult(:final failure):
        if (stagedGallery != null && stagedGallery.isNotEmpty) {
          await _deleteStaging(
            images: stagedGallery,
            sellerId: listingInput.sellerId,
          );
        }
        emit(CreateListingState.failure(createListingFailureKindFor(failure)));
      case Success(:final value):
        emit(CreateListingState.success(value));
    }
  }

  /// Gallery upload failures are surfaced under [CreateListingFailureKind.upload]
  /// unless the mapper recognizes auth/network buckets on the wire.
  static CreateListingFailureKind _failureKindDuringGalleryUpload(
    Failure failure,
  ) {
    if (failure is AuthFailure) {
      return CreateListingFailureKind.sessionExpired;
    }
    if (failure is NetworkFailure) {
      return CreateListingFailureKind.serviceUnavailable;
    }
    return CreateListingFailureKind.upload;
  }

  /// Exposed for cubit tests: mirrors production gallery attachment rules.
  static NewListingInput stagingGalleryAttached(
    NewListingInput base,
    List<UploadedListingImage>? gallery,
  ) {
    if (gallery == null || gallery.isEmpty) {
      return base.copyWith(uploadedGallery: null, coverImageUrl: null);
    }
    return base.copyWith(uploadedGallery: gallery, coverImageUrl: null);
  }
}
