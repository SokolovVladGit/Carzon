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

/// Vertical clearance (in logical pixels) that the floating capsule
/// nav occupies above the system bottom safe area.
///
/// Consists of:
///   * 64 px capsule height,
///   * 6 px padding above the capsule,
///   * 12 px minimum SafeArea bottom (when the device reports no
///     system home-indicator padding),
///   * ~14 px of breathing room so the last scrollable item lands
///     clearly above the capsule's shadow edge.
///
/// Pages wrapped in [TopLevelScaffold] render with `extendBody: true`,
/// so scrollables visually continue behind the pill. They must add
/// this constant to their bottom scroll padding so the last row is
/// not obscured by the floating nav.
const double kFloatingCapsuleNavClearance = 96.0;

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

    // Pass 2.0 flattens the capsule to a single premium white
    // surface, relying on the shadow (not a grey fill) to separate
    // it from the page. Dark mode keeps a lifted container tone so
    // the silhouette stays readable against deep surfaces.
    final capsuleBg = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.04),
            scheme.surfaceContainerHighest,
          )
        : Colors.white;
    // Hairline border — enough to bite the edge when the capsule
    // sits over a near-white page, but never a visible grey line.
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : scheme.outlineVariant.withValues(alpha: 0.18);

    const capsuleHeight = 64.0;
    // 32 lands mid-range of the premium floating-pill target band
    // (30–34); the resulting geometry reads as a deliberate
    // rounded rectangle, not a stadium.
    const radius = 32.0;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // Heavier, wider drop shadow sells the "floating" feel
            // against the pure-white feed background. Dark mode
            // still leans on a darker alpha for contrast over deep
            // surfaces.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 12),
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

    // Pass 1.9: the active tab now reads primarily through color —
    // the icon shifts to `primary` and earns a whisper primary pill
    // behind it. Inactive icons stay readable (not ghosted) but
    // clearly secondary, at ~0.55 onSurfaceVariant opacity.
    final activeIconColor = scheme.primary;
    final inactiveIconColor = scheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.62 : 0.55,
    );
    final iconColor = widget.selected ? activeIconColor : inactiveIconColor;

    final pillColor = widget.selected
        ? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10)
        : Colors.transparent;

    // Pass 2.0 bumps the selected icon +1 px so the active tab
    // reads stronger without turning the capsule into a FAB; the
    // emphasized "Sell" destination still gains another +2 px on
    // top of that.
    final iconSize = widget.destination.isEmphasized
        ? (widget.selected ? 25.0 : 24.0)
        : (widget.selected ? 23.0 : 22.0);

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
                // 44×44 rounded-square highlight (radius 14) —
                // lands in the 42–46 target for the active tab's
                // soft pill and pairs visually with the brand-row
                // tiles used elsewhere on the feed.
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(14),
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
