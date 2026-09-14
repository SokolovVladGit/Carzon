import 'package:equatable/equatable.dart';

/// Period engagement totals from `get_my_seller_engagement_summary`.
///
/// Counts are CTA actions, not unique leads or buyers.
class SellerEngagementSummary extends Equatable {
  const SellerEngagementSummary({
    required this.periodImpressions,
    required this.periodPhoneActions,
    required this.periodWhatsappActions,
    required this.periodTelegramActions,
    required this.periodShares,
  });

  const SellerEngagementSummary.zero()
    : periodImpressions = 0,
      periodPhoneActions = 0,
      periodWhatsappActions = 0,
      periodTelegramActions = 0,
      periodShares = 0;

  final int periodImpressions;
  final int periodPhoneActions;
  final int periodWhatsappActions;
  final int periodTelegramActions;
  final int periodShares;

  int get periodContactActions =>
      periodPhoneActions + periodWhatsappActions + periodTelegramActions;

  @override
  List<Object?> get props => [
    periodImpressions,
    periodPhoneActions,
    periodWhatsappActions,
    periodTelegramActions,
    periodShares,
  ];
}
