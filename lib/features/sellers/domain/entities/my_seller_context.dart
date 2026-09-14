import 'package:equatable/equatable.dart';

import 'seller_type.dart';

/// Authoritative self-service seller mode from `get_my_seller_context`.
class MySellerContext extends Equatable {
  const MySellerContext({
    required this.sellerType,
    required this.verifiedDealer,
  });

  final SellerType sellerType;
  final bool verifiedDealer;

  @override
  List<Object?> get props => [sellerType, verifiedDealer];
}
