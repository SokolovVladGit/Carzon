import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_view_stats.dart';
import '../utils/listing_details_metadata.dart';

/// Compact metadata chips for listing details: views, optional today, added date.
class ListingDetailsMetadataChips extends StatelessWidget {
  const ListingDetailsMetadataChips({
    super.key,
    required this.l10n,
    required this.listing,
    this.viewStats,
  });

  final AppLocalizations l10n;
  final Listing listing;
  final ListingViewStats? viewStats;

  static const double _chipSpacing = 7;
  static const double _runSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final totalViews = viewStats?.totalViews ?? listing.viewCount;
    final todayLabel = listingDetailsMetadataTodayLabel(
      l10n,
      todayViews: viewStats?.todayViews,
    );

    return Wrap(
      spacing: _chipSpacing,
      runSpacing: _runSpacing,
      children: [
        _ListingDetailsMetadataChip(
          icon: Icons.visibility_outlined,
          label: listingDetailsMetadataViewsLabel(l10n, totalViews: totalViews),
          variant: _MetadataChipVariant.primary,
        ),
        if (todayLabel != null)
          _ListingDetailsMetadataChip(
            icon: Icons.north_east_rounded,
            label: todayLabel,
            variant: _MetadataChipVariant.accent,
          ),
        _ListingDetailsMetadataChip(
          icon: Icons.calendar_today_outlined,
          label: listingDetailsMetadataAddedDateLabel(
            l10n,
            createdAt: listing.createdAt,
          ),
          variant: _MetadataChipVariant.subtle,
        ),
      ],
    );
  }
}

enum _MetadataChipVariant { primary, accent, subtle }

class _ListingDetailsMetadataChip extends StatelessWidget {
  const _ListingDetailsMetadataChip({
    required this.icon,
    required this.label,
    required this.variant,
  });

  final IconData icon;
  final String label;
  final _MetadataChipVariant variant;

  static const double _iconSize = 14;
  static const double _horizontalPadding = 10;
  static const double _verticalPadding = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accent = light
        ? scheme.primary
        : AppTheme.editorialAccentColor(scheme);

    final (background, border, iconColor, textColor) = switch (variant) {
      _MetadataChipVariant.primary => (
        light
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.58)
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.08),
                scheme.surfaceContainerHigh,
              ),
        light ? null : scheme.outline.withValues(alpha: 0.22),
        scheme.onSurfaceVariant.withValues(alpha: light ? 0.72 : 0.78),
        scheme.onSurface.withValues(alpha: light ? 0.78 : 0.86),
      ),
      _MetadataChipVariant.accent => (
        light
            ? accent.withValues(alpha: 0.1)
            : Color.alphaBlend(
                accent.withValues(alpha: 0.14),
                scheme.surfaceContainerHigh,
              ),
        light ? accent.withValues(alpha: 0.18) : accent.withValues(alpha: 0.28),
        accent.withValues(alpha: light ? 0.82 : 0.9),
        accent.withValues(alpha: light ? 0.92 : 0.96),
      ),
      _MetadataChipVariant.subtle => (
        light
            ? scheme.surfaceContainerLow.withValues(alpha: 0.85)
            : scheme.surfaceContainer.withValues(alpha: 0.55),
        light
            ? scheme.outlineVariant.withValues(alpha: 0.2)
            : scheme.outline.withValues(alpha: 0.16),
        scheme.onSurfaceVariant.withValues(alpha: light ? 0.58 : 0.66),
        scheme.onSurfaceVariant.withValues(alpha: light ? 0.72 : 0.8),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: variant == _MetadataChipVariant.accent
                  ? FontWeight.w700
                  : FontWeight.w600,
              letterSpacing: variant == _MetadataChipVariant.accent
                  ? 0.02
                  : 0.08,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
