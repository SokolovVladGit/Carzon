/// Supported seller-analytics lookback windows.
///
/// Backend RPCs accept only these exact day counts.
enum SellerAnalyticsPeriod {
  days7(7),
  days30(30),
  days90(90);

  const SellerAnalyticsPeriod(this.days);

  final int days;

  static const SellerAnalyticsPeriod defaultPeriod = days30;
}
