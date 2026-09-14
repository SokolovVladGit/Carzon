/// In-memory session guard so one listing does not re-hit the RPC
/// after a qualified impression in the current app session.
class ListingImpressionSessionGuard {
  final Set<String> _recorded = <String>{};

  bool contains(String listingId) => _recorded.contains(listingId);

  /// Returns true the first time [listingId] is claimed.
  bool claim(String listingId) => _recorded.add(listingId);

  void reset() => _recorded.clear();
}
