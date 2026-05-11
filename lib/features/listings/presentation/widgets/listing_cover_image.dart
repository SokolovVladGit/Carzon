import 'package:flutter/material.dart';

/// Builds the hero tag used to connect a listing card's cover image to
/// the listing details cover image across the push transition. Exposed
/// as a free function so tests and both endpoints derive the exact
/// same tag from a listing id.
String listingCoverHeroTag(String listingId) => 'listing-cover-$listingId';

/// Hero tag for carousel slide index `> 0` and the matching fullscreen viewer
/// slide. Slide 0 keeps [listingCoverHeroTag] for feed→details continuity.
String listingDetailsGalleryHeroTag(String listingId, int index) {
  assert(index > 0, 'Use listingCoverHeroTag for carousel index 0');
  return 'listing-gallery-$listingId-$index';
}

/// Corner radius used on the card-side cover image (rounded top,
/// square bottom so the card's info panel can overlap cleanly). The
/// cover-image Hero interpolates between this radius (source) and a
/// sharp full-bleed destination in the listing-details hero section
/// so the photo's corners don't "pop" at flight start.
const double _listingCardImageRadius = 20;

/// [Hero.flightShuttleBuilder] shared by listing cover, details carousel,
/// and fullscreen viewer — interpolates top corners toward a square crop.
HeroFlightShuttleBuilder listingCoverHeroFlightShuttleBuilder(
  double sourceTopRadius,
) {
  return (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final toHero = toHeroContext.widget as Hero;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final radius = (1 - t) * sourceTopRadius;
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          child: child,
        );
      },
      child: toHero.child,
    );
  };
}

/// No opacity tween — avoids stacking an opacity animation on top of the
/// route Hero flight (cold-open blink). Shows tonal loading until the first
/// frame, then the bitmap immediately.
Widget _heroBoundNetworkFrameBuilder(
  BuildContext context,
  Widget imageWidget,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return imageWidget;
  return frame == null ? const _CoverLoading() : imageWidget;
}

/// Card / non-Hero polish: short fade when the first frame arrives.
Widget _cardNetworkFrameBuilder(
  BuildContext context,
  Widget imageWidget,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return imageWidget;
  return AnimatedOpacity(
    opacity: frame == null ? 0.0 : 1.0,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    child: frame == null ? const _CoverLoading() : imageWidget,
  );
}

/// Edge-to-edge cover image used on a [ListingCard] and on the
/// listing details page.
///
/// Renders [imageUrl] when present and loadable, or a clean
/// automotive-styled placeholder when the URL is null, blank, or
/// fails to decode. The placeholder is an offline, theme-aware
/// gradient with a centered car icon — no external image URL is ever
/// referenced as a fallback, satisfying the "no remote/external image
/// URLs" constraint.
///
/// When [heroTag] is provided the rendered image (or placeholder) is
/// wrapped in a [Hero] so feed-to-details navigation animates the
/// cover photo between the two surfaces. A stable, id-based tag is
/// expected (see [listingCoverHeroTag]). Hero-bound network images use
/// [_heroBoundNetworkFrameBuilder] and [Image.gaplessPlayback] so they
/// do not run an extra opacity fade during the transition.
class ListingCoverImage extends StatelessWidget {
  const ListingCoverImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.heroFlightSourceTopRadius,
  });

  final String? imageUrl;
  final Object? heroTag;

  /// Top corner radius on the **feed card** side used only by the Hero
  /// shuttle clip. Defaults to [_listingCardImageRadius] for deep-linked
  /// details opens; passing [ListingCard] radii here fixes featured tiles.
  final double? heroFlightSourceTopRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final heroBound = heroTag != null;
    final child = (url == null || url.isEmpty)
        ? const _CoverPlaceholder()
        : Image.network(
            url,
            fit: BoxFit.cover,
            gaplessPlayback: heroBound,
            errorBuilder: (_, _, _) => const _CoverPlaceholder(),
            frameBuilder: heroBound
                ? _heroBoundNetworkFrameBuilder
                : _cardNetworkFrameBuilder,
          );
    final tag = heroTag;
    if (tag == null) return child;
    final shuttleRadius = heroFlightSourceTopRadius ?? _listingCardImageRadius;
    return Hero(
      tag: tag,
      flightShuttleBuilder: listingCoverHeroFlightShuttleBuilder(shuttleRadius),
      child: child,
    );
  }
}

/// Neutral gradient + car icon used when no cover photo is available.
/// Uses theme surface containers so it reads correctly in both light
/// and dark mode.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Clean tonal surface shown while a cover image decodes.
///
/// Spinner-less — reads as "loading" without motion noise. Non-Hero
/// tiles crossfade via [_cardNetworkFrameBuilder]; Hero-bound tiles
/// switch to the bitmap immediately when the first frame is ready.
class _CoverLoading extends StatelessWidget {
  const _CoverLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest],
        ),
      ),
    );
  }
}
