// PostgREST / ILIKE helpers for home-feed free-text discovery search.
//
// Free-text [ListingsQuery.search] matches `title`, `make`, or `model`
// (OR). Explicit `make` / `model` filters remain separate AND predicates.

/// Escapes user text for use inside an ILIKE `%…%` pattern.
///
/// Treats `%`, `_`, and `\` as literals (PostgREST / Postgres ILIKE).
String escapeIlikePatternFragment(String raw) {
  return raw
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Wraps [value] for PostgREST filter syntax when it contains reserved chars.
String postgrestFilterValue(String value) {
  if (RegExp(r'[,\(\)".]').hasMatch(value)) {
    return '"${value.replaceAll('"', r'\"')}"';
  }
  return value;
}

/// Builds `%term%` after trimming and ILIKE escaping.
String listingsDiscoverySearchIlikePattern(String trimmedSearch) {
  return '%${escapeIlikePatternFragment(trimmedSearch)}%';
}

/// PostgREST `.or(...)` filter matching title OR make OR model.
String listingsDiscoverySearchPostgrestOrFilter(String trimmedSearch) {
  final pattern = postgrestFilterValue(
    listingsDiscoverySearchIlikePattern(trimmedSearch),
  );
  return 'title.ilike.$pattern,make.ilike.$pattern,model.ilike.$pattern';
}

/// Mirrors feed / filter-alert free-text search semantics for unit tests.
bool listingDiscoveryFreeTextSearchMatches({
  required String searchTerm,
  String? title,
  String? make,
  String? model,
}) {
  final term = searchTerm.trim();
  if (term.isEmpty) return true;
  return _ilikeContains(title, term) ||
      _ilikeContains(make, term) ||
      _ilikeContains(model, term);
}

bool _ilikeContains(String? haystack, String needle) {
  if (haystack == null || haystack.isEmpty) return false;
  final escapedNeedle = escapeIlikePatternFragment(needle);
  final regex = RegExp(
    '^.*${_likePatternToRegex(escapedNeedle)}.*\$',
    caseSensitive: false,
  );
  return regex.hasMatch(haystack);
}

String _likePatternToRegex(String escapedLikeFragment) {
  final buffer = StringBuffer();
  for (var i = 0; i < escapedLikeFragment.length; i++) {
    final ch = escapedLikeFragment[i];
    if (ch == r'\' && i + 1 < escapedLikeFragment.length) {
      final next = escapedLikeFragment[i + 1];
      if (next == '%' || next == '_' || next == r'\') {
        buffer.write(RegExp.escape(next));
        i++;
        continue;
      }
    }
    buffer.write(RegExp.escape(ch));
  }
  return buffer.toString();
}
