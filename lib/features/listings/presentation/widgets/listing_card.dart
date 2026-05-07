import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_formatters.dart';
import 'listing_cover_image.dart';

/// Visual rhythm for a [ListingCard].
///
///   * [regular] — the default feed/grid variant: 16:9 cover with a
///     light info panel overlapping the image's bottom edge.
///   * [featured] — the "feature listing" variant used for the first
///     card of the home feed: taller 4:3 cover, slightly larger price
///     type in the panel, and region/type badges intentionally
///     dropped so the image drives the hierarchy.
enum ListingCardVariant { regular, featured }

/// Visual listing card shared by the public feed, favorites, and
/// My Listings surfaces. Renders a single [Listing] as a modern,
/// marketplace-style card:
///
///   * a big rounded cover image (16:9 regular, 4:3 featured) wrapped
///     in a [Hero] so feed → details transitions animate the photo,
///   * a light rounded info panel that **overlaps the bottom of the
///     image** and carries price, title (make + model), a muted meta
///     row (mileage · year · city), and — on the right — the
///     context-specific action (favorite toggle on public/favorites,
///     owner overflow menu on My Listings),
///   * optional region/type/status badges below the meta row on the
///     regular variant.
///
/// A [trailing] slot is exposed so callers can attach context-specific
/// actions without the card needing to know about either. The slot is
/// rendered **inside** the info panel on the right side — no overlay
/// chip on the image.
class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.trailing,
    this.statusBadge,
    this.variant = ListingCardVariant.regular,
    this.coverParallax,
  });

  final Listing listing;
  final VoidCallback? onTap;

  /// Optional listenable feed-scroll offset (pixels) used to drive a
  /// subtle parallax on the cover image. When provided the cover
  /// translates vertically by `offset * 0.15`, creating the "image
  /// moves slower than scroll" effect used on the first (featured)
  /// card of the home feed. Only the image `Stack` rebuilds on
  /// scroll — the info panel (including its backdrop blur) is NOT
  /// inside the [AnimatedBuilder] subtree, so the expensive glass
  /// layer stays stable.
  ///
  /// Null for regular cards, so no scroll listener overhead is
  /// incurred on the rest of the feed.
  final ValueListenable<double>? coverParallax;

  /// Optional widget rendered inside the info panel on the right side.
  /// Used for the favorite toggle on public cards and for the owner
  /// overflow menu on My Listings.
  final Widget? trailing;

  /// Optional status badge rendered in the badges row. Owner-facing
  /// surfaces (My Listings) pass a status pill; public surfaces leave
  /// this null because active-only filtering is already enforced at
  /// the query layer.
  final Widget? statusBadge;

  /// Visual rhythm of the card. See [ListingCardVariant].
  final ListingCardVariant variant;

  /// Corner radius system for the card.
  ///
  /// Featured hero cards use a deliberately **smaller** radius (16 /
  /// 14) than regular cards (20 / 18) — the tighter corners feel
  /// more editorial / magazine-like, while the rounder regular card
  /// reads as a softer, friendlier tile. The panel is always one
  /// notch tighter than the image so it visually layers on top of
  /// the photo.
  static double _imageRadiusFor(bool featured) => featured ? 16 : 20;
  static double _panelRadiusFor(bool featured) => featured ? 14 : 18;

  /// How far the info panel pushes up into the image's bottom edge.
  ///
  /// The image's bottom corners are square (see the ClipRRect below),
  /// so the overlap no longer needs to be ≥ image radius to hide a
  /// curved cutout. A compact 12 px overlap keeps the panel visually
  /// attached to the image while preserving the lower part of the
  /// cover — important for cars framed low in the photo (plates,
  /// wheels, stance).
  static const double _overlap = 12;

  /// Horizontal inset of the info panel from the card edges.
  ///
  /// `0` — the panel matches the image width exactly so its left and
  /// right edges align with the photo's edges. The depth illusion is
  /// carried entirely by the vertical overlap, the panel shadow, and
  /// the 0.5 px top highlight; a horizontal gutter would read as a
  /// floating chip instead of a card-wide info surface.
  static const double _panelInset = 0;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  // Subtle press micro-interaction: the card settles slightly on tap
  // down and returns on release / cancel. Scale stays above 0.98 so
  // the effect reads as refined, not bouncy.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final listing = widget.listing;
    final isFeatured = widget.variant == ListingCardVariant.featured;

    final imageRadius = ListingCard._imageRadiusFor(isFeatured);
    final panelRadius = ListingCard._panelRadiusFor(isFeatured);

    final badges = <Widget>[
      if (widget.statusBadge != null) widget.statusBadge!,
      if (!isFeatured)
        ListingBadge(
          label: formatMarketRegion(l10n, listing.marketRegion),
          icon: CarzonIcons.map,
          tone: ListingBadgeTone.neutral,
        ),
      if (!isFeatured && listing.type != ListingType.sale)
        ListingBadge(
          label: formatType(l10n, listing.type),
          icon: CarzonIcons.swap,
          tone: ListingBadgeTone.accent,
        ),
    ];

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        // The card is rendered as two framed surfaces (image + panel);
        // no outer fill or tint needed here.
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(imageRadius),
          onHighlightChanged: (highlighted) {
            if (!mounted) return;
            setState(() => _pressed = highlighted);
          },
          child: _OverlapCardLayout(
            aspectRatio: isFeatured ? 4 / 3 : 16 / 9,
            overlap: ListingCard._overlap,
            horizontalMargin: ListingCard._panelInset,
            children: [
              // Child 0: cover image with Hero tag preserved.
              // A 30 px transparent→black vignette painted over the
              // bottom of the photo separates it from the panel
              // that overlaps into this region. Kept very subtle
              // (α 0.10) so it reads as depth, not a dark overlay.
              _CoverStack(
                imageRadius: imageRadius,
                coverImageUrl: listing.coverImageUrl,
                heroTag: listingCoverHeroTag(listing.id),
                parallax: widget.coverParallax,
              ),
              // Child 1: info panel that overlaps the image's bottom.
              _InfoPanel(
                priceLabel: formatListingPriceFromListing(listing),
                titleLabel: '${listing.make} ${listing.model}',
                brandIconAsset: getBrandIconPath(listing.make),
                mileageLabel: formatKm(listing.mileageKm),
                yearLabel: listing.year.toString(),
                city: listing.city,
                theme: theme,
                isFeatured: isFeatured,
                badges: badges,
                trailing: widget.trailing,
                radius: panelRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Image layer of the card: cover photo (Hero-wrapped) + cinematic
/// bottom scrim + optional scroll parallax.
///
/// Pulled out of [ListingCard.build] so the parallax [AnimatedBuilder]
/// (when wired) only rebuilds the image subtree on every scroll
/// tick, NOT the glass info panel — keeping the expensive
/// `BackdropFilter` layer stable across scroll frames.
class _CoverStack extends StatelessWidget {
  const _CoverStack({
    required this.imageRadius,
    required this.coverImageUrl,
    required this.heroTag,
    this.parallax,
  });

  final double imageRadius;
  final String? coverImageUrl;
  final Object heroTag;

  /// Optional feed-scroll offset (pixels). When provided drives a
  /// subtle `Transform.translate` so the cover photo "floats" at
  /// ~15 % of the scroll speed. Positive feed scroll → negative
  /// translateY (image drifts up slower than the rest of the
  /// feed). Kept very small (clamped ≤ 24 px) so it reads as
  /// depth, not motion sickness.
  final ValueListenable<double>? parallax;

  /// 3-stop gradient mapping transparent → deep black for a
  /// cinematic fall. Alpha `0x55` ≈ 33 %, landing in the brief's
  /// 30–40 % band. The mid-stop at 0.55 softens the curve so the
  /// transition never reads as a hard band.
  static const LinearGradient _scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.55, 1.0],
    colors: [Color(0x00000000), Color(0x20000000), Color(0x55000000)],
  );

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      fit: StackFit.passthrough,
      children: [
        ListingCoverImage(imageUrl: coverImageUrl, heroTag: heroTag),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // 64 px bottom scrim lands behind the info panel's top
          // edge (the panel overlaps the photo by 12 px) and fades
          // smoothly into the middle third of the image so even
          // photos framed low in the bottom band of the cover read
          // cleanly into the glass.
          height: 64,
          child: IgnorePointer(
            child: DecoratedBox(decoration: BoxDecoration(gradient: _scrim)),
          ),
        ),
      ],
    );

    final clipped = ClipRRect(
      // Top corners rounded to match the card silhouette, bottom
      // corners left square so the info panel's rounded top can
      // overlap without exposing a curved cutout.
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(imageRadius),
        topRight: Radius.circular(imageRadius),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
      child: stack,
    );

    final parallaxSource = parallax;
    if (parallaxSource == null) return clipped;

    // Only the image+scrim `ClipRRect` is inside the AnimatedBuilder
    // subtree. The Hero lives inside `clipped`, so its current
    // render position naturally reflects the parallax transform —
    // exactly what we want when a flight starts from the visually
    // translated image.
    return AnimatedBuilder(
      animation: parallaxSource,
      builder: (context, child) {
        // Clamp so long scrolls don't pull the photo off its frame.
        final raw = parallaxSource.value;
        final dy = -(raw * 0.15).clamp(-24.0, 24.0);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: clipped,
    );
  }
}

