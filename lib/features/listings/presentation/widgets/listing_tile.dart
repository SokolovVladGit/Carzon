import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import 'listing_card.dart';

/// Public/favorites feed tile.
///
/// Thin wrapper around [ListingCard] that wires the favorite toggle as
/// the card's overlay action. Kept as a separate widget so the public
/// feed and favorites page don't need to know about the card's
/// internals or the favorite toggle's slot.
class ListingTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListingCard(
      listing: listing,
      onTap: onTap,
      trailing: FavoriteToggleButton(listingId: listing.id),
      variant: variant,
      coverParallax: coverParallax,
    );
  }
}
