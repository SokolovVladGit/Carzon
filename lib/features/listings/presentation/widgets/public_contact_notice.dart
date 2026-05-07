import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

/// Small seller-facing notice displayed near contact fields on the
/// create-listing and edit-listing forms.
///
/// Its purpose is awareness, not a security guarantee: Carzon
/// intentionally publishes seller contact details on active listings
/// for MVP, and sellers should be reminded before they submit. This
/// widget does not block submission, does not track consent, and does
/// not claim any anti-scraping protection.
class PublicContactNotice extends StatelessWidget {
  const PublicContactNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final noticeFill = Color.alphaBlend(
      cs.outlineVariant.withValues(alpha: br == Brightness.light ? 0.07 : 0.12),
      cs.surface,
    );
    final fg = cs.onSurfaceVariant;
    final message = l10n.publicContactNotice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: noticeFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CarzonIcons.info, size: 18, color: fg.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg.withValues(alpha: 0.88),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
