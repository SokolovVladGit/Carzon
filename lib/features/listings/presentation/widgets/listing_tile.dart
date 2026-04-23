import 'package:flutter/material.dart';

import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_formatters.dart';

class ListingTile extends StatelessWidget {
  const ListingTile({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.directions_car)),
      title: Text('${listing.make} ${listing.model} (${listing.year})'),
      subtitle: Text('${listing.city} • ${formatKm(listing.mileageKm)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatEur(listing.priceEur),
            style: theme.textTheme.titleMedium,
          ),
          FavoriteToggleButton(listingId: listing.id),
        ],
      ),
    );
  }
}
