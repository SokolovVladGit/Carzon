import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_cubit.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_state.dart';
import '../../../sellers/presentation/widgets/account_private_avatar.dart';
import 'profile_grouped_card.dart';

class ProfileAccountHeaderCard extends StatelessWidget {
  const ProfileAccountHeaderCard({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final fullName = user.fullName?.trim();
    final email = user.email.trim();
    final hasEmail = email.isNotEmpty;

    final String primary;
    final bool hasDisplayedName = fullName != null && fullName.isNotEmpty;
    if (hasDisplayedName) {
      primary = fullName;
    } else if (hasEmail) {
      primary = email;
    } else {
      primary = l10n.profileSignedInFallback;
    }
    final secondary = hasDisplayedName && hasEmail ? email : null;

    const double avatarD = 54;
    final cardFill = profileSoftSurface(scheme, isDark: isDark);
    final shadow = profileCardShadow(scheme, isDark: isDark);
    final radius = BorderRadius.circular(28);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isDark
                ? scheme.outline.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.40),
            width: 1.1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.120 : 0.060),
                  cardFill,
                ),
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: isDark ? 0.045 : 0.014),
                  cardFill,
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 15, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ProfileAvatarMedallion(
                  diameter: avatarD,
                  child:
                      BlocBuilder<
                        PublicSellerIdentityCubit,
                        PublicSellerIdentityState
                      >(
                        buildWhen: (p, c) =>
                            p.profile?.avatarUrl != c.profile?.avatarUrl ||
                            p.profile?.displayName != c.profile?.displayName,
                        builder: (context, s) {
                          return AccountPrivateAvatarCircle(
                            diameter: avatarD,
                            authUser: user,
                            sellerProfilesAvatarUrl: s.profile?.avatarUrl,
                            sellerDisplayNameForInitialsFallback:
                                s.profile?.displayName,
                          );
                        },
                      ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileBrandPill(scheme: scheme, isDark: isDark),
                      const SizedBox(height: 7),
                      Text(
                        primary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.05,
                          height: 1.18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (secondary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          secondary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.82,
                            ),
                            height: 1.24,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

class _ProfileBrandPill extends StatelessWidget {
  const _ProfileBrandPill({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.24 : 0.44,
        ),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.18 : 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          'CARZON',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.72 : 0.62,
            ),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarMedallion extends StatelessWidget {
  const _ProfileAvatarMedallion({required this.diameter, required this.child});

  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: diameter + 14,
      height: diameter + 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.22 : 0.13),
              scheme.surfaceContainerHighest,
            ),
            Color.alphaBlend(
              scheme.onSurface.withValues(alpha: isDark ? 0.055 : 0.018),
              scheme.surfaceContainerLow,
            ),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}
