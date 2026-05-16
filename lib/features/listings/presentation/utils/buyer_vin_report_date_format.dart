/// Buyer VIN report timestamp as `dd.MM.yyyy` using [DateTime.toLocal].
///
/// Kept separate from shared listing date formatting so other screens stay unchanged.
String formatBuyerVinReportDate(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString().padLeft(4, '0');
  return '$d.$m.$y';
}
