import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/seller_public_profile.dart';
import '../utils/format_seller_member_since.dart';
import 'seller_avatar_badge.dart';

/// Compact seller row on listing details — navigates to full profile on tap.
class SellerTrustCard extends StatelessWidget {
  const SellerTrustCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.tooltipMessage,
  });

  final SellerPublicProfile profile;
  final VoidCallback onTap;

  /// Long-press / accessibility hint — card stays the primary tap target.
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ];

    final cardFill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    final displayName = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!.trim()
        : l10n.sellerFallbackName;

    final memberLine = l10n.sellerMemberSince(
      formatSellerMemberSinceMonthYear(l10n, profile.memberSince),
    );
    final listingsLine = l10n.sellerActiveListingsCount(
      profile.activeListingsCount,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: shadow,
        ),
        child: Material(
          color: cardFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _maybeTooltip(
            tooltipMessage,
            InkWell(
              onTap: onTap,
              splashFactory: InkRipple.splashFactory,
              splashColor: scheme.onSurface.withValues(alpha: 0.038),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    SellerAvatarBadge(profile: profile, diameter: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.06,
                              height: 1.22,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            memberLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.88,
                              ),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            listingsLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.82,
                              ),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CarzonIcons.chevronRight,
                      size: 19,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.48),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maybeTooltip(String? message, Widget child) {
  final t = message?.trim();
  if (t == null || t.isEmpty) return child;
  return Tooltip(message: t, child: child);
}
