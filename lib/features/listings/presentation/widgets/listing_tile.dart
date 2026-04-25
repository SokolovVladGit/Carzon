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
  });

  final Listing listing;
  final VoidCallback? onTap;

  /// Visual rhythm of the underlying [ListingCard]. The home feed
  /// passes [ListingCardVariant.featured] for the first tile so it
  /// reads as the main car of the catalogue page.
  final ListingCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return ListingCard(
      listing: listing,
      onTap: onTap,
      trailing: FavoriteToggleButton(listingId: listing.id),
      variant: variant,
    );
  }
}
