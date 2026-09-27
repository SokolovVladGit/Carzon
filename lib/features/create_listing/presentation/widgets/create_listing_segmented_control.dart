import 'package:flutter/material.dart';

import 'create_listing_compose_layout.dart';

class CreateListingSegmentOption<T> {
  const CreateListingSegmentOption({
    required this.value,
    required this.label,
    this.key,
  });

  final T value;
  final String label;
  final Key? key;
}

/// Inset track + slightly raised selected thumb. Create-only.
class CreateListingSegmentedControl<T> extends StatelessWidget {
  const CreateListingSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.forceWrap = false,
    this.dense = false,
    this.graphiteActive = false,
  });

  static const rowLayoutKey = ValueKey('create_listing_segment_row');
  static const compactLayoutKey = ValueKey('create_listing_segment_compact');

  final List<CreateListingSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool forceWrap;

  /// Smaller type so three short labels fit one row.
  final bool dense;

  /// Graphite selected fill shared with Scan VIN and the currency chips.
  /// Off for selectors that still use the neutral thumb.
  final bool graphiteActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelSize = dense ? 12.5 : 14.0;
        if (options.length == 3 &&
            (scale > 1.15 || constraints.maxWidth < 280)) {
          return _Shell(
            key: compactLayoutKey,
            theme: theme,
            enabled: enabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  Row(children: [_thumb(context, theme, option, dense: dense)]),
              ],
            ),
          );
        }
        final compactThree =
            options.length == 3 &&
            (forceWrap ||
                scale > 1.25 ||
                !_labelsFitInEqualSlots(
                  labels: [for (final option in options) option.label],
                  maxWidth: constraints.maxWidth,
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        height: 1.1,
                        fontSize: labelSize,
                      ) ??
                      TextStyle(fontSize: labelSize),
                  scaler: MediaQuery.textScalerOf(context),
                  thumbChrome: dense ? 12 : 22,
                  slack: dense ? 4 : 10,
                ));

        if (compactThree) {
          return _Shell(
            key: compactLayoutKey,
            theme: theme,
            enabled: enabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _thumb(context, theme, options[0], dense: dense),
                      _thumb(context, theme, options[1], dense: dense),
                    ],
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _thumb(context, theme, options[2], dense: dense),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _Shell(
          key: rowLayoutKey,
          theme: theme,
          enabled: enabled,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  _thumb(context, theme, option, dense: dense),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(
    BuildContext context,
    ThemeData theme,
    CreateListingSegmentOption<T> option, {
    required bool dense,
  }) {
    final cs = theme.colorScheme;
    final selected = option.value == value;
    final labelColor = graphiteActive
        ? (selected
              ? kCreateListingActiveForeground
              : createListingInactiveSegmentLabel(theme))
        : cs.onSurface.withValues(alpha: selected ? 0.92 : 0.60);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: option.key,
          borderRadius: BorderRadius.circular(kCreateListingSegmentRadius),
          onTap: enabled && !selected ? () => onChanged(option.value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(2),
            constraints: BoxConstraints(minHeight: dense ? 40 : 44),
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 4 : 8,
              vertical: dense ? 6 : 8,
            ),
            decoration: graphiteActive
                ? createListingActiveThumbDecoration(theme, selected: selected)
                : createListingSegmentThumbDecoration(
                    theme,
                    selected: selected,
                  ),
            alignment: Alignment.center,
            child: Text(
              option.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.1,
                fontSize: dense ? 12.5 : 14,
                color: labelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-flex thumbs: every label must fit its equal slot, not just the sum.
bool _labelsFitInEqualSlots({
  required List<String> labels,
  required double maxWidth,
  required TextStyle style,
  required TextScaler scaler,
  double thumbChrome = 22,
  double slack = 10,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0 || labels.isEmpty) {
    return false;
  }
  const trackPad = 4.0;
  final cellWidth = (maxWidth - trackPad) / labels.length;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    if (painter.width + thumbChrome + slack > cellWidth) {
      return false;
    }
  }
  return true;
}

class _Shell extends StatelessWidget {
  const _Shell({
    super.key,
    required this.theme,
    required this.enabled,
    required this.child,
  });

  final ThemeData theme;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: createListingTrackDecoration(theme),
        child: Padding(padding: const EdgeInsets.all(2), child: child),
      ),
    );
  }
}
