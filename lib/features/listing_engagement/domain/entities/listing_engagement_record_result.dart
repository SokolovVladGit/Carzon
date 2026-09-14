import 'package:equatable/equatable.dart';

/// Result of `record_listing_engagement_event`. Never carries viewer identity.
class ListingEngagementRecordResult extends Equatable {
  const ListingEngagementRecordResult({
    required this.recorded,
    required this.todayCount,
  });

  final bool recorded;
  final int todayCount;

  @override
  List<Object?> get props => [recorded, todayCount];
}
