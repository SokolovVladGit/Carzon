import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../listings/presentation/widgets/listing_cover_image.dart';
import '../../domain/entities/compare_resolved_slot.dart';
import '../utils/compare_spec_formatters.dart';

/// One vehicle column in the compare header strip.
class CompareVehicleColumnHeader extends StatelessWidget {
  const CompareVehicleColumnHeader({
    super.key,
    required this.slot,
    required this.width,
    required this.onRemove,
  });

  final CompareResolvedSlot slot;
  final double width;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final snapshot = slot.item.snapshot;
    final listing = slot.listing;
    final fmt = CompareSpecFormatters(l10n);

    final title = _title(
      snapshot.make,
      snapshot.model,
      listing?.make,
      listing?.model,
    );
    final year = listing?.year ?? snapshot.year;
    final price = listing != null
        ? fmt.formatPriceFromListing(listing)
        : fmt.formatPriceFromSnapshot(snapshot);
    final location = slot.phase == CompareSlotPhase.unavailable
        ? null
        : fmt.formatCityRegion(slot);

    final isMuted =
        slot.phase == CompareSlotPhase.unavailable ||
        slot.phase == CompareSlotPhase.inactive;
    final statusLabel = switch (slot.phase) {
      CompareSlotPhase.unavailable => l10n.compareUnavailableListing,
      CompareSlotPhase.inactive => l10n.compareInactiveListing,
      _ => null,
    };

    final decoration = light
        ? BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isMuted ? 0.24 : 0.34,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.26),
            ),
          )
        : AppTheme.editorialDarkCompareVehicleCard(scheme, muted: isMuted)!;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: decoration,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: light
                                ? scheme.outlineVariant.withValues(alpha: 0.2)
                                : scheme.outline.withValues(alpha: 0.28),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 11,
                          child: ListingCoverImage(
                            imageUrl:
                                listing?.coverImageUrl ??
                                snapshot.coverImageUrl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (title != null)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: scheme.onSurface.withValues(
                            alpha: light ? 1 : 0.98,
                          ),
                        ),
                      ),
                    if (year != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        year.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: light ? 1 : 0.78,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                        color: scheme.onSurface.withValues(
                          alpha: light ? 1 : 0.98,
                        ),
                      ),
                    ),
                    if (location != null &&
                        location != CompareSpecFormatters.missing) ...[
                      const SizedBox(height: 8),
                      Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: light ? 1 : 0.76,
                          ),
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (statusLabel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: light
                              ? scheme.surface.withValues(alpha: 0.7)
                              : Color.alphaBlend(
                                  scheme.primary.withValues(alpha: 0.06),
                                  scheme.surfaceContainerHigh,
                                ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: light ? 0.2 : 0.24,
                            ),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: light ? 0.85 : 0.82,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: l10n.compareRemoveVehicle,
                  child: Material(
                    color: light
                        ? scheme.surface.withValues(alpha: 0.86)
                        : Color.alphaBlend(
                            scheme.surfaceContainerHigh.withValues(alpha: 0.92),
                            scheme.surface,
                          ),
                    elevation: light ? 0 : 2,
                    shadowColor: scheme.shadow.withValues(alpha: 0.25),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: light ? 1 : 0.88,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (slot.phase == CompareSlotPhase.loading)
                Positioned.fill(
                  child: ColoredBox(
                    color: scheme.surface.withValues(
                      alpha: light ? 0.55 : 0.62,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.editorialAccentColor(scheme),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _title(
    String? snapMake,
    String? snapModel,
    String? listMake,
    String? listModel,
  ) {
    final make = (listMake ?? snapMake)?.trim();
    final model = (listModel ?? snapModel)?.trim();
    if (make != null && make.isNotEmpty && model != null && model.isNotEmpty) {
      return '$make $model';
    }
    if (make != null && make.isNotEmpty) return make;
    if (model != null && model.isNotEmpty) return model;
    return null;
  }
}
