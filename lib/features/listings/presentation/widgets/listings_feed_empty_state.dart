import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../shared/ui/carzon_icons.dart';

/// Empty-state surface rendered when the public listings feed query
/// returns zero rows.
///
/// Two copy variants depending on [hasFilters]:
///   * `true`  — search / make / year / type filters are active →
///               prompt the user to adjust or reset filters.
///   * `false` — the section (current region) simply has no active
///               listings.
///
/// Always hosted inside a `RefreshIndicator` so pull-to-refresh keeps
/// working on an empty feed. The inner `SingleChildScrollView` uses
/// `AlwaysScrollableScrollPhysics` so the refresh gesture is armed
/// even when there is no content taller than the viewport.
class ListingsFeedEmptyState extends StatelessWidget {
  const ListingsFeedEmptyState({
    super.key,
    required this.hasFilters,
    required this.onResetFilters,
    required this.onRefresh,
  });

  final bool hasFilters;
  final VoidCallback onResetFilters;
  final Future<void> Function() onRefresh;

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
                icon: CarzonIcons.searchEmpty,
                title: l10n.listingsEmptyTitle,
                body: hasFilters
                    ? l10n.listingsEmptyFilteredBody
                    : l10n.listingsEmptyBody,
                secondaryAction: hasFilters
                    ? EmptyStateAction(
                        label: l10n.listingsEmptyResetFilters,
                        onPressed: onResetFilters,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
