import 'package:equatable/equatable.dart';

/// Per-listing engagement from `get_my_seller_engagement_listings`.
class SellerListingEngagement extends Equatable {
  const SellerListingEngagement({
    required this.listingId,
    required this.periodImpressions,
    required this.periodPhoneActions,
    required this.periodWhatsappActions,
    required this.periodTelegramActions,
    required this.periodShares,
  });

  const SellerListingEngagement.zero(this.listingId)
    : periodImpressions = 0,
      periodPhoneActions = 0,
      periodWhatsappActions = 0,
      periodTelegramActions = 0,
      periodShares = 0;

  final String listingId;
  final int periodImpressions;
  final int periodPhoneActions;
  final int periodWhatsappActions;
  final int periodTelegramActions;
  final int periodShares;

  int get periodContactActions =>
      periodPhoneActions + periodWhatsappActions + periodTelegramActions;

  @override
  List<Object?> get props => [
    listingId,
    periodImpressions,
    periodPhoneActions,
    periodWhatsappActions,
    periodTelegramActions,
    periodShares,
  ];
}
