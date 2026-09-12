import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'create_listing_compose_layout.dart';

String? createListingContactChannelsSummary({
  required AppLocalizations l10n,
  required bool hasTelegram,
  required bool whatsappEnabled,
}) {
  final parts = [
    if (hasTelegram) l10n.contactTelegram,
    if (whatsappEnabled) l10n.createListingWhatsAppTitle,
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// Calm location/contact summary used after valid current values exist.
class CreateListingCompactSummary extends StatelessWidget {
  const CreateListingCompactSummary({
    super.key,
    required this.primary,
    required this.changeLabel,
    required this.onChange,
    this.secondary,
    this.changeKey,
  });

  final String primary;
  final String? secondary;
  final String changeLabel;
  final VoidCallback onChange;
  final Key? changeKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.2,
      fontSize: 18,
      color: cs.onSurface.withValues(alpha: light ? 0.94 : 0.96),
    );
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: light ? 0.58 : 0.68),
      height: 1.3,
    );

    return DecoratedBox(
      decoration: createListingIdentityCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: [primary, ?secondary].join('. '),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(primary, style: titleStyle),
                        if (secondary != null) ...[
                          const SizedBox(height: 3),
                          Text(secondary!, style: secondaryStyle),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CreateListingSecondaryAction(
              key: changeKey,
              label: changeLabel,
              onPressed: onChange,
            ),
          ],
        ),
      ),
    );
  }
}
