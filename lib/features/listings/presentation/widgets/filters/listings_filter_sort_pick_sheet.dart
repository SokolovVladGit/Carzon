import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/listing_sort_option.dart';
import 'listings_filter_labels.dart';

/// Opens styled sort picker for listings filter sheet (always returns a choice).
Future<ListingSortOption?> showListingsFilterSortPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required ListingSortOption selected,
}) {
  return showModalBottomSheet<ListingSortOption>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => ListingsFilterSortPickSheet(
      appL10n: l10n,
      selected: selected,
    ),
  );
}

/// Modal list for [ListingSortOption]; matches vehicle-spec filter pick sheets.
class ListingsFilterSortPickSheet extends StatelessWidget {
  const ListingsFilterSortPickSheet({
    super.key,
    required this.appL10n,
    required this.selected,
  });

  final AppLocalizations appL10n;
  final ListingSortOption selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;

    final items = ListingSortOption.values
        .map(
          (e) => (
            value: e,
            label: listingFilterSortOptionLabel(appL10n, e),
          ),
        )
        .toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appL10n.filterSortLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: appL10n.commonCancel,
                    onPressed: () =>
                        Navigator.of(context).maybePop<ListingSortOption>(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSel = item.value == selected;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: cs.onSurface.withValues(alpha: 0.038),
                      highlightColor: cs.onSurface.withValues(alpha: 0.018),
                      onTap: () =>
                          Navigator.pop<ListingSortOption>(context, item.value),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? cs.onSurface.withValues(
                                    alpha: br == Brightness.light ? 0.26 : 0.34,
                                  )
                                : cs.outlineVariant.withValues(alpha: 0.30),
                          ),
                          color: isSel
                              ? Color.alphaBlend(
                                  cs.onSurface.withValues(
                                    alpha: br == Brightness.light
                                        ? 0.065
                                        : 0.11,
                                  ),
                                  cs.surfaceContainerLowest,
                                )
                              : Color.alphaBlend(
                                  cs.outlineVariant.withValues(alpha: 0.035),
                                  cs.surfaceContainerLowest,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        child: Text(
                          item.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
