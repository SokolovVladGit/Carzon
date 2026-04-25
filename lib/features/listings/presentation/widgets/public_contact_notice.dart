import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';

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
    final fg = theme.colorScheme.onSurfaceVariant;
    final message = l10n.publicContactNotice;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
