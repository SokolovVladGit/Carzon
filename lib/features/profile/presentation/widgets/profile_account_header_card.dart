import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_cubit.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_state.dart';
import '../../../sellers/presentation/widgets/account_private_avatar.dart';

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

    const double avatarD = 56;
    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.055),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ];

    return DecoratedBox(
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              BlocBuilder<PublicSellerIdentityCubit, PublicSellerIdentityState>(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.12,
                        height: 1.22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondary != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        secondary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                          height: 1.28,
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
    );
  }
}
