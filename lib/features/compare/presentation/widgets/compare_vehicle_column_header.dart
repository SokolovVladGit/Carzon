import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
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
    final snapshot = slot.item.snapshot;
    final listing = slot.listing;
    final fmt = CompareSpecFormatters(l10n);

    final title = _title(snapshot.make, snapshot.model, listing?.make, listing?.model);
    final year = listing?.year ?? snapshot.year;
    final price = listing != null
        ? fmt.formatPriceFromListing(listing)
        : fmt.formatPriceFromSnapshot(snapshot);
    final location = slot.phase == CompareSlotPhase.unavailable
        ? null
        : fmt.formatCityRegion(slot);

    final isMuted = slot.phase == CompareSlotPhase.unavailable ||
        slot.phase == CompareSlotPhase.inactive;
    final statusLabel = switch (slot.phase) {
      CompareSlotPhase.unavailable => l10n.compareUnavailableListing,
      CompareSlotPhase.inactive => l10n.compareInactiveListing,
      _ => null,
    };

    return SizedBox(
      width: width,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isMuted ? 0.28 : 0.42,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ListingCoverImage(
                        imageUrl: listing?.coverImageUrl ?? snapshot.coverImageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (title != null)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  if (year != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      year.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  if (location != null && location != CompareSpecFormatters.missing) ...[
                    const SizedBox(height: 4),
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                  if (statusLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: l10n.compareRemoveVehicle,
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (slot.phase == CompareSlotPhase.loading)
              Positioned.fill(
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.55),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
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
