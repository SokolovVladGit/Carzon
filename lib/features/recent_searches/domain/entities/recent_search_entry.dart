import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing_discovery_criteria.dart';

/// Local recent discovery search snapshot (criteria + timestamp).
class RecentSearchEntry extends Equatable {
  const RecentSearchEntry({required this.criteria, required this.searchedAt});

  final ListingDiscoveryCriteria criteria;
  final DateTime searchedAt;

  @override
  List<Object?> get props => [criteria, searchedAt];
}
