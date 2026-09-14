import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/sellers/data/mappers/my_seller_context_mapper.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps private and unverified', () {
    final context = mySellerContextFromRow({
      'seller_type': 'private',
      'verified_dealer': false,
    });
    expect(context.sellerType, SellerType.private);
    expect(context.verifiedDealer, isFalse);
  });

  test('maps dealer and verified', () {
    final context = mySellerContextFromRow({
      'seller_type': 'DEALER',
      'verified_dealer': true,
    });
    expect(context.sellerType, SellerType.dealer);
    expect(context.verifiedDealer, isTrue);
  });

  test('unknown seller type falls back to private', () {
    final context = mySellerContextFromRow({
      'seller_type': 'agency',
      'verified_dealer': 't',
    });
    expect(context.sellerType, SellerType.private);
    expect(context.verifiedDealer, isTrue);
  });

  test('invalid RPC payload throws', () {
    expect(
      () => requireSellerContextRow(null, 'get_my_seller_context'),
      throwsA(isA<ServerException>()),
    );
    expect(
      () => requireSellerContextRow(<Object?>[], 'get_my_seller_context'),
      throwsA(isA<ServerException>()),
    );
  });
}
