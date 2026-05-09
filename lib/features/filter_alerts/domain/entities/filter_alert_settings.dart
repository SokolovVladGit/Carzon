import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing_discovery_criteria.dart';

/// Single per-user snapshot used for future new-listing alerts (delivery TBD).
class FilterAlertSettings extends Equatable {
  const FilterAlertSettings({
    required this.userId,
    required this.criteria,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final ListingDiscoveryCriteria? criteria;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    userId,
    criteria,
    notificationsEnabled,
    createdAt,
    updatedAt,
  ];
}
