/// Redacts dense digit spans (often phone fragments) from debug/log lines only.
///
/// Intended for diagnostics — never substitute this for authorization or privacy guarantees.
String redactLikelyDigitsInLogs(String raw) {
  return raw.replaceAll(RegExp(r'\+?\d[\d\s().-]{5,}\d'), '[digits]');
}