/// Visual tone for [ListingBadge]. Kept small and explicit — the card
/// only needs a neutral "meta" style and a colored "accent" style for
/// noteworthy facts (e.g. a listing that accepts exchange).
enum ListingBadgeTone { neutral, accent, status }

/// Small rounded pill used by [ListingCard] for region/type/status.
class ListingBadge extends StatelessWidget {
  const ListingBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = ListingBadgeTone.neutral,
    this.background,
    this.foreground,
  });

  final String label;
  final IconData? icon;
  final ListingBadgeTone tone;

  /// Optional explicit colors, used only by [ListingBadgeTone.status]
  /// callers that want to map a status value to a theme container.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (tone) {
      ListingBadgeTone.neutral => (
        scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
        scheme.onSurface.withValues(alpha: 0.72),
      ),
      ListingBadgeTone.accent => (
        scheme.secondaryContainer.withValues(alpha: isDark ? 0.45 : 0.55),
        scheme.onSecondaryContainer,
      ),
      ListingBadgeTone.status => (
        background ?? scheme.primaryContainer,
        foreground ?? scheme.onPrimaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info panel rendered inside the card, overlapping the image's
/// bottom edge. Carries price, title, meta row, badges, and the
/// optional right-side action slot (favorite toggle or owner menu).
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.priceLabel,
    required this.titleLabel,
    required this.brandIconAsset,
    required this.mileageLabel,
    required this.yearLabel,
    required this.city,
    required this.theme,
    required this.isFeatured,
    required this.badges,
    required this.radius,
    this.trailing,
  });

  final String priceLabel;
  final String titleLabel;

  /// Pre-resolved brand SVG asset path (via [getBrandIconPath]). Always
  /// a valid asset string — callers never need to null-check.
  final String brandIconAsset;

  final String mileageLabel;
  final String yearLabel;
  final String city;
  final ThemeData theme;
  final bool isFeatured;
  final List<Widget> badges;
  final Widget? trailing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Price carries the card's primary signal — full onSurface colour
    // (no alpha dilution), the largest type on the card, weight 800,
    // and tightened `letterSpacing: -0.4` so multi-digit prices read
    // as one condensed number instead of a sparse row of digits.
    // The featured hero gets +2 px size (26 vs 24) so on a hero
    // tile the price visibly dominates the composition. This is
    // deliberately the strongest typographic element on the card.
    final priceStyle =
        (isFeatured
                ? theme.textTheme.headlineSmall
                : theme.textTheme.titleLarge)
            ?.copyWith(
              fontSize: isFeatured ? 26 : 20,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.4,
              height: 1.1,
            );
    // Title sits one step below the price in the hierarchy: medium
    // weight, slightly muted so the price dominates without the title
    // feeling ghosted.
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onSurface.withValues(alpha: 0.88),
      height: 1.2,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.25,
    );

    // Pass 2.2 rebuilds the panel as a premium **glass sheet**:
    //   * light mode: translucent white at α 0.90 over a 12-sigma
    //     backdrop blur — where the panel overlaps the photo's
    //     bottom the underlying image softens into a frosted haze,
    //     selling the "glass over photo" feel promised by the
    //     brief without changing the layout structure,
    //   * dark mode: a lifted container tone at α 0.92 so the
    //     panel still reads as a distinct layer; the backdrop
    //     blur picks up the photo/page beneath for cohesion.
    final panelBg = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.06),
            scheme.surfaceContainerHigh,
          ).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.90);
    // Featured vs. regular differentiation lives in the shadow,
    // not in extra chrome:
    //
    //   * featured — α 0.11, blur 24, y 12: a firm editorial lift
    //     so the hero card visibly "sits forward" on the feed,
    //   * regular  — α 0.04, blur 14, y 6: a soft whisper so the
    //     regular stream reads as a quiet, airy catalogue under
    //     the featured hero.
    //
    // Dark mode leans heavier in both cases so the silhouette
    // bites against deep surfaces.
    final panelShadowColor = isDark
        ? Colors.black.withValues(alpha: isFeatured ? 0.52 : 0.32)
        : Colors.black.withValues(alpha: isFeatured ? 0.11 : 0.04);
    final panelShadowBlur = isFeatured ? 24.0 : 14.0;
    final panelShadowOffset = isFeatured
        ? const Offset(0, 12)
        : const Offset(0, 6);
    // Hairline edge. Light mode uses a faint white specular line
    // (works on glass), dark mode a whisper white edge.
    final panelBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: panelShadowColor,
            blurRadius: panelShadowBlur,
            spreadRadius: 0,
            offset: panelShadowOffset,
          ),
        ],
      ),
      // ClipRRect + BackdropFilter give the panel a real glass
      // effect: whatever is painted below (the photo's bottom
      // edge, the scaffold background) is blurred through the
      // translucent fill. Shadow is kept OUTSIDE the clip so it
      // still casts cleanly below the card.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: panelBorderColor, width: 0.5),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                12,
                trailing != null ? 10 : 14,
                isFeatured ? 16 : 14,
              ),
              // Panel is a 2-column Row:
              //   * left  — dedicated 48 px brand-icon column, vertically
              //             centered against the whole content stack so the
              //             mark reads as a column label rather than a
              //             decoration attached to the top of the text,
              //   * a 1 px white-alpha vertical divider that fades toward
              //             the bottom, stretched to the full content
              //             height via IntrinsicHeight so the soft fade
              //             tracks card density,
              //   * right — the full content stack (price → title → meta →
              //             badges).
              //
              // The trailing slot (favorite toggle / owner menu) lives
              // outside the IntrinsicHeight box: it must stay vertically
              // centered against the content column without being stretched
              // to the column's full height.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Center(
                              child: _BrandIconTile(assetPath: brandIconAsset),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              height: double.infinity,
                              child: Center(
                                child: Container(
                                  width: 1,
                                  // 4 px (was 8) — extends the visible span
                                  // of the divider for a longer, more
                                  // elegant fade while still leaving a small
                                  // breathing gap at the very top / bottom.
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isDark
                                          ? [
                                              Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.30,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              Colors.transparent,
                                            ]
                                          : [
                                              scheme.onSurface.withValues(
                                                alpha: 0.14,
                                              ),
                                              scheme.onSurface.withValues(
                                                alpha: 0.09,
                                              ),
                                              scheme.onSurface.withValues(
                                                alpha: 0.04,
                                              ),
                                              Colors.transparent,
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  priceLabel,
                                  style: priceStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  titleLabel,
                                  style: titleStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                DefaultTextStyle.merge(
                                  style: metaStyle ?? const TextStyle(),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          mileageLabel,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _MetaSeparator(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      Text(yearLabel),
                                      _MetaSeparator(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      Flexible(
                                        child: Text(
                                          city,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (badges.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: badges,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    _PanelActionSlot(child: trailing!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand logo rendered next to the title, 26×26, with **no** tile,
/// background, or border — the mark sits directly on the panel so
/// the logo silhouette carries the hierarchy.
///
/// The asset path is pre-resolved by [getBrandIconPath], which is
/// total (unknown / empty input returns the neutral `default.svg`).
/// When that fallback path is detected the widget draws a generic
/// `Icons.directions_car` glyph instead of the neutral SVG so the
/// card reads as "unknown brand" rather than "generic car logo".
class _BrandIconTile extends StatelessWidget {
  const _BrandIconTile({required this.assetPath});

  final String assetPath;

  /// Rendered size. 32 px is large enough for the brand silhouette
  /// to read at a glance from the feed while staying subordinate to
  /// the price type on the right.
  static const double _size = 32;

  /// Sentinel suffix used to detect the resolver's neutral fallback.
  /// The resolver is the sole source of truth for this path, so a
  /// suffix match keeps this widget from needing to import an
  /// internal constant.
  static const String _defaultSuffix = '/default.svg';

  /// Neutral metallic fill used ONLY by the unknown-brand fallback
  /// glyph. Real brand SVGs are never tinted — multi-color logos
  /// (e.g. Škoda, BMW, Alfa Romeo) must keep their native palette.
  static const Color _fallbackSilver = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final isUnknown = assetPath.endsWith(_defaultSuffix);

    if (isUnknown) {
      return const Icon(
        Icons.directions_car,
        size: _size,
        color: _fallbackSilver,
      );
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: SvgPicture.asset(
        assetPath,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Small bullet separator used between the mileage/year/city fields
/// in the meta row.
class _MetaSeparator extends StatelessWidget {
  const _MetaSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: color, height: 1.25)),
    );
  }
}

/// Rounded circular slot that hosts the card's right-side action
/// (favorite toggle on public cards, owner overflow menu on My
/// Listings) inside the info panel.
///
/// Pass 2.1 re-skins the slot as a **near-white glass chip** so it
/// visually echoes the glass back/favorite buttons on the details
/// page hero. Over the new white info panel the chip reads as a
/// distinct, slightly translucent affordance with a hairline edge
/// rather than a flat tinted circle.
class _PanelActionSlot extends StatelessWidget {
  const _PanelActionSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Glass recipe — mirrors `_HeroGlassTile` on the details page:
    //   * light mode: near-white @ 0.78 (slightly more opaque than
    //     the panel itself so the chip reads as a distinct surface
    //     *on* the glass), hairline white edge @ 0.60 to sell the
    //     translucent curvature,
    //   * dark mode: white @ 0.12 with a faint specular edge so
    //     the slot stays legible on the dark panel.
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.78);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.60);
    // Subtle lift — keeps the chip legibly "pressable" against the
    // glass panel without reading as a heavy Material button.
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.32)
        : Colors.black.withValues(alpha: 0.08);
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // ClipOval + BackdropFilter match the panel's glass
        // language: the chip picks up and softens whatever sits
        // behind it (the translucent panel + the photo peeking
        // through the overlap region).
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: scheme.onSurface, size: 19),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps a listing status to the badge tone used by the owner-facing
/// card surface. Kept here so callers don't duplicate the status→color
/// decision across `MyListingTile` and any future surface that needs a
/// status pill.
ListingBadge statusListingBadge(
  BuildContext context,
  AppLocalizations l10n,
  ListingStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  final (Color bg, Color fg) = switch (status) {
    ListingStatus.active => (
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    ),
    ListingStatus.hidden => (
      scheme.tertiaryContainer,
      scheme.onTertiaryContainer,
    ),
    ListingStatus.sold => (
      scheme.secondaryContainer,
      scheme.onSecondaryContainer,
    ),
    ListingStatus.archived => (
      scheme.surfaceContainerHighest,
      scheme.onSurfaceVariant,
    ),
  };
  return ListingBadge(
    label: formatStatus(l10n, status),
    tone: ListingBadgeTone.status,
    background: bg,
    foreground: fg,
  );
}

// --------------------------------------------------------------------
// Overlap layout primitive
// --------------------------------------------------------------------
//
// Flutter's stock Column/Stack cannot place the info panel so that it
// overlaps the image bottom *and* reports a total height of
// `imageHeight + panelHeight - overlap` to its parent — Column reports
// the sum of children (ignores Transform.translate), and Stack needs
// an explicit size. A small custom RenderObject keeps the layout
// pixel-exact: the image gets an aspect-ratio-tight slot, the panel
// gets a width-bounded slot, and the overall size is the union.
//
// Children are consumed positionally (image, panel).

class _OverlapCardLayout extends MultiChildRenderObjectWidget {
  const _OverlapCardLayout({
    required this.aspectRatio,
    required this.overlap,
    required this.horizontalMargin,
    required super.children,
  });

  final double aspectRatio;
  final double overlap;
  final double horizontalMargin;

  @override
  _OverlapCardRenderBox createRenderObject(BuildContext context) {
    return _OverlapCardRenderBox(
      aspectRatio: aspectRatio,
      overlap: overlap,
      horizontalMargin: horizontalMargin,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _OverlapCardRenderBox renderObject,
  ) {
    renderObject
      ..aspectRatio = aspectRatio
      ..overlap = overlap
      ..horizontalMargin = horizontalMargin;
  }
}

class _OverlapCardParentData extends ContainerBoxParentData<RenderBox> {}

class _OverlapCardRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _OverlapCardParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _OverlapCardParentData> {
  _OverlapCardRenderBox({
    required double aspectRatio,
    required double overlap,
    required double horizontalMargin,
  }) : _aspectRatio = aspectRatio,
       _overlap = overlap,
       _horizontalMargin = horizontalMargin;

  double _aspectRatio;
  double get aspectRatio => _aspectRatio;
  set aspectRatio(double value) {
    if (value == _aspectRatio) return;
    _aspectRatio = value;
    markNeedsLayout();
  }

  double _overlap;
  double get overlap => _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  double _horizontalMargin;
  double get horizontalMargin => _horizontalMargin;
  set horizontalMargin(double value) {
    if (value == _horizontalMargin) return;
    _horizontalMargin = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverlapCardParentData) {
      child.parentData = _OverlapCardParentData();
    }
  }

  @override
  void performLayout() {
    final image = firstChild;
    assert(image != null, 'ListingCard expects an image child.');
    final panel = childAfter(image!);
    assert(panel != null, 'ListingCard expects a panel child.');

    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : constraints.constrainWidth(0);
    final imageHeight = width / _aspectRatio;

    image.layout(
      BoxConstraints.tightFor(width: width, height: imageHeight),
      parentUsesSize: true,
    );
    final panelWidth = (width - _horizontalMargin * 2).clamp(0.0, width);
    panel!.layout(
      BoxConstraints(minWidth: panelWidth, maxWidth: panelWidth),
      parentUsesSize: true,
    );

    final imageParentData = image.parentData! as _OverlapCardParentData;
    imageParentData.offset = Offset.zero;
    final panelParentData = panel.parentData! as _OverlapCardParentData;
    panelParentData.offset = Offset(_horizontalMargin, imageHeight - _overlap);

    final totalHeight = imageHeight - _overlap + panel.size.height;
    size = constraints.constrain(Size(width, totalHeight));
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    final image = firstChild;
    final panel = image == null ? null : childAfter(image);
    return (image?.getMaxIntrinsicWidth(double.infinity) ?? 0)
        .clamp(
          panel?.getMaxIntrinsicWidth(double.infinity) ?? 0,
          double.infinity,
        )
        .toDouble();
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (width == 0 || !width.isFinite) return 0;
    final imageHeight = width / _aspectRatio;
    final panel = firstChild == null ? null : childAfter(firstChild!);
    final panelHeight =
        panel?.getMaxIntrinsicHeight(width - _horizontalMargin * 2) ?? 0;
    return imageHeight - _overlap + panelHeight;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    // Best-effort dry size: reproduces performLayout sizing without
    // actually laying out the panel child's width, so callers that do
    // intrinsic sizing get a sensible answer.
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : constraints.constrainWidth(0);
    if (width == 0) return constraints.constrain(Size.zero);
    final imageHeight = width / _aspectRatio;
    final panel = firstChild == null ? null : childAfter(firstChild!);
    final panelWidth = (width - _horizontalMargin * 2).clamp(0.0, width);
    final panelSize =
        panel?.getDryLayout(
          BoxConstraints(minWidth: panelWidth, maxWidth: panelWidth),
        ) ??
        Size.zero;
    return constraints.constrain(
      Size(width, imageHeight - _overlap + panelSize.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Default: paint children in order (image first, panel second) so
    // the panel draws on top of the image.
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Hit-test in reverse order so the panel (and its trailing action)
    // wins over the image when the user taps within the overlapping
    // region.
    return defaultHitTestChildren(result, position: position);
  }
}
