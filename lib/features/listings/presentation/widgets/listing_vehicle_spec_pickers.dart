import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_formatters.dart';

/// Opens a modal list; first option clears fuel type (`null`).
Future<ListingFuelType?> showListingFuelTypePickerSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required ListingFuelType? selected,
}) {
  return showModalBottomSheet<ListingFuelType?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _FuelTypePickSheet(appL10n: l10n, selected: selected),
  );
}

/// Opens a modal list; first option clears drivetrain (`null`).
Future<ListingDrivetrain?> showListingDrivetrainPickerSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required ListingDrivetrain? selected,
}) {
  return showModalBottomSheet<ListingDrivetrain?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _DrivetrainPickSheet(appL10n: l10n, selected: selected),
  );
}

/// Tappable row used on create listing (matches body-type picker chrome).
class ListingVehicleSpecPickerRow extends StatelessWidget {
  const ListingVehicleSpecPickerRow({
    super.key,
    required this.valueText,
    required this.enabled,
    required this.onTap,
    this.fieldKey,
  });

  final String valueText;
  final bool enabled;
  final VoidCallback? onTap;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: fieldKey,
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.onSurface.withValues(alpha: 0.038),
        highlightColor: cs.onSurface.withValues(alpha: 0.018),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(
                alpha: br == Brightness.light ? 0.32 : 0.38,
              ),
            ),
            color: Color.alphaBlend(
              cs.outlineVariant.withValues(
                alpha: br == Brightness.light ? 0.042 : 0.078,
              ),
              cs.surface,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  valueText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.22,
                    color: cs.onSurface.withValues(alpha: 0.94),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color.alphaBlend(
                    cs.outlineVariant.withValues(alpha: 0.11),
                    cs.surface,
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.26),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelTypePickSheet extends StatelessWidget {
  const _FuelTypePickSheet({
    required this.appL10n,
    required this.selected,
  });

  final AppLocalizations appL10n;
  final ListingFuelType? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;

    final items =
        <
          ({
            ListingFuelType? value,
            String label,
          })
        >[
          (value: null, label: appL10n.listingBodyTypeNotSpecified),
          ...ListingFuelType.values.map(
            (e) =>
                (value: e, label: formatListingFuelType(appL10n, e)),
          ),
        ];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appL10n.listingFuelType,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: appL10n.commonCancel,
                    onPressed: () =>
                        Navigator.of(context).maybePop<ListingFuelType?>(),
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
                          Navigator.pop<ListingFuelType?>(context, item.value),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? cs.onSurface.withValues(
                                    alpha:
                                        br == Brightness.light ? 0.26 : 0.34,
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
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
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

class _DrivetrainPickSheet extends StatelessWidget {
  const _DrivetrainPickSheet({
    required this.appL10n,
    required this.selected,
  });

  final AppLocalizations appL10n;
  final ListingDrivetrain? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;

    final items =
        <
          ({
            ListingDrivetrain? value,
            String label,
          })
        >[
          (value: null, label: appL10n.listingBodyTypeNotSpecified),
          ...ListingDrivetrain.values.map(
            (e) =>
                (value: e, label: formatListingDrivetrain(appL10n, e)),
          ),
        ];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appL10n.listingDrivetrain,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: appL10n.commonCancel,
                    onPressed: () =>
                        Navigator.of(context).maybePop<ListingDrivetrain?>(),
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
                      onTap: () => Navigator.pop<ListingDrivetrain?>(
                        context,
                        item.value,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? cs.onSurface.withValues(
                                    alpha:
                                        br == Brightness.light ? 0.26 : 0.34,
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
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
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
