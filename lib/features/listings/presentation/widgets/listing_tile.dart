import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../compare/presentation/widgets/compare_toggle_button.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import 'listing_card.dart';

/// Public/favorites feed tile.
///
/// Thin wrapper around [ListingCard] that wires compare + favorite toggles
/// as the card's overlay actions.
class ListingTile extends StatefulWidget {
  const ListingTile({
    super.key,
    required this.listing,
    this.onTap,
    this.variant = ListingCardVariant.regular,
    this.coverParallax,
  });

  final Listing listing;
  final VoidCallback? onTap;

  /// Visual rhythm of the underlying [ListingCard]. The home feed
  /// passes [ListingCardVariant.featured] for the first tile so it
  /// reads as the main car of the catalogue page.
  final ListingCardVariant variant;

  /// Optional scroll-offset listenable forwarded to [ListingCard.coverParallax].
  /// Only the home feed's featured tile wires this — other surfaces
  /// (favorites, my listings) pass null so there is zero scroll-tick
  /// rebuild cost anywhere outside the hero tile.
  final ValueListenable<double>? coverParallax;

  @override
  State<ListingTile> createState() => _ListingTileState();
}

class _ListingTileState extends State<ListingTile> {
  final GlobalKey _compareFlySourceKey = GlobalKey(
    debugLabel: 'listing_compare_fly_source',
  );

  @override
  Widget build(BuildContext context) {
    return ListingCard(
      listing: widget.listing,
      onTap: widget.onTap,
      trailingWide: true,
      compareFlySourceKey: _compareFlySourceKey,
      trailing: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompareToggleButton.fromListing(
              widget.listing,
              density: CompareToggleDensity.compact,
              flySourceKey: _compareFlySourceKey,
            ),
            FavoriteToggleButton(listingId: widget.listing.id),
          ],
        ),
      ),
      variant: widget.variant,
      coverParallax: widget.coverParallax,
    );
  }
}
