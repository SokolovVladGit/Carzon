import 'package:equatable/equatable.dart';

import 'seller_inventory_demand.dart';
import 'seller_listing_demand.dart';

class SellerDemandSnapshot extends Equatable {
  const SellerDemandSnapshot({required this.inventory, required this.listings});

  final SellerInventoryDemand inventory;
  final List<SellerListingDemand> listings;

  @override
  List<Object?> get props => [inventory, listings];
}
