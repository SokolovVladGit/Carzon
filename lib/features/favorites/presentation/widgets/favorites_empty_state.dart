import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/empty_state_view.dart';

/// Empty-state surface rendered when the signed-in user has no
/// favorite listings yet.
///
/// Wraps an [EmptyStateView] inside a `RefreshIndicator`-compatible
/// scrollable so the user can still pull-to-refresh to pick up
/// newly-favorited items. Exposes a primary "browse listings" action
/// that the caller wires up to router navigation.
class FavoritesEmptyState extends StatelessWidget {
  const FavoritesEmptyState({
    super.key,
    required this.onRefresh,
    required this.onBrowseListings,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyStateView(
                icon: Icons.favorite_border,
                title: l10n.favoritesEmptyTitle,
                body: l10n.favoritesEmptyBody,
                primaryAction: EmptyStateAction(
                  label: l10n.favoritesEmptyBrowse,
                  onPressed: onBrowseListings,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
