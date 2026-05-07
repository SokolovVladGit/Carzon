import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/repositories/listings_repository.dart';
import '../../../listings/domain/usecases/get_listings.dart';
import '../../domain/usecases/get_seller_public_profile.dart';
import 'seller_profile_state.dart';

class SellerProfileCubit extends Cubit<SellerProfileState> {
  SellerProfileCubit({
    required GetSellerPublicProfile getSellerPublicProfile,
    required GetListings getListings,
    required String sellerId,
  }) : _getSellerPublicProfile = getSellerPublicProfile,
       _getListings = getListings,
       _sellerId = sellerId,
       super(const SellerProfileState());

  final GetSellerPublicProfile _getSellerPublicProfile;
  final GetListings _getListings;
  final String _sellerId;

  Future<void> load() async {
    emit(
      const SellerProfileState(
        profileLoading: true,
        listingsLoading: true,
        listings: [],
        listingsPage: 0,
        hasMoreListings: false,
        loadingMoreListings: false,
      ),
    );

    final profileFuture = _getSellerPublicProfile(_sellerId);
    final listingsFuture = _getListings(
      ListingsQuery(
        sellerId: _sellerId,
        status: ListingStatus.active,
        page: 0,
        pageSize: AppConstants.defaultPageSize,
      ),
    );

    final profileResult = await profileFuture;
    final listingsResult = await listingsFuture;

    var next = state.copyWith(
      profileLoading: false,
      listingsLoading: false,
      clearProfileFailure: true,
      clearListingsFailure: true,
    );

    profileResult.fold(
      (f) => next = next.copyWith(profileFailure: f),
      (p) => next = next.copyWith(assignProfile: true, profile: p),
    );

    listingsResult.fold((f) => next = next.copyWith(listingsFailure: f), (
      list,
    ) {
      next = next.copyWith(
        listings: list,
        listingsPage: 0,
        hasMoreListings: list.length >= AppConstants.defaultPageSize,
      );
    });

    emit(next);
  }

  Future<void> retry() => load();

  Future<void> loadMoreListings() async {
    if (state.loadingMoreListings || !state.hasMoreListings) return;
    emit(state.copyWith(loadingMoreListings: true));
    final nextPage = state.listingsPage + 1;
    final result = await _getListings(
      ListingsQuery(
        sellerId: _sellerId,
        status: ListingStatus.active,
        page: nextPage,
        pageSize: AppConstants.defaultPageSize,
      ),
    );
    result.fold(
      (f) =>
          emit(state.copyWith(loadingMoreListings: false, listingsFailure: f)),
      (list) {
        emit(
          state.copyWith(
            loadingMoreListings: false,
            listings: [...state.listings, ...list],
            listingsPage: nextPage,
            hasMoreListings: list.length >= AppConstants.defaultPageSize,
          ),
        );
      },
    );
  }
}
