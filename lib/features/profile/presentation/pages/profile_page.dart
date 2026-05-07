import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_cubit.dart';
import '../../../sellers/presentation/widgets/public_seller_name_section.dart';

/// Account hub: session identity, **public seller display name** editing,
/// shortcuts to listings/favorites/create, legal, sign-out.
///
/// Public seller name is stored in `seller_profiles.display_name` (buyer-visible)
/// and does not replace private auth metadata.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TopLevelScaffold(
      destination: TopLevelDestination.menu,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          // AuthCubit.signOut emits `unauthenticated` on success and
          // `error` on failure. We handle both here rather than in an
          // onPressed callback because the sign-out could also be
          // triggered by another path (e.g. future session expiry).
          if (state.status == AuthStatus.unauthenticated) {
            context.go(AppRoutes.listings);
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileSignOutFailedRetry)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            return BlocProvider(
              create: (_) => sl<PublicSellerIdentityCubit>()..load(),
              child: _AccountView(user: state.user!),
            );
          }
          return _SignInRequired(onSignIn: () => context.go(AppRoutes.signIn));
        },
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CarzonIcons.user, size: 48),
            const SizedBox(height: 12),
            Text(l10n.profileSignInRequired, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSignIn, child: Text(l10n.commonSignIn)),
          ],
        ),
      ),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, kFloatingCapsuleNavClearance),
      children: [
        _IdentityHeader(user: user),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: PublicSellerNameSection(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(CarzonIcons.myListings),
          title: Text(l10n.profileMyListings),
          trailing: const Icon(CarzonIcons.chevronRight),
          onTap: () => context.go(AppRoutes.myListings),
        ),
        ListTile(
          leading: const Icon(CarzonIcons.heartOutline),
          title: Text(l10n.profileFavorites),
          trailing: const Icon(CarzonIcons.chevronRight),
          onTap: () => context.go(AppRoutes.favorites),
        ),
        ListTile(
          leading: const Icon(CarzonIcons.navCreateOutline),
          title: Text(l10n.profileCreateListing),
          trailing: const Icon(CarzonIcons.chevronRight),
          onTap: () => context.go(AppRoutes.createListing),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(CarzonIcons.privacy),
          title: Text(l10n.profileLegal),
          trailing: const Icon(CarzonIcons.chevronRight),
          onTap: () => context.go(AppRoutes.legal),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: OutlinedButton.icon(
            key: const ValueKey('profileSignOutButton'),
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(CarzonIcons.signOut),
            label: Text(l10n.profileSignOut),
          ),
        ),
      ],
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final fullName = user.fullName?.trim();
    final hasName = fullName != null && fullName.isNotEmpty;
    final email = user.email.trim();
    final hasEmail = email.isNotEmpty;

    // Primary line prefers full name; secondary line shows email.
    // If neither is available (edge case on legacy accounts) we fall
    // back to a neutral "Signed in" label.
    final primary = hasName
        ? fullName
        : (hasEmail ? email : l10n.profileSignedInFallback);
    final secondary = hasName && hasEmail ? email : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(CarzonIcons.user),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
