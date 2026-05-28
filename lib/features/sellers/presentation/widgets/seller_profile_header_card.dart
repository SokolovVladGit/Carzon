import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
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

    final darkCardDecoration = isDark
        ? AppTheme.editorialDarkSectionCard(scheme, borderRadius: 20)
        : null;

    if (unavailable || profile == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: DecoratedBox(
          decoration:
              darkCardDecoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: shadow,
              ),
          child: Material(
            color: isDark
                ? Colors.transparent
                : Color.alphaBlend(
                    scheme.surfaceTint.withValues(alpha: 0.04),
                    scheme.surfaceContainerLowest,
                  ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isDark
                  ? BorderSide.none
                  : BorderSide(color: scheme.outline.withValues(alpha: 0.16)),
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
                      color: isDark
                          ? scheme.onSurface.withValues(alpha: 0.96)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sellerUnavailableMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.82 : 0.92,
                      ),
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
        decoration:
            darkCardDecoration ??
            BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: shadow,
            ),
        child: Material(
          color: isDark
              ? Colors.transparent
              : Color.alphaBlend(
                  scheme.surfaceTint.withValues(alpha: 0.045),
                  scheme.surfaceContainerLowest,
                ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark
                ? BorderSide.none
                : BorderSide(color: scheme.outline.withValues(alpha: 0.16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerAvatarBadge(
                  profile: p,
                  diameter: 72,
                  showEditorialRing: true,
                ),
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
                          color: isDark
                              ? scheme.onSurface.withValues(alpha: 0.96)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.sellerMemberSince(
                          formatSellerMemberSinceMonthYear(l10n, p.memberSince),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: isDark ? 0.82 : 0.88,
                          ),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SellerTypeBadge(label: typeLabel, isDark: isDark),
                      const SizedBox(height: 8),
                      Text(
                        l10n.sellerActiveListingsCount(p.activeListingsCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                          color: isDark
                              ? scheme.onSurface.withValues(alpha: 0.90)
                              : null,
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

class _SellerTypeBadge extends StatelessWidget {
  const _SellerTypeBadge({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    if (!isDark) {
      return Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
          letterSpacing: 0.15,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.10),
          scheme.surfaceContainerHigh,
        ),
        border: Border.all(
          color: AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
            letterSpacing: 0.12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
