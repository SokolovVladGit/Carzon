import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_profile_cubit.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSellerPublicProfile extends Mock
    implements GetSellerPublicProfile {}

class _MockGetListings extends Mock implements GetListings {}

SellerPublicProfile _p({
  String userId = 'seller-1',
  String displayName = 'Seller Name',
}) {
  return SellerPublicProfile(
    userId: userId,
    displayName: displayName,
    avatarUrl: null,
    memberSince: DateTime.utc(2026, 1, 1),
    sellerType: SellerType.private,
    activeListingsCount: 2,
    ratingAverage: null,
    ratingCount: 0,
    reviewCount: 0,
    verifiedPhone: false,
    verifiedEmail: false,
    verifiedDealer: false,
  );
}

Listing _listing(String id) => Listing(
  id: id,
  title: 'Car',
  make: 'M',
  model: 'X',
  year: 2020,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'C',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 5, 1),
);

void main() {
  late _MockGetSellerPublicProfile getSellerPublicProfile;
  late _MockGetListings getListings;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(
      ListingsQuery(
        sellerId: 'fallback-sid',
        status: ListingStatus.active,
        page: 0,
        pageSize: AppConstants.defaultPageSize,
      ),
    );
  });

  setUp(() {
    getSellerPublicProfile = _MockGetSellerPublicProfile();
    getListings = _MockGetListings();
  });

  blocTest<SellerProfileCubit, SellerProfileState>(
    'loads profile and first page of active listings',
    build: () {
      when(
        () => getSellerPublicProfile(any()),
      ).thenAnswer((_) async => Success(_p()));
      when(
        () => getListings(any()),
      ).thenAnswer((_) async => Success([_listing('l1')]));
      return SellerProfileCubit(
        getSellerPublicProfile: getSellerPublicProfile,
        getListings: getListings,
        sellerId: 'seller-1',
      );
    },
    act: (c) => c.load(),
    expect: () => [
      isA<SellerProfileState>()
          .having((s) => s.profileLoading, 'profileLoading', isTrue)
          .having((s) => s.listingsLoading, 'listingsLoading', isTrue),
      isA<SellerProfileState>()
          .having((s) => s.profileLoading, 'profileLoading', isFalse)
          .having((s) => s.listingsLoading, 'listingsLoading', isFalse)
          .having((s) => s.profile?.displayName, 'displayName', 'Seller Name')
          .having((s) => s.listings.length, 'listings', 1),
    ],
    verify: (_) {
      verify(() => getSellerPublicProfile('seller-1')).called(1);
    },
  );

  blocTest<SellerProfileCubit, SellerProfileState>(
    'missing public profile maps to unavailable (null profile, no failure)',
    build: () {
      when(
        () => getSellerPublicProfile(any()),
      ).thenAnswer((_) async => const Success<SellerPublicProfile?>(null));
      when(() => getListings(any())).thenAnswer((_) async => Success([]));
      return SellerProfileCubit(
        getSellerPublicProfile: getSellerPublicProfile,
        getListings: getListings,
        sellerId: 'seller-1',
      );
    },
    act: (c) => c.load(),
    expect: () => [
      isA<SellerProfileState>()
          .having((s) => s.profileLoading, 'profileLoading', isTrue)
          .having((s) => s.listingsLoading, 'listingsLoading', isTrue),
      isA<SellerProfileState>()
          .having((s) => s.showProfileUnavailable, 'unavailable', isTrue)
          .having((s) => s.profileFailure, 'profileFailure', isNull),
    ],
  );

  blocTest<SellerProfileCubit, SellerProfileState>(
    'profile transport failure surfaces profileFailure',
    build: () {
      when(
        () => getSellerPublicProfile(any()),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('down')));
      when(() => getListings(any())).thenAnswer((_) async => Success([]));
      return SellerProfileCubit(
        getSellerPublicProfile: getSellerPublicProfile,
        getListings: getListings,
        sellerId: 'seller-1',
      );
    },
    act: (c) => c.load(),
    expect: () => [
      isA<SellerProfileState>()
          .having((s) => s.profileLoading, 'profileLoading', isTrue)
          .having((s) => s.listingsLoading, 'listingsLoading', isTrue),
      isA<SellerProfileState>().having(
        (s) => s.profileFailure,
        'failure',
        isA<ServerFailure>(),
      ),
    ],
  );
}
