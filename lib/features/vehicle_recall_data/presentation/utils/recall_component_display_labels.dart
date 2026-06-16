import '../../../../l10n/app_localizations.dart';

/// Normalizes NHTSA component codes for deterministic lookup.
String normalizeRecallComponentKey(String raw) {
  return raw
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'\s*/\s*'), '/')
      .replaceAll(RegExp(r'\s*:\s*'), ':')
      .replaceAll(RegExp(r'\s+'), ' ');
}

typedef _RecallComponentLabelResolver = String Function(AppLocalizations l10n);

/// Buyer-safe localized labels for common NHTSA component strings.
final Map<String, _RecallComponentLabelResolver> kKnownRecallComponentLabels = {
  'SUSPENSION:FRONT': (l10n) => l10n.listingRecallComponentSuspensionFront,
  'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY': (l10n) =>
      l10n.listingRecallComponentSeatBeltsRear,
  'SEAT BELTS:REAR': (l10n) => l10n.listingRecallComponentSeatBeltsRear,
  'EQUIPMENT:OTHER:OWNERS/SERVICE/OTHER MANUAL': (l10n) =>
      l10n.listingRecallComponentEquipmentManual,
  'BACK OVER PREVENTION:DISPLAY FUNCTION': (l10n) =>
      l10n.listingRecallComponentBackOverPreventionDisplay,
  'ELECTRICAL SYSTEM:PROPULSION SYSTEM:TRACTION BATTERY': (l10n) =>
      l10n.listingRecallComponentElectricalPropulsionBattery,
  'SERVICE BRAKES, AIR:SUPPLY:HOSES, LINES/PIPING, AND FITTINGS': (l10n) =>
      l10n.listingRecallComponentServiceBrakesAirSupply,
  'AIR BAGS:FRONTAL': (l10n) => l10n.listingRecallComponentAirbagsFrontal,
};

/// Longest-prefix wins when exact key is absent (variant NHTSA strings).
final List<MapEntry<String, _RecallComponentLabelResolver>>
    kRecallComponentPrefixLabels =
    [
      MapEntry(
        'SERVICE BRAKES, AIR:SUPPLY',
        (l10n) => l10n.listingRecallComponentServiceBrakesAirSupply,
      ),
      MapEntry(
        'ELECTRICAL SYSTEM:PROPULSION SYSTEM',
        (l10n) => l10n.listingRecallComponentElectricalPropulsionBattery,
      ),
      MapEntry(
        'BACK OVER PREVENTION',
        (l10n) => l10n.listingRecallComponentBackOverPreventionDisplay,
      ),
      MapEntry(
        'EQUIPMENT:OTHER:OWNERS/SERVICE/OTHER MANUAL',
        (l10n) => l10n.listingRecallComponentEquipmentManual,
      ),
      MapEntry(
        'SEAT BELTS:REAR',
        (l10n) => l10n.listingRecallComponentSeatBeltsRear,
      ),
      MapEntry(
        'SUSPENSION:FRONT',
        (l10n) => l10n.listingRecallComponentSuspensionFront,
      ),
    ]..sort((a, b) => b.key.length.compareTo(a.key.length));

const int kRecallComponentCollapsedLabelMaxLength = 52;
const int kRecallComponentCompactFallbackParts = 2;

_RecallComponentLabelResolver? _resolveKnownRecallComponentLabel(String key) {
  final exact = kKnownRecallComponentLabels[key];
  if (exact != null) return exact;

  for (final entry in kRecallComponentPrefixLabels) {
    if (key.startsWith(entry.key)) return entry.value;
  }
  return null;
}

String _titleCaseRecallSegment(String segment) {
  if (segment.isEmpty) return segment;

  final letters = segment.replaceAll(RegExp(r'[^A-Za-z]'), '');
  final shouldNormalize =
      letters.isNotEmpty && letters == letters.toUpperCase();
  if (!shouldNormalize) return segment.trim();

  return segment
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _truncateRecallComponentLabel(String label) {
  if (label.length <= kRecallComponentCollapsedLabelMaxLength) return label;
  return '${label.substring(0, kRecallComponentCollapsedLabelMaxLength - 1).trimRight()}…';
}

/// Compact fallback for collapsed rows: first slash segment, up to two parts.
String formatRecallComponentDisplayFallbackCompact(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return text;

  final firstSlashSegment = text.split('/').first.trim();
  final colonParts = firstSlashSegment
      .split(':')
      .map((part) => _titleCaseRecallSegment(part.trim()))
      .where((part) => part.isNotEmpty)
      .take(kRecallComponentCompactFallbackParts)
      .toList();

  if (colonParts.isEmpty) {
    return _truncateRecallComponentLabel(_titleCaseRecallSegment(firstSlashSegment));
  }

  return _truncateRecallComponentLabel(colonParts.join(' · '));
}

/// Full title-case formatting (used in tests / non-collapsed contexts).
String formatRecallComponentDisplayFallback(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return text;

  final slashSegments = text.split('/');
  final formatted = <String>[];

  for (final slashSegment in slashSegments) {
    final colonParts = slashSegment
        .split(':')
        .map((part) => _titleCaseRecallSegment(part.trim()))
        .where((part) => part.isNotEmpty)
        .toList();
    if (colonParts.isEmpty) continue;
    formatted.add(colonParts.join(' · '));
  }

  return formatted.isEmpty
      ? _titleCaseRecallSegment(text)
      : formatted.join(' · ');
}

/// Buyer-facing collapsed-row component label (localized when known).
String resolveRecallComponentDisplayLabel(AppLocalizations l10n, String raw) {
  final key = normalizeRecallComponentKey(raw);
  final known = _resolveKnownRecallComponentLabel(key);
  if (known != null) return known(l10n);
  return formatRecallComponentDisplayFallbackCompact(raw);
}

/// Top-level category chip from a component string (localized when known).
String resolveRecallComponentCategoryLabel(AppLocalizations l10n, String raw) {
  final label = resolveRecallComponentDisplayLabel(l10n, raw);
  final parts = label.split(' · ');
  return parts.isNotEmpty ? parts.first : label;
}

/// Whether [raw] uses a known localized mapping (exact or prefix).
bool recallComponentHasKnownDisplayLabel(String raw) {
  final key = normalizeRecallComponentKey(raw);
  return _resolveKnownRecallComponentLabel(key) != null;
}
