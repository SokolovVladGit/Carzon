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

/// Tappable location row inside the vehicle-data card.
class CreateListingCompactSummary extends StatelessWidget {
  const CreateListingCompactSummary({
    super.key,
    required this.primary,
    this.secondary,
    this.icon,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.tapKey,
    this.expanded = false,
  });

  final String primary;
  final String? secondary;
  final IconData? icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Key? tapKey;

  /// Inline editors are open under this row.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final light = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DecoratedBox(
        key: const ValueKey('create_listing_location_surface'),
        decoration: createListingFactSurfaceDecoration(theme),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: tapKey,
            borderRadius: BorderRadius.circular(kCreateListingFactRadius),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    CreateListingFactIconChip(icon: icon!),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Semantics(
                      container: true,
                      button: onPressed != null,
                      enabled: enabled,
                      label: [?label, primary, ?secondary].join('. '),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (label != null)
                              Text(
                                label!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurface.withValues(
                                    alpha: light ? 0.52 : 0.66,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                              ),
                            if (label != null) const SizedBox(height: 4),
                            Text(
                              primary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: -0.2,
                                height: 1.15,
                                color: cs.onSurface.withValues(
                                  alpha: light ? 1 : 0.98,
                                ),
                              ),
                            ),
                            if (secondary != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                secondary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(
                                    alpha: light ? 0.48 : 0.60,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      expanded
                          ? kCreateListingIconChevronUp
                          : kCreateListingIconChevronDown,
                      size: kCreateListingChevronSize,
                      color: cs.onSurface.withValues(
                        alpha: light ? 0.62 : 0.74,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
