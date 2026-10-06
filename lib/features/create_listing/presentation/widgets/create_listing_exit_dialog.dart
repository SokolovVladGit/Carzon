import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'create_listing_compose_layout.dart';

/// Confirms leaving Create Listing. `true` leaves, `false` stays.
Future<bool> showCreateListingExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => const CreateListingExitDialog(),
  ).then((value) => value ?? false);
}

class CreateListingExitDialog extends StatelessWidget {
  const CreateListingExitDialog({super.key});

  static const Key dialogKey = ValueKey('create_listing_exit_dialog');
  static const Key stayKey = ValueKey('create_listing_exit_stay');
  static const Key leaveKey = ValueKey('create_listing_exit_leave');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final ink = light ? const Color(0xFF3F3832) : theme.colorScheme.onSurface;

    return AlertDialog(
      key: dialogKey,
      backgroundColor: light ? const Color(0xFFFFFCF8) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        l10n.createListingExitTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.25,
        ),
      ),
      content: Text(
        l10n.createListingExitBody,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: ink.withValues(alpha: light ? 0.72 : 0.8),
          height: 1.35,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          key: leaveKey,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8C5E52),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.createListingExitLeave),
        ),
        FilledButton(
          key: stayKey,
          style: FilledButton.styleFrom(
            backgroundColor: kCreateListingActiveFill,
            foregroundColor: kCreateListingActiveForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.createListingExitStay),
        ),
      ],
    );
  }
}
