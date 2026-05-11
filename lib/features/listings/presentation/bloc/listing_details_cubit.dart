import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../messaging/domain/usecases/get_or_create_conversation.dart';
import '../../domain/usecases/get_listing_by_id.dart';
import '../../domain/usecases/get_listing_images.dart';
import '../utils/listing_details_hero_urls.dart';
import 'listing_details_state.dart';

/// Loads the listing plus ordered gallery URLs for details carousel.
class ListingDetailsCubit extends Cubit<ListingDetailsState> {
  ListingDetailsCubit({
    required GetListingById getListingById,
    required GetListingImages getListingImages,
    required GetOrCreateConversation getOrCreateConversation,
  }) : _getListingById = getListingById,
       _getListingImages = getListingImages,
       _getOrCreateConversation = getOrCreateConversation,
       super(const ListingDetailsState.initial());

  final GetListingById _getListingById;
  final GetListingImages _getListingImages;
  final GetOrCreateConversation _getOrCreateConversation;

  Future<void> load(String id, {String? initialCoverImageUrl}) async {
    emit(const ListingDetailsState.loading());
    final listingRes = await _getListingById(id);
    switch (listingRes) {
      case FailureResult(:final failure):
        emit(ListingDetailsState.failure(failure));
        return;
      case Success(:final value):
        final listing = value;
        final imagesRes = await _getListingImages(listing.id);
        final urls = listingDetailsHeroImageUrls(
          listing: listing,
          imagesResult: imagesRes,
          preferredFirstUrl: initialCoverImageUrl,
        );
        emit(ListingDetailsState.success(listing, heroImageUrls: urls));
    }
  }

  /// RPC `get_or_create_conversation`; [listingId] must be non-empty.
  /// Callers enforce auth and seller/buyer rules before invoking.
  Future<Result<String>> startConversationForListing(String listingId) =>
      _getOrCreateConversation(listingId);
}
