import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../sellers/presentation/bloc/self_seller_visual_cubit.dart';
import '../../../sellers/presentation/widgets/account_private_avatar.dart';

enum _MenuFooterVariant { neutral, accent }

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
/// No new cubit beyond what the app tree already provides — [AuthCubit]
/// and hub-scoped cubits are reused, same as [ProfilePage].
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      unawaited(context.read<SelfSellerVisualCubit>().prime(auth));
      unawaited(context.read<MessagingUnreadSummaryCubit>().sync(auth));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return TopLevelScaffold(
      destination: TopLevelDestination.menu,
      backgroundColor: _menuPageBackground(context),
      appBar: AppBar(
        title: Text(
          l10n.menuTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileSignOutFailedRetry)),
            );
          }
        },
        builder: (context, state) {
          final authenticated =
              state.status == AuthStatus.authenticated && state.user != null;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(
              bottom: kFloatingCapsuleNavClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                if (authenticated) ...[
                  _MenuIdentityCard(user: state.user!),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 8),
                _PremiumGroupedCard(
                  children: [
                    _PremiumMenuRow(
                      icon: CarzonIcons.myListings,
                      title: l10n.profileMyListings,
                      onTap: () => context.go(AppRoutes.myListings),
                    ),
                    _PremiumMenuRow(
                      icon: CarzonIcons.user,
                      title: l10n.menuAccount,
                      onTap: () => context.push(AppRoutes.profile),
                    ),
                    _PremiumMenuRow(
                      icon: CarzonIcons.heartOutline,
                      title: l10n.profileFavorites,
                      onTap: () => context.go(AppRoutes.favorites),
                    ),
                    _PremiumMenuRow(
                      icon: CarzonIcons.chat,
                      title: l10n.messagingTitle,
                      onTap: () => context.go(AppRoutes.messages),
                      showDividerAfter: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CreateListingPremiumTile(
                  title: l10n.profileCreateListing,
                  onTap: () => context.go(AppRoutes.createListing),
                ),
                const SizedBox(height: 14),
                _PremiumGroupedCard(
                  children: [
                    _PremiumMenuRow(
                      icon: CarzonIcons.privacy,
                      title: l10n.profileLegal,
                      onTap: () => context.go(AppRoutes.legal),
                      showDividerAfter: false,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: authenticated
                      ? _MenuFooterAuthAction(
                          key: const ValueKey('menu_sign_out_action'),
                          label: l10n.profileSignOut,
                          icon: CarzonIcons.signOut,
                          variant: _MenuFooterVariant.neutral,
                          onTap: () => context.read<AuthCubit>().signOut(),
                        )
                      : _MenuFooterAuthAction(
                          key: const ValueKey('menu_sign_in_action'),
                          label: l10n.commonSignIn,
                          icon: CarzonIcons.signIn,
                          variant: _MenuFooterVariant.accent,
                          onTap: () => context.go(AppRoutes.signIn),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color _menuPageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return scheme.surface;
  }
  // Whisper seed tint + warmer container wash (luxury-neutral, not cold grey).
  final tinted = Color.alphaBlend(
    scheme.surfaceTint.withValues(alpha: 0.045),
    scheme.surface,
  );
  return Color.alphaBlend(
    scheme.surfaceContainerLow.withValues(alpha: 0.82),
    tinted,
  );
}

/// Rounded group surface wrapping premium menu rows.
class _PremiumGroupedCard extends StatelessWidget {
  const _PremiumGroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.065),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.032),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    final Color cardFill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
          ),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < children.length; i++) children[i]],
          ),
        ),
      ),
    );
  }
}

class _PremiumMenuRow extends StatelessWidget {
  const _PremiumMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDividerAfter = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDividerAfter;

  static double get _dividerIndent =>
      16 + _PremiumIconCapsule.size + 14; // padding + capsule + gap

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashFactory: InkRipple.splashFactory,
            splashColor: scheme.onSurface.withValues(alpha: 0.038),
            highlightColor: Colors.transparent,
            hoverColor: scheme.onSurface.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  _PremiumIconCapsule(icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        height: 1.28,
                        color: scheme.onSurface.withValues(alpha: 0.93),
                      ),
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
        if (showDividerAfter)
          Padding(
            padding: EdgeInsets.only(left: _dividerIndent),
            child: Divider(
              height: 1,
              thickness: 1,
              endIndent: 16,
              color: scheme.outline.withValues(alpha: isDark ? 0.18 : 0.13),
            ),
          ),
      ],
    );
  }
}

