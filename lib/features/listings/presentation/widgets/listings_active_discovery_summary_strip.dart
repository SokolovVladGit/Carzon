import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../bloc/listings_state.dart';
import '../utils/discovery_feed_chip_labels.dart';

class ListingsActiveDiscoverySummaryStrip extends StatelessWidget {
  const ListingsActiveDiscoverySummaryStrip({
    super.key,
    required this.state,
    required this.onFilterRemoved,
  });

  final ListingsState state;
  final ValueChanged<ListingsDiscoveryChipKind> onFilterRemoved;

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
                  child: _ActiveDiscoveryChip(
                    data: chips[i],
                    onRemove: () => onFilterRemoved(chips[i].kind),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDiscoveryChip extends StatelessWidget {
  const _ActiveDiscoveryChip({required this.data, required this.onRemove});

  final ListingsDiscoveryChip data;
  final VoidCallback onRemove;

  static const double _radius = 14;
  static const double _closeDiameter = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final restingBg = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final fill = isDark
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.2),
            restingBg,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.11),
            restingBg,
          );
    final stroke = isDark
        ? scheme.primary.withValues(alpha: 0.38)
        : scheme.primary.withValues(alpha: 0.24);

    final valueStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.98 : 0.94),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.01,
      height: 1.15,
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.88 : 0.74),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05,
      height: 1.15,
    );
    final dotStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.62 : 0.48),
      fontWeight: FontWeight.w600,
      height: 1.15,
    );

    final hasLabel = data.label != null && data.label!.isNotEmpty;
    final removeSemantics = '${l10n.listingsDiscoveryFilterRemoveTooltip}: '
        '${data.flat}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: stroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.16 : 0.035),
            blurRadius: isDark ? 10 : 14,
            offset: Offset(0, isDark ? 3 : 4),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: isDark ? 4 : 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: data.flat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasLabel) ...[
                    Text(data.label!, style: labelStyle, maxLines: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
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
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
            ),
            _ChipRemoveButton(
              key: ValueKey<String>(
                'discovery-chip-remove-${data.kind.name}',
              ),
              onPressed: onRemove,
              semanticsLabel: removeSemantics,
              scheme: scheme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRemoveButton extends StatelessWidget {
  const _ChipRemoveButton({
    super.key,
    required this.onPressed,
    required this.semanticsLabel,
    required this.scheme,
    required this.isDark,
  });

  final VoidCallback onPressed;
  final String semanticsLabel;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final wellFill = isDark
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.26),
            scheme.surfaceContainerHighest,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.12),
            scheme.surfaceContainerLow,
          );
    final wellBorder = scheme.primary.withValues(alpha: isDark ? 0.34 : 0.2);
    final iconColor = Color.lerp(
      scheme.primary,
      scheme.onSurface,
      isDark ? 0.28 : 0.38,
    )!.withValues(alpha: isDark ? 0.94 : 0.88);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          label: semanticsLabel,
          child: SizedBox(
            width: _ActiveDiscoveryChip._closeDiameter,
            height: _ActiveDiscoveryChip._closeDiameter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wellFill,
                border: Border.all(color: wellBorder, width: 1),
              ),
              child: Icon(
                CarzonIcons.close,
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
