import 'package:flutter/material.dart';

import 'official_data_editorial.dart';

/// How [OfficialDataPendingCard.sourceNote] is rendered in the card footer.
enum OfficialDataPendingSourceNoteStyle {
  /// Compact source badge (e.g. EPA · FuelEconomy.gov).
  sourceBadge,

  /// Muted scope/limitation footnote.
  footnote,
}

/// Compact editorial pending card for official-data sections on listing details.
class OfficialDataPendingCard extends StatelessWidget {
  const OfficialDataPendingCard({
    super.key,
    required this.title,
    required this.body,
    this.sourceNote,
    this.sourceNoteStyle = OfficialDataPendingSourceNoteStyle.footnote,
    this.sectionKey,
    this.includeLeadingSpacing = true,
    this.leadingIcon = Icons.hourglass_top_rounded,
    this.statusIcon = Icons.schedule_rounded,
  });

  final String title;
  final String body;
  final String? sourceNote;
  final OfficialDataPendingSourceNoteStyle sourceNoteStyle;
  final Key? sectionKey;
  final bool includeLeadingSpacing;
  final IconData leadingIcon;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: title,
      child: Column(
        key: sectionKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeLeadingSpacing) const SizedBox(height: 24),
          DecoratedBox(
            decoration: officialDataPendingCardDecoration(theme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OfficialDataPendingIconAnchor(
                        theme: theme,
                        icon: leadingIcon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.15,
                                      height: 1.25,
                                      color: scheme.onSurface.withValues(
                                        alpha: isDark ? 0.96 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OfficialDataPendingStatusChip(
                                  theme: theme,
                                  icon: statusIcon,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              body,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: isDark ? 0.86 : 0.92,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (sourceNote != null) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: scheme.outlineVariant.withValues(
                        alpha: isDark ? 0.16 : 0.22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    switch (sourceNoteStyle) {
                      OfficialDataPendingSourceNoteStyle.sourceBadge =>
                        OfficialDataSourceBadge(
                          theme: theme,
                          label: sourceNote!,
                        ),
                      OfficialDataPendingSourceNoteStyle.footnote =>
                        OfficialDataPendingFootnote(
                          theme: theme,
                          text: sourceNote!,
                        ),
                    },
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
