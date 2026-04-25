import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
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
  });

  final Listing listing;
  final VoidCallback? onTap;

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

  /// Corner radius system for the card:
  ///   * image: 20 — the largest surface, sets the card silhouette,
  ///   * panel: 18 — one notch tighter than the image so the panel
  ///     reads as a smaller surface layered on top of it,
  ///   * panel action slot: circular (36 px).
  static const double _imageRadius = 20;
  static const double _panelRadius = 18;

  /// How far the info panel pushes up into the image's bottom edge.
  /// At 32 px the panel clearly bites into the image instead of just
  /// touching it — this is what makes the panel read as a separate
  /// "floating" layer rather than a flush footer.
  static const double _overlap = 32;

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

    final badges = <Widget>[
      if (widget.statusBadge != null) widget.statusBadge!,
      if (!isFeatured)
        ListingBadge(
          label: formatMarketRegion(l10n, listing.marketRegion),
          icon: Icons.map_outlined,
          tone: ListingBadgeTone.neutral,
        ),
      if (!isFeatured && listing.type != ListingType.sale)
        ListingBadge(
          label: formatType(l10n, listing.type),
          icon: Icons.swap_horiz,
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
          borderRadius: BorderRadius.circular(ListingCard._imageRadius),
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
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(ListingCard._imageRadius),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    ListingCoverImage(
                      imageUrl: listing.coverImageUrl,
                      heroTag: listingCoverHeroTag(listing.id),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 30,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00000000),
                                Color(0x1A000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Child 1: info panel that overlaps the image's bottom.
              _InfoPanel(
                priceLabel: formatEur(listing.priceEur),
                titleLabel: '${listing.make} ${listing.model}',
                mileageLabel: formatKm(listing.mileageKm),
                yearLabel: listing.year.toString(),
                city: listing.city,
                theme: theme,
                isFeatured: isFeatured,
                badges: badges,
                trailing: widget.trailing,
                radius: ListingCard._panelRadius,
              ),
            ],
          ),
        ),
      ),
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
    // (no alpha dilution) and a slightly larger type size than the
    // Pass 1 spec so it reads from a glance.
    final priceStyle = (isFeatured
            ? theme.textTheme.headlineSmall
            : theme.textTheme.titleLarge)
        ?.copyWith(
      fontSize: isFeatured ? 24 : 20,
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.3,
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

    // Panel must read as a distinct layer hovering above the image:
    //   * light mode: `surfaceContainerHighest` is too cold on its
    //     own — we blend a 5 % primary tint into it to warm the
    //     neutral and lift contrast vs. the scaffold background,
    //   * dark mode: lift `surfaceContainerHigh` one step with a
    //     hint of white so the panel is visibly brighter than the
    //     page background (a flat surfaceContainer* tone in dark
    //     mode reads as the same layer as the image).
    final panelBg = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            scheme.surfaceContainerHigh,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.05),
            scheme.surfaceContainerHighest,
          );
    // Directional shadow — deliberately heavier below the panel
    // than around it so the panel reads as sitting on a real
    // surface above the image (not a modal hovering in free space).
    // The small 0.5 px top highlight creates the "material edge"
    // that sells the lift: in light mode a whisper of white, in
    // dark mode a faint specular line.
    final panelShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.13);
    final panelHighlightColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.50);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: panelHighlightColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: panelShadowColor,
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          12,
          trailing != null ? 10 : 14,
          isFeatured ? 16 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Trailing action reads as a balanced, tappable
              // affordance next to the text block when vertically
              // centered against the price+title+meta column.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceLabel,
                        style: priceStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        titleLabel,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
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
                            _MetaSeparator(color: scheme.onSurfaceVariant),
                            Text(yearLabel),
                            _MetaSeparator(color: scheme.onSurfaceVariant),
                            Flexible(
                              child: Text(
                                city,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  _PanelActionSlot(child: trailing!),
                ],
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: badges,
              ),
            ],
          ],
        ),
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
/// Listings) inside the info panel. Uses soft theme-aware tints so
/// the slot reads as a tappable affordance on the panel surface, not
/// as a glass chip over a photo.
class _PanelActionSlot extends StatelessWidget {
  const _PanelActionSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Slot tint is one contrast step darker / lighter than the panel
    // it sits on, so the circle reads as a tappable affordance at a
    // glance without needing a border.
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.11)
        : Colors.black.withValues(alpha: 0.06);
    // 36 px (not 40) keeps the slot in scale with the text block on
    // its left — a chunkier circle visually crowds a single-line
    // price + title. An IconTheme.merge at size 19 (not 20) gives
    // the icon slightly more breathing room inside the circle.
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: scheme.onSurface, size: 19),
          child: child,
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
  })  : _aspectRatio = aspectRatio,
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
    panelParentData.offset =
        Offset(_horizontalMargin, imageHeight - _overlap);

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
            panel?.getMaxIntrinsicWidth(double.infinity) ?? 0, double.infinity)
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
    final panelSize = panel?.getDryLayout(
          BoxConstraints(minWidth: panelWidth, maxWidth: panelWidth),
        ) ??
        Size.zero;
    return constraints
        .constrain(Size(width, imageHeight - _overlap + panelSize.height));
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
