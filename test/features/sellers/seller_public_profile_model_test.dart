import 'package:carzon/features/sellers/data/models/seller_public_profile_model.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses full RPC-shaped JSON row', () {
    final m = SellerPublicProfileModel.fromJson({
      'user_id': '11111111-1111-1111-1111-111111111111',
      'display_name': 'Test Seller',
      'avatar_url': 'https://example.com/a.jpg',
      'member_since': '2026-01-15T10:00:00.000Z',
      'seller_type': 'dealer',
      'active_listings_count': 3,
      'rating_average': '4.20',
      'rating_count': 10,
      'review_count': 7,
      'verified_phone': true,
      'verified_email': false,
      'verified_dealer': true,
    });

    expect(m.userId, '11111111-1111-1111-1111-111111111111');
    expect(m.displayName, 'Test Seller');
    expect(m.avatarUrl, 'https://example.com/a.jpg');
    expect(m.memberSince.toUtc(), DateTime.utc(2026, 1, 15, 10));
    expect(m.sellerType, SellerType.dealer);
    expect(m.activeListingsCount, 3);
    expect(m.ratingAverage, 4.2);
    expect(m.ratingCount, 10);
    expect(m.reviewCount, 7);
    expect(m.verifiedPhone, isTrue);
    expect(m.verifiedEmail, isFalse);
    expect(m.verifiedDealer, isTrue);
  });

  test('parses nullable display_name and numeric rating_average', () {
    final m = SellerPublicProfileModel.fromJson({
      'user_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'display_name': null,
      'avatar_url': null,
      'member_since': '2026-03-01T00:00:00Z',
      'seller_type': 'unknown_should_private',
      'active_listings_count': 0,
      'rating_average': null,
      'rating_count': 0,
      'review_count': 0,
      'verified_phone': false,
      'verified_email': false,
      'verified_dealer': false,
    });

    expect(m.displayName, isNull);
    expect(m.sellerType, SellerType.private);
    expect(m.activeListingsCount, 0);
    expect(m.ratingAverage, isNull);
  });

  test('active_listings_count accepts bigint-like num', () {
    final m = SellerPublicProfileModel.fromJson({
      'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'display_name': null,
      'avatar_url': null,
      'member_since': '2026-03-01T00:00:00Z',
      'seller_type': 'private',
      'active_listings_count': 42.0,
      'rating_average': 3.5,
      'rating_count': 1,
      'review_count': 1,
      'verified_phone': false,
      'verified_email': false,
      'verified_dealer': false,
    });
    expect(m.activeListingsCount, 42);
    expect(m.ratingAverage, 3.5);
  });
}
