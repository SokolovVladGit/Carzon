import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';

/// Wraps a concrete body-type choice so sheet dismissal (`null`) stays distinct.
class ListingBodyTypeSelection {
  const ListingBodyTypeSelection(this.value);

  final ListingBodyType? value;
}

/// Modal picker for optional listing body type; pops [ListingBodyTypeSelection]
/// on tap.
class ListingBodyTypePickSheet extends StatelessWidget {
  const ListingBodyTypePickSheet({
    super.key,
    required this.appL10n,
    required this.selected,
  });

  final AppLocalizations appL10n;
  final ListingBodyType? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final items = <({ListingBodyType? value, String label})>[
      (value: null, label: appL10n.listingBodyTypeNotSpecified),
      ...ListingBodyType.values.map(
        (e) => (value: e, label: formatListingBodyType(appL10n, e)),
      ),
    ];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appL10n.listingBodyTypeSectionTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: appL10n.commonCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
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
                      onTap: () => Navigator.pop(
                        context,
                        ListingBodyTypeSelection(item.value),
                      ),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.12,
                                  color: cs.onSurface.withValues(
                                    alpha: isSel ? 1 : 0.82,
                                  ),
                                ),
                              ),
                            ),
                            if (isSel)
                              Icon(
                                Icons.check_rounded,
                                size: 21,
                                color: cs.onSurface.withValues(alpha: 0.58),
                              ),
                          ],
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
