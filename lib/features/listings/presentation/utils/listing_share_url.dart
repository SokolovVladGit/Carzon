/// Builds an optional public listing URL from a configured base and id.
///
/// Returns `null` when the base is missing, blank, or invalid so callers can
/// fall back to localized in-app copy without crashing the details page.
String? buildListingShareUrl(String? baseUrl, String listingId) {
  final trimmedBase = baseUrl?.trim();
  final trimmedId = listingId.trim();
  if (trimmedBase == null || trimmedBase.isEmpty || trimmedId.isEmpty) {
    return null;
  }

  try {
    final parsed = Uri.parse(trimmedBase);
    if (!parsed.hasScheme ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return null;
    }

    final normalizedBase = trimmedBase.replaceAll(RegExp(r'/+$'), '');
    final candidate = '$normalizedBase/listings/$trimmedId';
    final resolved = Uri.parse(candidate);
    if (!resolved.hasScheme ||
        (resolved.scheme != 'http' && resolved.scheme != 'https')) {
      return null;
    }
    return resolved.toString();
  } catch (_) {
    return null;
  }
}
