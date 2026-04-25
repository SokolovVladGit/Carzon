import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../../domain/usecases/create_listing.dart';
import '../../domain/usecases/upload_listing_cover_image.dart';
import 'create_listing_state.dart';

/// Single submit action — Cubit is sufficient (no event-driven flow).
///
/// MVP flow with optional cover image:
///   1. If a cover image is provided, upload it first and take the
///      resulting public URL.
///   2. Insert the listing row, passing `coverImageUrl` only when the
///      upload succeeded (or was skipped entirely).
///   3. Any upload failure short-circuits the whole submit — no listing
///      row is created, and the user sees the failure message.
class CreateListingCubit extends Cubit<CreateListingState> {
  CreateListingCubit({
    required CreateListing createListing,
    required UploadListingCoverImage uploadListingCoverImage,
  })  : _createListing = createListing,
        _uploadCover = uploadListingCoverImage,
        super(const CreateListingState.idle());

  final CreateListing _createListing;
  final UploadListingCoverImage _uploadCover;

  Future<void> submit(
    NewListingInput input, {
    CoverImageUpload? coverImage,
  }) async {
    if (state.status == CreateListingStatus.submitting) return;
    emit(const CreateListingState.submitting());

    var effectiveInput = input;

    if (coverImage != null) {
      final uploadResult = await _uploadCover(coverImage);
      final uploaded = uploadResult.fold<({bool ok, String? url})>(
        (_) => (ok: false, url: null),
        (url) => (ok: true, url: url),
      );
      if (!uploaded.ok) {
        emit(const CreateListingState.failure(
          CreateListingFailureKind.upload,
        ));
        return;
      }
      if (uploaded.url != null && uploaded.url!.isNotEmpty) {
        effectiveInput = effectiveInput.copyWith(coverImageUrl: uploaded.url);
      }
    }

    final result = await _createListing(effectiveInput);
    result.fold(
      (_) => emit(
        const CreateListingState.failure(CreateListingFailureKind.create),
      ),
      (listing) => emit(CreateListingState.success(listing)),
    );
  }
}
