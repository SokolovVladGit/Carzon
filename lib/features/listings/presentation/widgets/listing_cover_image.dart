import 'package:flutter/material.dart';

/// Builds the hero tag used to connect a listing card's cover image to
/// the listing details cover image across the push transition. Exposed
/// as a free function so tests and both endpoints derive the exact
/// same tag from a listing id.
String listingCoverHeroTag(String listingId) => 'listing-cover-$listingId';

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
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const _CoverLoading();
            },
          );
    final tag = heroTag;
    if (tag == null) return child;
    return Hero(tag: tag, child: child);
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
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
          ],
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

class _CoverLoading extends StatelessWidget {
  const _CoverLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
