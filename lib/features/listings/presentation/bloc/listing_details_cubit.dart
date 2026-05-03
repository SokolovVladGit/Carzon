import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/get_listing_by_id.dart';
import '../../domain/usecases/get_listing_images.dart';
import '../utils/listing_details_hero_urls.dart';
import 'listing_details_state.dart';

/// Loads the listing plus ordered gallery URLs for details carousel.
class ListingDetailsCubit extends Cubit<ListingDetailsState> {
  ListingDetailsCubit({
    required GetListingById getListingById,
    required GetListingImages getListingImages,
  }) : _getListingById = getListingById,
       _getListingImages = getListingImages,
       super(const ListingDetailsState.initial());

  final GetListingById _getListingById;
  final GetListingImages _getListingImages;

  Future<void> load(String id) async {
    emit(const ListingDetailsState.loading());
    final listingRes = await _getListingById(id);
    switch (listingRes) {
      case FailureResult(:final failure):
        emit(ListingDetailsState.failure(failure.message));
        return;
      case Success(:final value):
        final listing = value;
        final imagesRes = await _getListingImages(listing.id);
        final urls = listingDetailsHeroImageUrls(
          listing: listing,
          imagesResult: imagesRes,
        );
        emit(ListingDetailsState.success(listing, heroImageUrls: urls));
    }
  }
}
