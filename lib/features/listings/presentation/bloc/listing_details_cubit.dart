import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../messaging/domain/usecases/get_or_create_conversation.dart';
import '../../domain/entities/listing_contact.dart';
import '../../domain/usecases/get_listing_by_id.dart';
import '../../domain/usecases/get_listing_images.dart';
import '../../domain/usecases/get_listing_public_contact.dart';
import '../../domain/usecases/record_listing_view.dart';
import '../utils/listing_details_hero_urls.dart';
import 'listing_details_state.dart';

/// Loads the listing plus ordered gallery URLs for details carousel.
class ListingDetailsCubit extends Cubit<ListingDetailsState> {
  ListingDetailsCubit({
    required GetListingById getListingById,
    required GetListingImages getListingImages,
    required GetListingPublicContact getListingPublicContact,
    required GetOrCreateConversation getOrCreateConversation,
    required RecordListingView recordListingView,
  }) : _getListingById = getListingById,
       _getListingImages = getListingImages,
       _getListingPublicContact = getListingPublicContact,
       _getOrCreateConversation = getOrCreateConversation,
       _recordListingView = recordListingView,
       super(const ListingDetailsState.initial());

  final GetListingById _getListingById;
  final GetListingImages _getListingImages;
  final GetListingPublicContact _getListingPublicContact;
  final GetOrCreateConversation _getOrCreateConversation;
  final RecordListingView _recordListingView;

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
        emit(
          ListingDetailsState.success(
            listing,
            heroImageUrls: urls,
            viewStats: null,
          ),
        );
        unawaited(_recordViewAfterSuccessfulLoad(listing.id));
    }
  }

  Future<void> _recordViewAfterSuccessfulLoad(String listingId) async {
    final result = await _recordListingView(listingId);
    if (isClosed) return;
    if (state.status != ListingDetailsStatus.success) return;
    if (state.listing?.id != listingId) return;
    if (result case Success(:final value)) {
      emit(state.copyWith(viewStats: value));
    }
  }

  /// RPC `get_or_create_conversation`; [listingId] must be non-empty.
  /// Callers enforce auth and seller/buyer rules before invoking.
  Future<Result<String>> startConversationForListing(String listingId) =>
      _getOrCreateConversation(listingId);

  Future<Result<ListingContact>> revealPublicContact(String listingId) =>
      _getListingPublicContact(listingId);
}