/// Premium primary-action tile for create listing.
class _CreateListingPremiumTile extends StatelessWidget {
  const _CreateListingPremiumTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color fill = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.15 : 0.125),
      isDark
          ? scheme.surfaceContainerLow
          : Color.alphaBlend(
              scheme.surfaceTint.withValues(alpha: 0.05),
              scheme.surface,
            ),
    );
    final Color borderColor = scheme.primary.withValues(
      alpha: isDark ? 0.36 : 0.30,
    );

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.078),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: shadow,
        ),
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor, width: 1.15),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: InkRipple.splashFactory,
            splashColor: scheme.primary.withValues(alpha: 0.085),
            highlightColor: Colors.transparent,
            hoverColor: scheme.primary.withValues(alpha: 0.045),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 14, 17),
              child: Row(
                children: [
                  _PremiumIconCapsule(
                    icon: CarzonIcons.navCreateOutline,
                    emphasize: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        height: 1.28,
                        color: scheme.onSurface.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
                  Icon(
                    CarzonIcons.chevronRight,
                    size: 21,
                    color: scheme.primary.withValues(alpha: 0.62),
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

class _PremiumIconCapsule extends StatelessWidget {
  const _PremiumIconCapsule({required this.icon, this.emphasize = false});

  final IconData icon;
  final bool emphasize;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = emphasize
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.26 : 0.20),
            scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.42 : 0.88,
            ),
          )
        : scheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.48 : 0.94,
          );

    final Color fg = emphasize
        ? scheme.primary.withValues(alpha: isDark ? 0.98 : 0.90)
        : scheme.onSurfaceVariant.withValues(alpha: 0.92);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: scheme.outline.withValues(alpha: emphasize ? 0.22 : 0.11),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: emphasize ? 21.5 : 19.5, color: fg),
    );
  }
}

/// Premium identity card when the user is signed in.
class _MenuIdentityCard extends StatelessWidget {
  const _MenuIdentityCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final fullName = user.fullName?.trim();
    final hasName = fullName != null && fullName.isNotEmpty;
    final email = user.email.trim();
    final hasEmail = email.isNotEmpty;

    final primary = hasName
        ? fullName
        : (hasEmail ? email : l10n.profileSignedInFallback);
    final secondary = hasName && hasEmail ? email : null;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BlocBuilder<SelfSellerVisualCubit, SelfSellerVisualState>(
                  builder: (context, vis) {
                    return AccountPrivateAvatarCircle(
                      diameter: avatarD,
                      authUser: user,
                      sellerProfilesAvatarUrl: vis.sellerAvatarUrl,
                      sellerDisplayNameForInitialsFallback:
                          vis.sellerDisplayName,
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
                          letterSpacing: 0.15,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (secondary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          secondary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.88,
                            ),
                            height: 1.25,
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

/// Full-width footer control matching grouped-card language (not system buttons).
class _MenuFooterAuthAction extends StatelessWidget {
  const _MenuFooterAuthAction({
    super.key,
    required this.label,
    required this.icon,
    required this.variant,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final _MenuFooterVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = variant == _MenuFooterVariant.accent;

    final Color bg = accent
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.17 : 0.14),
            isDark
                ? scheme.surfaceContainerLow
                : Color.alphaBlend(
                    scheme.surfaceTint.withValues(alpha: 0.04),
                    scheme.surfaceContainerLowest,
                  ),
          )
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: isDark ? 0.055 : 0.038),
            isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
          );

    final Color border = accent
        ? scheme.primary.withValues(alpha: isDark ? 0.36 : 0.26)
        : scheme.outline.withValues(alpha: isDark ? 0.30 : 0.44);

    final Color fg = scheme.onSurface.withValues(alpha: accent ? 0.94 : 0.88);

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: accent ? 0.055 : 0.042),
              blurRadius: accent ? 16 : 14,
              offset: Offset(0, accent ? 6 : 5),
            ),
          ];

    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: shadow,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border, width: accent ? 1.05 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashFactory: InkRipple.splashFactory,
            splashColor: scheme.onSurface.withValues(
              alpha: accent ? 0.05 : 0.036,
            ),
            highlightColor: Colors.transparent,
            hoverColor: scheme.onSurface.withValues(alpha: 0.018),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 21, color: fg.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: fg,
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
