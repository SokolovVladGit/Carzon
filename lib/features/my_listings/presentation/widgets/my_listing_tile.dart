import 'package:flutter/material.dart';

import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';

/// Owner-facing tile: same content as the public tile but with a
/// status badge and no favorite toggle (a seller doesn't favorite
/// their own listings).
class MyListingTile extends StatelessWidget {
  const MyListingTile({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.directions_car)),
      title: Text('${listing.make} ${listing.model} (${listing.year})'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _StatusBadge(status: listing.status),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${listing.city} • ${formatKm(listing.mileageKm)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: Text(
        formatEur(listing.priceEur),
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      ListingStatus.active => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ListingStatus.hidden => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ListingStatus.sold => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      ListingStatus.archived => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        formatStatus(status),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
