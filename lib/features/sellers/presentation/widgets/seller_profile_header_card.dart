import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/entities/seller_public_profile.dart';
import '../../domain/entities/seller_type.dart';
import '../utils/format_seller_member_since.dart';
import 'seller_avatar_badge.dart';

/// Premium identity header for the public seller profile route.
class SellerProfileHeaderCard extends StatelessWidget {
  SellerProfileHeaderCard.loaded({
    super.key,
    required SellerPublicProfile profile,
  }) : profile = profile,
       unavailable = false;

  SellerProfileHeaderCard.unavailable({super.key})
    : profile = null,
      unavailable = true;

  final SellerPublicProfile? profile;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.055),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ];

    if (unavailable || profile == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: shadow,
          ),
          child: Material(
            color: isDark
                ? scheme.surfaceContainerLow
                : Color.alphaBlend(
                    scheme.surfaceTint.withValues(alpha: 0.04),
                    scheme.surfaceContainerLowest,
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.16),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sellerUnavailableTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sellerUnavailableMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final p = profile!;
    final displayName = p.displayName?.trim().isNotEmpty == true
        ? p.displayName!.trim()
        : l10n.sellerFallbackName;

    final typeLabel = switch (p.sellerType) {
      SellerType.dealer => l10n.sellerTypeDealer,
      SellerType.private => l10n.sellerTypePrivate,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: shadow,
        ),
        child: Material(
          color: isDark
              ? scheme.surfaceContainerLow
              : Color.alphaBlend(
                  scheme.surfaceTint.withValues(alpha: 0.045),
                  scheme.surfaceContainerLowest,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerAvatarBadge(profile: p, diameter: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.12,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.sellerMemberSince(
                          formatSellerMemberSinceMonthYear(l10n, p.memberSince),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.88,
                          ),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        typeLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.82,
                          ),
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.sellerActiveListingsCount(p.activeListingsCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
