import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Menu tab rendered by the fourth capsule-nav destination.
///
/// This is the user's hub for account-adjacent surfaces. It replaces
/// the old separate "My Listings" and "Profile" tabs with a single
/// collected surface, matching modern marketplace navigation rhythm
/// (4 tabs instead of 5).
///
/// Responsibilities:
///   * surface a compact identity header when the user is signed in
///     (email / full name) so the tab isn't a cold navigation wall,
///   * offer entries for the authenticated sub-surfaces:
///       - My Listings,
///       - Account (Profile page),
///       - Favorites (mirror of the tab — accessible from here too
///         so Menu reads as the account hub),
///       - Create Listing,
///   * always offer the Legal entry (available regardless of auth),
///   * expose Sign in when signed out, Sign out when signed in.
///
/// No new cubit, domain model or data-layer import is introduced —
/// [AuthCubit.signOut] is reused, same as [ProfilePage].
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TopLevelScaffold(
      destination: TopLevelDestination.menu,
      appBar: AppBar(
        title: Text(l10n.menuTitle),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileSignOutFailedRetry),
              ),
            );
          }
        },
        builder: (context, state) {
          final authenticated = state.status == AuthStatus.authenticated &&
              state.user != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              0,
              8,
              0,
              kFloatingCapsuleNavClearance,
            ),
            children: [
              if (authenticated) ...[
                _MenuIdentityHeader(user: state.user!),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(CarzonIcons.myListings),
                title: Text(l10n.profileMyListings),
                trailing: const Icon(CarzonIcons.chevronRight),
                onTap: () => context.go(AppRoutes.myListings),
              ),
              ListTile(
                leading: const Icon(CarzonIcons.user),
                title: Text(l10n.menuAccount),
                trailing: const Icon(CarzonIcons.chevronRight),
                onTap: () => context.go(AppRoutes.profile),
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
                child: authenticated
                    ? OutlinedButton.icon(
                        onPressed: () =>
                            context.read<AuthCubit>().signOut(),
                        icon: const Icon(CarzonIcons.signOut),
                        label: Text(l10n.profileSignOut),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.signIn),
                        icon: const Icon(CarzonIcons.signIn),
                        label: Text(l10n.commonSignIn),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact identity header rendered at the top of the menu when the
/// user is signed in. Mirrors the shape of the identity block on the
/// account page so the menu reads as the user's home, not a list of
/// shortcuts.
class _MenuIdentityHeader extends StatelessWidget {
  const _MenuIdentityHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final fullName = user.fullName?.trim();
    final hasName = fullName != null && fullName.isNotEmpty;
    final email = user.email.trim();
    final hasEmail = email.isNotEmpty;

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
