import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/catalog/listing_brands.dart';

/// Opens searchable brand/make sheet aligned with listing create/edit flows.
///
/// Returns a catalog English label (e.g. `Toyota`, `Other`) or trimmed custom
/// make text from manual entry when the search has no catalog matches.
Future<String?> showListingBrandPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ListingBrandPickSheet(appL10n: l10n),
  );
}

String localizedListingBrandCatalogLabel(
  AppLocalizations l10n,
  String catalogValue,
) => catalogValue == kListingBrandCatalog.last
    ? l10n.createListingBrandOther
    : catalogValue;

/// Resolved catalog selection after [showListingBrandPickSheet].
class ListingBrandPickApply {
  const ListingBrandPickApply({
    required this.catalogKey,
    this.customMakeText = '',
  });

  final String catalogKey;
  final String customMakeText;
}

/// Maps a picker result to catalog `"Other"` + optional custom text.
ListingBrandPickApply applyListingBrandPick(String picked) {
  final trimmed = picked.trim();
  if (trimmed.isEmpty) {
    return const ListingBrandPickApply(catalogKey: kListingBrandCatalogOther);
  }

  final normalized = listingBrandNormalizeForLookup(trimmed);
  if (normalized != null) {
    return ListingBrandPickApply(catalogKey: normalized);
  }

  return ListingBrandPickApply(
    catalogKey: kListingBrandCatalogOther,
    customMakeText: trimmed,
  );
}

/// Label for the brand picker row / read-only field.
String listingBrandFieldDisplay({
  required AppLocalizations l10n,
  required String? catalogKey,
  required String customMakeText,
}) {
  if (catalogKey == null) return l10n.createListingChooseBrand;
  if (catalogKey == kListingBrandCatalogOther) {
    final custom = customMakeText.trim();
    if (custom.isEmpty) {
      return localizedListingBrandCatalogLabel(l10n, kListingBrandCatalogOther);
    }
    return custom;
  }
  return localizedListingBrandCatalogLabel(l10n, catalogKey);
}

/// Final persisted make for listing RPCs.
String effectiveListingMakeForSubmit({
  required String? catalogKey,
  required String customMakeText,
}) {
  if (catalogKey == null) return '';
  if (catalogKey == kListingBrandCatalogOther) {
    return customMakeText.trim();
  }
  return catalogKey;
}

/// Validates the custom-make field when catalog sentinel `"Other"` is selected.
String? validateListingCustomMakeField(
  AppLocalizations l10n, {
  required String? catalogKey,
  required String customMakeText,
}) {
  if (catalogKey != kListingBrandCatalogOther) return null;

  final trimmed = customMakeText.trim();
  if (trimmed.isEmpty) return l10n.validationRequired;
  if (trimmed.toLowerCase() == kListingBrandCatalogOther.toLowerCase()) {
    return l10n.createListingCustomBrandInvalid;
  }
  return null;
}

class ListingBrandPickSheet extends StatefulWidget {
  const ListingBrandPickSheet({super.key, required this.appL10n});

  final AppLocalizations appL10n;

  @override
  State<ListingBrandPickSheet> createState() => _ListingBrandPickSheetState();
}

class _ListingBrandPickSheetState extends State<ListingBrandPickSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _popManualMake(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.appL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final queryTrimmed = _query.text.trim();
    final q = queryTrimmed.toLowerCase();

    final filtered = kListingBrandCatalog
        .where(
          (b) =>
              q.isEmpty ||
              localizedListingBrandCatalogLabel(
                l10n,
                b,
              ).toLowerCase().contains(q),
        )
        .toList(growable: false);

    final showManualEmptyState = q.isNotEmpty && filtered.isEmpty;

    return AnimatedPadding(
      duration: Duration.zero,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.createListingChooseBrand,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: l10n.createListingSearchBrandsHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: showManualEmptyState
                  ? _ManualMakeEmptyState(
                      l10n: l10n,
                      query: queryTrimmed,
                      onUseManualMake: () => _popManualMake(queryTrimmed),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: .5,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final brandEnglish = filtered[index];
                        final label = localizedListingBrandCatalogLabel(
                          l10n,
                          brandEnglish,
                        );
                        return ListTile(
                          title: Text(label),
                          onTap: () => Navigator.pop(context, brandEnglish),
                        );
                      },
                    ),
            ),
            if (!showManualEmptyState && queryTrimmed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Text(
                  l10n.brandPickManualHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ManualMakeEmptyState extends StatelessWidget {
  const _ManualMakeEmptyState({
    required this.l10n,
    required this.query,
    required this.onUseManualMake,
  });

  final AppLocalizations l10n;
  final String query;
  final VoidCallback onUseManualMake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 44,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.brandPickNotFoundTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.brandPickManualHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onUseManualMake,
            icon: Icon(Icons.edit_outlined, size: 20),
            label: Text(l10n.brandPickUseMake(query)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onUseManualMake,
            child: Text(l10n.brandPickEnterManually),
          ),
        ],
      ),
    );
  }
}
