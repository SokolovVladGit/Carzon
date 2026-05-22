import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/entities/compare_item.dart';
import 'compare_snapshot_tile.dart';

/// Empty compare set (0 vehicles).
class CompareEmptyState extends StatelessWidget {
  const CompareEmptyState({super.key, required this.onBrowseListings});

  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CompareStateScaffold(
      title: l10n.compareVehiclesTitle,
      body: l10n.compareEmptyBody,
      primaryLabel: l10n.compareGoToListings,
      onPrimary: onBrowseListings,
    );
  }
}

/// One vehicle in compare — need at least two.
class CompareNeedOneMoreState extends StatelessWidget {
  const CompareNeedOneMoreState({
    super.key,
    required this.item,
    required this.onBrowseListings,
  });

  final CompareItem item;
  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CompareStateScaffold(
      title: l10n.compareAddOneMoreTitle,
      body: l10n.compareAddOneMoreBody,
      primaryLabel: l10n.compareGoToListings,
      onPrimary: onBrowseListings,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: CompareSnapshotTile(snapshot: item.snapshot),
      ),
    );
  }
}

class _CompareStateScaffold extends StatelessWidget {
  const _CompareStateScaffold({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.child,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (child != null) child!,
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('compare_browse_listings_button'),
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}
