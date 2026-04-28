import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../shared/ui/carzon_icons.dart';

/// Empty-state surface rendered on My Listings when the authenticated
/// user has never published a listing.
///
/// Purely presentation — the caller wires [onCreate] to router
/// navigation (typically to `/create-listing`).
class MyListingsEmptyState extends StatelessWidget {
  const MyListingsEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyStateView(
      icon: CarzonIcons.inventoryEmpty,
      title: l10n.myListingsEmptyTitle,
      body: l10n.myListingsEmptyBody,
      primaryAction: EmptyStateAction(
        label: l10n.myListingsSellCta,
        onPressed: onCreate,
      ),
    );
  }
}
