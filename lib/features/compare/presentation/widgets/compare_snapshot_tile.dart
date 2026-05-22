import 'package:flutter/material.dart';

import '../../../listings/presentation/widgets/listing_cover_image.dart';
import '../../domain/entities/compare_listing_snapshot.dart';

/// Compact read-only row for a stored compare snapshot.
class CompareSnapshotTile extends StatelessWidget {
  const CompareSnapshotTile({super.key, required this.snapshot});

  final CompareListingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = _titleLine();
    final subtitle = _subtitleLine();

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 54,
                child: ListingCoverImage(imageUrl: snapshot.coverImageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _titleLine() {
    final make = snapshot.make?.trim();
    final model = snapshot.model?.trim();
    if (make != null && make.isNotEmpty && model != null && model.isNotEmpty) {
      return '$make $model';
    }
    if (make != null && make.isNotEmpty) return make;
    if (model != null && model.isNotEmpty) return model;
    return null;
  }

  String? _subtitleLine() {
    final parts = <String>[];
    if (snapshot.year != null) parts.add('${snapshot.year}');
    if (snapshot.priceEur != null) {
      parts.add('${snapshot.priceEur!.round()} €');
    }
    if (snapshot.city != null && snapshot.city!.trim().isNotEmpty) {
      parts.add(snapshot.city!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
