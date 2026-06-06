import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../compare/presentation/widgets/compare_toggle_button.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import 'listing_cover_image.dart';
import 'listing_details_fullscreen_gallery.dart';

/// Horizontal gutter for the hero top controls. Mirrors the page's
/// below-hero content gutter so the glass tiles align to the same edge.
const double _heroHPadding = 20;

Iterable<Widget>? _spreadOptionalTrailing(Widget? w) =>
    w == null ? null : <Widget>[w];

/// Full-bleed hero carousel for the listing details screen: an ordered
/// gallery `PageView` (with the listing-cover `Hero` on the first slide),
/// page dots, a light scrim, and the top control row (back / compare /
/// favorite).
///
/// Behavior, layout, and visuals are unchanged from the previous
/// same-library `part`; all inputs are passed explicitly.
class ListingHeroCarousel extends StatefulWidget {
  const ListingHeroCarousel({
    super.key,
    required this.listingId,
    this.listing,
    required this.urls,
    required this.heroFlightSourceTopRadius,
    this.flySourceKey,
    this.compareFlyFallbackKey,
    required this.onPageChanged,
  });

  final String listingId;
  final Listing? listing;
  final List<String> urls;
  final double heroFlightSourceTopRadius;
  final GlobalKey? flySourceKey;
  final GlobalKey? compareFlyFallbackKey;
  final ValueChanged<int> onPageChanged;

  @override
  State<ListingHeroCarousel> createState() => _ListingHeroCarouselState();
}

class _ListingHeroCarouselState extends State<ListingHeroCarousel> {
  late PageController _pageController = PageController(initialPage: 0);
  int _pageIndexVisual = 0;

  @override
  void didUpdateWidget(covariant ListingHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _pageController.dispose();
      _pageController = PageController(initialPage: 0);
      _pageIndexVisual = 0;
      return;
    }
    if (listEquals(widget.urls, oldWidget.urls)) return;
    final len = widget.urls.length;
    if (len == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      final maxIndex = len - 1;
      final raw = (_pageController.page ?? _pageIndexVisual.toDouble()).round();
      if (raw > maxIndex || raw < 0) {
        _pageController.jumpToPage(0);
        setState(() => _pageIndexVisual = 0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _heroStack({required Widget backdrop, Widget? pageDots}) {
    final stack = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          backdrop,
          const _HeroScrim(),
          ...?_spreadOptionalTrailing(pageDots),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _HeroTopControls(
                listingId: widget.listingId,
                listing: widget.listing,
                flySourceKey: widget.flySourceKey,
                compareFlyFallbackKey: widget.compareFlyFallbackKey,
              ),
            ),
          ),
        ],
      ),
    );
    final key = widget.flySourceKey;
    if (key == null) return stack;
    return KeyedSubtree(key: key, child: stack);
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final tag = listingCoverHeroTag(widget.listingId);
    final rHero = widget.heroFlightSourceTopRadius;

    if (urls.isEmpty) {
      return _heroStack(
        backdrop: ListingCoverImage(
          imageUrl: null,
          heroTag: tag,
          heroFlightSourceTopRadius: rHero,
        ),
      );
    }

    final pageDots = urls.length > 1
        ? Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active =
                      i == _pageIndexVisual.clamp(0, urls.length - 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 7 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: active ? 0.95 : 0.35,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: active ? 0.35 : 0.22,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          )
        : null;

    return _heroStack(
      pageDots: pageDots,
      backdrop: PageView.builder(
        controller: _pageController,
        itemCount: urls.length,
        onPageChanged: (i) {
          setState(() => _pageIndexVisual = i);
          widget.onPageChanged(i);
        },
        itemBuilder: (context, i) {
          final pageHeroTag = i == 0
              ? tag
              : listingDetailsGalleryHeroTag(widget.listingId, i);
          return GestureDetector(
            onTap: () => openListingDetailsFullscreenGallery(
              context,
              listingId: widget.listingId,
              urls: urls,
              initialIndex: i,
              heroFlightSourceTopRadius: rHero,
            ),
            behavior: HitTestBehavior.opaque,
            child: ListingCoverImage(
              imageUrl: urls[i],
              heroTag: pageHeroTag,
              heroFlightSourceTopRadius: rHero,
            ),
          );
        },
      ),
    );
  }
}

/// Very light uniform scrim. The glass tiles on the top controls now
/// carry their own readable background, so the scrim only has to
/// cover the rare case of a fully white sky / body panel — it stays
/// nearly invisible over normal photos.
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0x52000000),
                    Color(0x00000000),
                    Color(0x38000000),
                  ]
                : const [Color(0x1F000000), Color(0x00000000)],
            stops: isDark ? const [0.0, 0.45, 1.0] : const [0.0, 0.35],
          ),
        ),
      ),
    );
  }
}

/// Top chrome on the hero: matching glass tiles on the left (back)
/// and right (favorite). Aligned to the page's horizontal gutter and
/// pulled tight to the safe-area top so the tiles feel anchored to
/// the corners of the image, not floating in its middle.
class _HeroTopControls extends StatelessWidget {
  const _HeroTopControls({
    required this.listingId,
    this.listing,
    this.flySourceKey,
    this.compareFlyFallbackKey,
  });

  final String listingId;
  final Listing? listing;
  final GlobalKey? flySourceKey;
  final GlobalKey? compareFlyFallbackKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_heroHPadding, 0, _heroHPadding, 0),
      child: Row(
        children: [
          _HeroGlassTile(
            child: const AppBackButton(fallback: AppRoutes.listings),
          ),
          const Spacer(),
          if (listing != null) ...[
            _HeroGlassTile(
              child: CompareToggleButton.fromListing(
                listing!,
                density: CompareToggleDensity.hero,
                flySourceKey: flySourceKey,
                flySourceFallbackKey: compareFlyFallbackKey,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _HeroGlassTile(child: FavoriteToggleButton(listingId: listingId)),
        ],
      ),
    );
  }
}

/// Premium glass tile used for every hero-image overlay control.
///
/// Visual recipe:
///   * 40×40 rounded square, radius 12,
///   * light mode: translucent white fill (~72%) and hairline white border
///     so the icon reads over any photo without looking pasted-on,
///   * dark mode: frosted `surface` fill + `outline` border (no harsh white tile),
///   * backdrop blur behind the fill so the photo is softened,
///     which is the detail that makes it feel like glass,
///   * low-opacity elevation shadow for a subtle lift,
///   * `onSurface` icon theme at 20 px.
///
/// Forwards all pointer events to the hosted [child], so the
/// `AppBackButton` / `FavoriteToggleButton` logic (pop, fallback,
/// auth gating, toggle, pending state) stays intact. The hosted
/// `IconButton` is stripped of its 48 px minimum via a local
/// `IconButtonTheme` so its tap target fits the 40 px tile cleanly.
class _HeroGlassTile extends StatelessWidget {
  const _HeroGlassTile({required this.child});

  final Widget child;

  static const double _size = 40;
  static const double _radius = 12;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.94)
        : scheme.onSurface;
    final fillColor = isDark ? null : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.55);
    final shadowColor = isDark
        ? scheme.primary.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.18);
    final darkFill = isDark
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor, width: 0.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.surfaceContainerHigh.withValues(alpha: 0.90),
                ),
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.surfaceContainerLow.withValues(alpha: 0.88),
                ),
              ],
            ),
          )
        : null;

    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isDark ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration:
                  darkFill ??
                  BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
              alignment: Alignment.center,
              child: IconTheme.merge(
                data: IconThemeData(color: iconColor, size: _iconSize),
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(_size, _size),
                      maximumSize: const Size(_size, _size),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
