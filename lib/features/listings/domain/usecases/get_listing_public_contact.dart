import '../../../../core/utils/result.dart';
import '../entities/listing_contact.dart';
import '../repositories/listings_repository.dart';

class GetListingPublicContact {
  GetListingPublicContact(this._repository);

  final ListingsRepository _repository;

  Future<Result<ListingContact>> call(String listingId) =>
      _repository.getPublicContact(listingId);
}
