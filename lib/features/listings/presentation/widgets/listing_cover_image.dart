import 'package:flutter/material.dart';

/// Builds the hero tag used to connect a listing card's cover image to
/// the listing details cover image across the push transition. Exposed
/// as a free function so tests and both endpoints derive the exact
/// same tag from a listing id.
String listingCoverHeroTag(String listingId) => 'listing-cover-$listingId';

/// Corner radius used on the card-side cover image (rounded top,
/// square bottom so the card's info panel can overlap cleanly). The
/// cover-image Hero interpolates between this radius (source) and a
/// sharp full-bleed destination in the listing-details hero section
/// so the photo's corners don't "pop" at flight start.
const double _listingCardImageRadius = 20;

/// Shared [Hero.flightShuttleBuilder] used by every [ListingCoverImage]
/// on both ends of the card→details transition. We always fly the
/// destination Hero's child (same as the default shuttle) but wrap it
/// in an animated [ClipRRect] whose top corners interpolate from the
/// card's 20 px rounding to the details hero's 0 px rounding. This
/// removes the visible corner "pop" that happens when the source's
/// parent [ClipRRect] stops applying to the shuttle the moment the
/// flight begins.
Widget _listingCoverFlightShuttleBuilder(
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
      // `animation.value` runs 0 → 1 regardless of direction (Hero
      // wires the same animation to both push and pop flights). So
      // radius = (1 - t) * source on push starts at 20 and ends at 0,
      // and on pop goes 0 → 20 — which is exactly what we want for
      // both directions.
      final t = animation.value;
      final radius = (1 - t) * _listingCardImageRadius;
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
/// expected (see [listingCoverHeroTag]).
class ListingCoverImage extends StatelessWidget {
  const ListingCoverImage({super.key, required this.imageUrl, this.heroTag});

  final String? imageUrl;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final child = (url == null || url.isEmpty)
        ? const _CoverPlaceholder()
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _CoverPlaceholder(),
            // Cinematic load-in: render a clean tonal placeholder
            // (no spinner, no progress noise) while bytes decode,
            // then fade the decoded frame in over 180 ms. If Flutter
            // ever returns the bitmap synchronously (cache hit), we
            // skip the animation entirely so cached frames appear
            // instant.
            frameBuilder: (context, image, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return image;
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: frame == null ? const _CoverLoading() : image,
              );
            },
          );
    final tag = heroTag;
    if (tag == null) return child;
    return Hero(
      tag: tag,
      flightShuttleBuilder: _listingCoverFlightShuttleBuilder,
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
/// Deliberately spinner-less — a soft diagonal gradient between the
/// theme's `surfaceContainerHigh` and `surfaceContainerHighest`
/// reads as "image loading" without adding motion noise. The loaded
/// frame fades over this surface via the `frameBuilder` above, so
/// the visual transition is one smooth crossfade instead of a
/// spinner pop.
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
