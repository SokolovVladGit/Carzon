import '../../../../core/utils/result.dart';
import '../entities/uploaded_listing_image.dart';
import '../repositories/create_listing_repository.dart';

/// Deletes previously uploaded staging objects — failures never surface as errors.
class DeleteUploadedListingImagesBestEffort {
  DeleteUploadedListingImagesBestEffort(this._repository);
  final ListingImageRepository _repository;

  Future<Result<void>> call({
    required List<UploadedListingImage> images,
    required String sellerId,
  }) => _repository.deleteUploadedBatchBestEffort(
    images: images,
    sellerId: sellerId,
  );
}
