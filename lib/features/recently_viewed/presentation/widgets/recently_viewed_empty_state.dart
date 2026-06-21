import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';

/// Empty recently viewed history (0 listings).
class RecentlyViewedEmptyState extends StatelessWidget {
  const RecentlyViewedEmptyState({super.key, required this.onBrowseListings});

  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: _emptyCardDecoration(scheme, light),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.recentlyViewedEmptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.recentlyViewedEmptyBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onBrowseListings,
                    child: Text(l10n.recentlyViewedBrowseListings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _emptyCardDecoration(ColorScheme scheme, bool light) {
    return BoxDecoration(
      color: light
          ? Colors.white.withValues(alpha: 0.88)
          : scheme.surfaceContainerHigh.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: light ? 0.42 : 0.30),
      ),
      boxShadow: light
          ? [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
          : const [],
    );
  }
}
