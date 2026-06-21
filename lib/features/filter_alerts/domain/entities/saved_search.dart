import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing_discovery_criteria.dart';

/// One saved listing-discovery search with optional push alerts (v2).
class SavedSearch extends Equatable {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.criteria,
    required this.alertsEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.lastNotifiedAt,
  });

  final String id;
  final String name;
  final ListingDiscoveryCriteria criteria;
  final bool alertsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastNotifiedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    criteria,
    alertsEnabled,
    createdAt,
    updatedAt,
    lastNotifiedAt,
  ];
}

/// Max saved searches per authenticated user (matches hosted SQL).
abstract final class SavedSearchesLimits {
  static const int maxPerUser = 5;
}
