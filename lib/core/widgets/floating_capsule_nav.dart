import 'package:flutter/material.dart';

/// Destination descriptor consumed by [FloatingCapsuleNav].
///
/// Mirrors the shape of [NavigationDestination] just enough for the
/// capsule nav to render an icon — we deliberately do not reuse
/// `NavigationDestination` so the custom nav doesn't leak Material
/// `NavigationBar` coupling into its call sites. Since the capsule
/// is icon-only, the [label] is used purely for semantics / a11y
/// and for the long-press tooltip.
class CapsuleNavDestination {
  const CapsuleNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isEmphasized = false,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Accessibility label. Not rendered as visible text — the capsule
  /// is icon-only — but surfaced via [Semantics] and a [Tooltip] so
  /// screen readers, long-press hints, and widget tests can still
  /// address each destination by its localized name.
  final String label;

  /// Opt-in subtle emphasis for a central / primary action (e.g. the
  /// "Sell" destination). Translated into a slightly larger icon size;
  /// no loud accent, no FAB — see Pass 1.5 guidelines.
  final bool isEmphasized;
}

/// Premium, label-less floating capsule bottom navigation (Pass 1.5).
///
/// Visual language:
///   * icon-only, so the bar stays quiet under image-rich content;
///   * a short, diffused shadow so the capsule reads as "floating"
///     without looking like Material elevation;
///   * the selected destination earns a soft rounded background
///     highlight in a low-alpha primary tint — no full-color "blast";
///   * an optional [CapsuleNavDestination.isEmphasized] bumps the
///     center/create icon a couple of points so it reads as the
///     primary action without turning into a FAB.
///
/// Accessibility:
///   * every item is wrapped in [Semantics] with its localized [label]
///     and `selected` state, so screen readers announce the full
///     destination name even though no text is visible;
///   * each item is also wrapped in a [Tooltip] so long-press /
///     pointer-hover reveals the name.
class FloatingCapsuleNav extends StatelessWidget {
  const FloatingCapsuleNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<CapsuleNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // The capsule must stay visibly distinct from the scaffold
    // background:
    //   * dark: one step above `surfaceContainerHighest` so the
    //     capsule feels like a lifted dark surface,
    //   * light: `surfaceContainerLow` — a soft warm grey that sits
    //     clearly on top of the warm-white scaffold. Previously this
    //     used `scheme.surface`, but the scaffold *is* now warm
    //     white, so re-using `surface` would make the capsule
    //     disappear into the background.
    final capsuleBg = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.04),
            scheme.surfaceContainerHighest,
          )
        : scheme.surfaceContainerLow;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : scheme.outlineVariant.withValues(alpha: 0.6);

    const capsuleHeight = 60.0;
    const radius = 34.0;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // Soft, diffused shadow — not Material default. Darker
            // and more pronounced in dark mode so the capsule reads
            // as lifted above deep surfaces.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: capsuleBg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: borderColor),
            ),
            child: Stack(
              children: [
                // Subtle top gloss — dark mode only; light mode
                // washes it out and it looks dirty.
                if (isDark)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: capsuleHeight,
                  child: Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _CapsuleNavItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onDestinationSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single tappable destination. Icon-only, with a soft rounded
/// primary-tinted highlight behind the icon when selected. An optional
/// tap scale gives the press a hint of weight without adding motion
/// noise to the bar.
class _CapsuleNavItem extends StatefulWidget {
  const _CapsuleNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final CapsuleNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CapsuleNavItem> createState() => _CapsuleNavItemState();
}

class _CapsuleNavItemState extends State<_CapsuleNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Active icon stays neutral-firm (not a primary-color blast);
    // the colored pill behind it carries the accent.
    final activeIconColor = scheme.onSurface;
    final inactiveIconColor =
        scheme.onSurfaceVariant.withValues(alpha: 0.65);
    final iconColor =
        widget.selected ? activeIconColor : inactiveIconColor;

    final pillColor = widget.selected
        ? scheme.primary.withValues(alpha: isDark ? 0.14 : 0.10)
        : Colors.transparent;

    final iconSize = widget.destination.isEmphasized ? 24.0 : 22.0;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.label,
      container: true,
      child: Tooltip(
        message: widget.destination.label,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (!mounted) return;
            setState(() => _pressed = highlighted);
          },
          customBorder: const StadiumBorder(),
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  widget.selected
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
