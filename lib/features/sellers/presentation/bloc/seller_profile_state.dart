import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/seller_public_profile.dart';

class SellerProfileState extends Equatable {
  const SellerProfileState({
    this.profileLoading = true,
    this.profile,
    this.profileFailure,
    this.listingsLoading = true,
    this.listings = const [],
    this.listingsFailure,
    this.listingsPage = 0,
    this.hasMoreListings = false,
    this.loadingMoreListings = false,
  });

  final bool profileLoading;
  final SellerPublicProfile? profile;
  final Failure? profileFailure;

  final bool listingsLoading;
  final List<Listing> listings;
  final Failure? listingsFailure;

  final int listingsPage;
  final bool hasMoreListings;
  final bool loadingMoreListings;

  bool get showProfileUnavailable =>
      !profileLoading && profileFailure == null && profile == null;

  SellerProfileState copyWith({
    bool? profileLoading,
    SellerPublicProfile? profile,
    bool assignProfile = false,
    Failure? profileFailure,
    bool clearProfileFailure = false,
    bool? listingsLoading,
    List<Listing>? listings,
    Failure? listingsFailure,
    bool clearListingsFailure = false,
    int? listingsPage,
    bool? hasMoreListings,
    bool? loadingMoreListings,
  }) {
    return SellerProfileState(
      profileLoading: profileLoading ?? this.profileLoading,
      profile: assignProfile ? profile : this.profile,
      profileFailure: clearProfileFailure
          ? null
          : (profileFailure ?? this.profileFailure),
      listingsLoading: listingsLoading ?? this.listingsLoading,
      listings: listings ?? this.listings,
      listingsFailure: clearListingsFailure
          ? null
          : (listingsFailure ?? this.listingsFailure),
      listingsPage: listingsPage ?? this.listingsPage,
      hasMoreListings: hasMoreListings ?? this.hasMoreListings,
      loadingMoreListings: loadingMoreListings ?? this.loadingMoreListings,
    );
  }

  /// First paint while both slices are still resolving.
  bool get isInitialSkeleton =>
      profileLoading &&
      profileFailure == null &&
      profile == null &&
      listingsLoading &&
      listings.isEmpty &&
      listingsFailure == null;

  @override
  List<Object?> get props => [
    profileLoading,
    profile,
    profileFailure,
    listingsLoading,
    listings,
    listingsFailure,
    listingsPage,
    hasMoreListings,
    loadingMoreListings,
  ];
}
