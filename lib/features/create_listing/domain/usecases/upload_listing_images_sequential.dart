import '../../../../core/utils/result.dart';
import '../entities/cover_image_upload.dart';
import '../entities/uploaded_listing_image.dart';
import '../repositories/create_listing_repository.dart';

/// Uploads up to nine listing images sequentially, preserving caller order.
class UploadListingImagesSequential {
  UploadListingImagesSequential(this._repository);
  final ListingImageRepository _repository;

  Future<Result<List<UploadedListingImage>>> call(
    List<CoverImageUpload> uploads,
  ) => _repository.uploadSequential(uploads);
}
