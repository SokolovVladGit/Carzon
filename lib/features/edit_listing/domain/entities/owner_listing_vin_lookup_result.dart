import 'package:equatable/equatable.dart';

/// Result of owner-only VIN lookup for edit flow (never used on public paths).
class OwnerListingVinLookupResult extends Equatable {
  const OwnerListingVinLookupResult({
    this.normalizedVin,
    this.fetchFailed = false,
  });

  /// Normalized 17-character VIN when a row exists.
  final String? normalizedVin;

  /// True when the RPC failed (form keeps preserve semantics on save).
  final bool fetchFailed;

  @override
  List<Object?> get props => [normalizedVin, fetchFailed];
}
