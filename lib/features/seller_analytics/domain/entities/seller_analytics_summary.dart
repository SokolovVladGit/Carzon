import 'package:equatable/equatable.dart';

import '../../../sellers/domain/entities/seller_type.dart';

/// Period-scoped seller KPIs from `get_my_seller_analytics_summary`.
class SellerAnalyticsSummary extends Equatable {
  const SellerAnalyticsSummary({
    required this.sellerType,
    required this.verifiedDealer,
    required this.activeCount,
    required this.soldCount,
    required this.periodViews,
    required this.currentFavorites,
    required this.periodInquiries,
    this.conversionPercent,
  });

  final SellerType sellerType;
  final bool verifiedDealer;
  final int activeCount;
  final int soldCount;
  final int periodViews;
  final int currentFavorites;
  final int periodInquiries;

  /// `period_inquiries / period_views * 100`. Null when views are 0.
  final double? conversionPercent;

  bool get hasListingUniverse => activeCount > 0 || soldCount > 0;

  @override
  List<Object?> get props => [
    sellerType,
    verifiedDealer,
    activeCount,
    soldCount,
    periodViews,
    currentFavorites,
    periodInquiries,
    conversionPercent,
  ];
}
