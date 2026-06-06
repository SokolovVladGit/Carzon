import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../bloc/listings_state.dart';
import '../utils/discovery_feed_chip_labels.dart';

class ListingsActiveDiscoverySummaryStrip extends StatelessWidget {
  const ListingsActiveDiscoverySummaryStrip({super.key, required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = listingsDiscoveryChips(state, l10n);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: l10n.filtersTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == chips.length - 1 ? 0 : 8,
                  ),
                  child: _ActiveDiscoveryChip(data: chips[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDiscoveryChip extends StatelessWidget {
  const _ActiveDiscoveryChip({required this.data});

  final ListingsDiscoveryChip data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fill = isDark
        ? scheme.surfaceContainerHigh
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.025),
            scheme.surface,
          );
    final stroke = scheme.outline.withValues(alpha: isDark ? 0.32 : 0.32);

    final valueStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.94 : 0.92),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05,
      height: 1.1,
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.82 : 0.52),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.08,
      height: 1.1,
    );
    final dotStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.55 : 0.32),
      fontWeight: FontWeight.w500,
      height: 1.1,
    );

    final hasLabel = data.label != null && data.label!.isNotEmpty;

    return Semantics(
      label: data.flat,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: stroke, width: 1),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLabel) ...[
                Text(data.label!, style: labelStyle, maxLines: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·', style: dotStyle),
                ),
              ],
              Flexible(
                child: Text(
                  data.value,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
