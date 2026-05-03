import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/cover_image_upload.dart';
import '../entities/new_listing_input.dart';
import '../entities/uploaded_listing_image.dart';

abstract interface class CreateListingRepository {
  Future<Result<Listing>> create(NewListingInput input);
  Future<Result<Listing>> createV2(NewListingInput input);
}

/// Narrow capability for managing a listing's cover image in storage.
/// Kept in a separate repository so the domain does not grow a
/// mixed-responsibility `CreateListingRepository`. Reused by the
/// edit-listing flow for replacement/removal cleanup.
abstract interface class ListingImageRepository {
  /// Uploads [upload.bytes] to the `listing-images` bucket under
  /// `listings/<sellerId>/...` and returns the resulting public URL.
  Future<Result<String>> uploadCover(CoverImageUpload upload);

  /// Best-effort delete of a previously-uploaded cover object, scoped
  /// to the caller's own `listings/<sellerId>/` folder. External URLs,
  /// foreign folders, and malformed URLs are silently skipped. The
  /// returned [Result] is always a [Success] — cleanup failures must
  /// never flip the main user operation into a user-visible error.
  Future<Result<void>> deleteByPublicUrl({
    required String publicUrl,
    required String sellerId,
  });

  /// Sequential upload in caller order — at most nine uploads per listing.
  Future<Result<List<UploadedListingImage>>> uploadSequential(
    List<CoverImageUpload> uploads,
  );

  /// Invokes best-effort [deleteByPublicUrl] for each metadata row; failures
  /// are swallowed and the result remains [Success].
  Future<Result<void>> deleteUploadedBatchBestEffort({
    required List<UploadedListingImage> images,
    required String sellerId,
  });
}
