import '../../../../core/utils/result.dart';
import '../entities/cover_image_upload.dart';
import '../repositories/create_listing_repository.dart';

/// Uploads a single listing cover image and returns its public URL.
///
/// Backend-agnostic: takes a [CoverImageUpload] value object carrying
/// raw bytes + content type + owner uid. No Supabase, `XFile`, or
/// platform types leak into the domain.
class UploadListingCoverImage {
  UploadListingCoverImage(this._repository);
  final ListingImageRepository _repository;

  Future<Result<String>> call(CoverImageUpload upload) =>
      _repository.uploadCover(upload);
}
