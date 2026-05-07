/// Initials for avatar fallback — best-effort for Latin/Cyrillic single-code-unit chars.
String sellerInitialsFromDisplayName(String? displayName) {
  final trimmed = displayName?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '';
  }
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return '$a$b'.toUpperCase();
  }
  final single = parts[0];
  if (single.length >= 2) {
    return single.substring(0, 2).toUpperCase();
  }
  return single.toUpperCase();
}
