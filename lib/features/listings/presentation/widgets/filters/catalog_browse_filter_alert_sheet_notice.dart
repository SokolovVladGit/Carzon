import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations_x.dart';
import 'catalog_browse_filter_alert_sheet_bell.dart';
import 'catalog_filter_alert_ui_constants.dart';

/// Sheet-local inline notice rendered inside `ListingsFilterHost` when the
/// catalog filter-alert bell publishes a [CatalogBellInlineNotice] payload.
///
/// Replaces the previous root-snackbar path for `criteriaTooBroad`: the
/// modal sheet has no own [ScaffoldMessenger], so any snackbar shown from
/// inside the sheet bled onto the listings page after the user tapped
/// "Show cars". Surfacing the message inline keeps it inside the modal
/// lifecycle and dies with the sheet on dismiss.
///
/// Visual language: compact rounded card with the shared amber accent
/// (matches the bell ornaments) and a neutral info glyph — informational,
/// never red-alarm. Two-line layout (title + body) so the message can be
/// scanned without dominating the header.
class CatalogBrowseFilterAlertSheetNotice extends StatelessWidget {
  const CatalogBrowseFilterAlertSheetNotice({super.key, required this.notice});

  final CatalogBellInlineNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final (title, body) = switch (notice) {
      CatalogBellInlineNotice.criteriaTooBroad => (
          l10n.catalogBrowseFilterAlertTooBroadInlineTitle,
          l10n.catalogBrowseFilterAlertTooBroadInlineBody,
        ),
    };

    final accent = CatalogFilterAlertAccent.amber;
    final fill = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.22 : 0.14),
      scheme.surface,
    );
    final stroke = accent.withValues(alpha: isDark ? 0.55 : 0.42);
    final iconColor = isDark ? accent : accent.withValues(alpha: 0.92);
    final titleColor = scheme.onSurface.withValues(alpha: 0.94);
    final bodyColor = scheme.onSurface.withValues(alpha: 0.66);

    return Semantics(
      liveRegion: true,
      container: true,
      label: '$title $body',
      child: DecoratedBox(
        key: CatalogFilterAlertAccent.sheetTooBroadNoticeKey,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stroke, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
