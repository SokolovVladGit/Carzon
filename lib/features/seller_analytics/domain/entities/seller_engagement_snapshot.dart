import 'package:equatable/equatable.dart';

import 'seller_engagement_summary.dart';
import 'seller_listing_engagement.dart';

class SellerEngagementSnapshot extends Equatable {
  const SellerEngagementSnapshot({
    required this.summary,
    required this.listings,
  });

  final SellerEngagementSummary summary;
  final List<SellerListingEngagement> listings;

  @override
  List<Object?> get props => [summary, listings];
}
