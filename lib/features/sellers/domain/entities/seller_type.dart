/// Public seller segment shown on the seller profile surface.
enum SellerType {
  private,
  dealer;

  static SellerType fromWire(Object? raw) {
    final key = raw?.toString().trim().toLowerCase();
    return key == 'dealer' ? SellerType.dealer : SellerType.private;
  }

  String get wireValue => switch (this) {
    SellerType.private => 'private',
    SellerType.dealer => 'dealer',
  };
}
