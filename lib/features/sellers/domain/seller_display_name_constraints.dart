/// Server and client agree on max public seller display name length for edits.
class SellerDisplayNameConstraints {
  SellerDisplayNameConstraints._();

  /// Matches `update_my_seller_display_name` (migration).
  static const int maxLength = 80;
}
