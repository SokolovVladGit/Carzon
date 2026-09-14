/// Conservative conversion display. Null / non-finite → [unavailable].
///
/// Integers stay whole (`12%`). One decimal only when it carries information
/// (`4.2%`). Never forced two-decimal formatting.
String formatStatisticsConversion(double? value, String unavailable) {
  if (value == null || !value.isFinite) return unavailable;
  final clamped = value < 0 ? 0.0 : value;
  final tenths = (clamped * 10).round();
  if (tenths % 10 == 0) {
    return '${tenths ~/ 10}%';
  }
  return '${(tenths / 10).toStringAsFixed(1)}%';
}
