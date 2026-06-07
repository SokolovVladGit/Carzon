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
import '../../../compare/presentation/cubit/compare_cubit.dart';
import '../../../compare/presentation/cubit/compare_state.dart';
import '../widgets/menu_count_badge.dart';
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
      body: _MenuShowroomBackground(
        child: BlocConsumer<AuthCubit, AuthState>(
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
                bottom: kFloatingCapsuleNavClearance + 42,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  if (authenticated) ...[
                    _MenuIdentityCard(user: state.user!),
                    const SizedBox(height: 22),
                  ] else
                    const SizedBox(height: 14),
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
                      BlocBuilder<CompareCubit, CompareState>(
                        builder: (context, compareState) {
                          return _PremiumMenuRow(
                            icon: CarzonIcons.compare,
                            title: l10n.menuCompare,
                            badgeCount: compareState.count,
                            onTap: () => context.go(AppRoutes.compare),
                          );
                        },
                      ),
                      _PremiumMenuRow(
                        icon: CarzonIcons.chat,
                        title: l10n.messagingTitle,
                        onTap: () => context.go(AppRoutes.messages),
                        showDividerAfter: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CreateListingPremiumTile(
                    title: l10n.profileCreateListing,
                    onTap: () => context.go(AppRoutes.createListing),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
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
      ),
    );
  }
}

class _MenuShowroomBackground extends StatelessWidget {
  const _MenuShowroomBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _menuPageGradient(context),
          stops: const [0, 0.42, 1],
        ),
      ),
      child: child,
    );
  }
}

Color _menuPageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.050),
      scheme.surface,
    );
  }
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.018),
    scheme.surface,
  );
}

List<Color> _menuPageGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    final top = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.075),
      scheme.surfaceContainerLow,
    );
    final mid = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.035),
      scheme.surface,
    );
    final bottom = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.026),
      Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.080),
        scheme.surfaceContainerLow,
      ),
    );
    return [top, mid, bottom];
  }

  final top = Color.alphaBlend(
    scheme.surfaceTint.withValues(alpha: 0.008),
    scheme.surface,
  );
  final mid = Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.032),
    scheme.surfaceContainerLowest,
  );
  final bottom = Color.alphaBlend(
    scheme.onSurface.withValues(alpha: 0.024),
    Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.070),
      scheme.surfaceContainerLow,
    ),
  );
  return [top, mid, bottom];
}

Color _softMenuSurface(ColorScheme scheme, {required bool isDark}) {
  if (isDark) {
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.070),
      scheme.surfaceContainerLow,
    );
  }
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.026),
    scheme.surfaceContainerLowest,
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
        ? [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 11),
            ),
          ]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.056),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.026),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ];

    final Color cardFill = _softMenuSurface(scheme, isDark: isDark);
    final radius = BorderRadius.circular(26);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.onSurface.withValues(alpha: isDark ? 0.025 : 0.010),
                cardFill,
              ),
              cardFill,
            ],
          ),
          borderRadius: radius,
          border: Border.all(
            color: isDark
                ? scheme.outline.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.42),
          ),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < children.length; i++) children[i]],
            ),
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
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDividerAfter;

  /// Optional numeric badge (e.g. compare set size). Hidden when null or 0.
  final int? badgeCount;

  static double get _dividerIndent =>
      20 + _PremiumIconCapsule.defaultSize + 16; // padding + capsule + gap

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              splashFactory: InkRipple.splashFactory,
              splashColor: scheme.onSurface.withValues(alpha: 0.038),
              highlightColor: Colors.transparent,
              hoverColor: scheme.onSurface.withValues(alpha: 0.02),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12.5, 8, 12.5),
                  child: Row(
                    children: [
                      _PremiumIconCapsule(icon: icon),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                            height: 1.28,
                            color: scheme.onSurface.withValues(alpha: 0.94),
                          ),
                        ),
                      ),
                      if (badgeCount != null && badgeCount! > 0) ...[
                        MenuCountBadge(count: badgeCount!),
                        const SizedBox(width: 9),
                      ],
                      _MenuChevronGlyph(),
                    ],
                  ),
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
                endIndent: 50,
                color: scheme.outline.withValues(alpha: isDark ? 0.080 : 0.045),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuChevronGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 26,
      height: 32,
      child: Icon(
        CarzonIcons.chevronRight,
        size: 18,
        color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.56 : 0.42),
      ),
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

    final Color fill = isDark
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.28),
            scheme.surfaceContainerHigh,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.155),
            scheme.surfaceContainerLowest,
          );
    final Color borderColor = scheme.primary.withValues(
      alpha: isDark ? 0.46 : 0.34,
    );

    final shadow = isDark
        ? [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.30),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.09),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.092),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.115),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: borderColor, width: 1.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: isDark ? 0.15 : 0.082),
                    fill,
                  ),
                  fill,
                  Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: isDark ? 0.045 : 0.018),
                    fill,
                  ),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              splashFactory: InkRipple.splashFactory,
              splashColor: scheme.primary.withValues(alpha: 0.095),
              highlightColor: Colors.transparent,
              hoverColor: scheme.primary.withValues(alpha: 0.045),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(19, 22, 17, 22),
                child: Row(
                  children: [
                    _PremiumIconCapsule(
                      icon: CarzonIcons.navCreateOutline,
                      emphasize: true,
                      size: 50,
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.02,
                          height: 1.20,
                          color: scheme.onSurface.withValues(alpha: 0.97),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.20 : 0.12,
                        ),
                        border: Border.all(
                          color: scheme.primary.withValues(
                            alpha: isDark ? 0.36 : 0.24,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CarzonIcons.chevronRight,
                        size: 20,
                        color: scheme.primary.withValues(alpha: 0.86),
                      ),
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

class _PremiumIconCapsule extends StatelessWidget {
  const _PremiumIconCapsule({
    required this.icon,
    this.emphasize = false,
    this.size = 42,
  });

  final IconData icon;
  final bool emphasize;
  final double size;

  static const double defaultSize = 42;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = emphasize
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
            scheme.surfaceContainerHighest,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.12 : 0.060),
            Color.alphaBlend(
              scheme.onSurface.withValues(alpha: isDark ? 0.025 : 0.010),
              scheme.surfaceContainerHighest,
            ),
          );

    final Color fg = emphasize
        ? scheme.primary.withValues(alpha: isDark ? 0.98 : 0.90)
        : scheme.onSurfaceVariant.withValues(alpha: 0.92);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(emphasize ? 18 : 16),
        color: bg,
        border: Border.all(
          color: emphasize
              ? scheme.primary.withValues(alpha: isDark ? 0.38 : 0.26)
              : scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(
                    alpha: emphasize ? 0.055 : 0.035,
                  ),
                  blurRadius: emphasize ? 14 : 10,
                  offset: Offset(0, emphasize ? 4 : 3),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: emphasize ? size * 0.48 : size * 0.45, color: fg),
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

    const double avatarD = 52;

    final shadow = isDark
        ? [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.26),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.055),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.070),
              blurRadius: 30,
              offset: const Offset(0, 13),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.052),
              blurRadius: 24,
              offset: const Offset(0, 7),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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
                    _softMenuSurface(scheme, isDark: isDark),
                  ),
                  Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: isDark ? 0.045 : 0.014),
                    _softMenuSurface(scheme, isDark: isDark),
                  ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MenuAvatarMedallion(diameter: avatarD, user: user),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuBrandPill(),
                        const SizedBox(height: 8),
                        Text(
                          primary,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.05,
                            height: 1.12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (secondary != null) ...[
                          const SizedBox(height: 5),
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
      ),
    );
  }
}

class _MenuBrandPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

class _MenuAvatarMedallion extends StatelessWidget {
  const _MenuAvatarMedallion({required this.diameter, required this.user});

  final double diameter;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: diameter + 16,
      height: diameter + 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.22 : 0.13),
              scheme.surfaceContainerHighest,
            ),
            Color.alphaBlend(
              scheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.018),
              scheme.surfaceContainerHighest,
            ),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.16),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.050),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: BlocBuilder<SelfSellerVisualCubit, SelfSellerVisualState>(
        builder: (context, vis) {
          return AccountPrivateAvatarCircle(
            diameter: diameter,
            authUser: user,
            sellerProfilesAvatarUrl: vis.sellerAvatarUrl,
            sellerDisplayNameForInitialsFallback: vis.sellerDisplayName,
          );
        },
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
            scheme.primary.withValues(alpha: isDark ? 0.17 : 0.105),
            _softMenuSurface(scheme, isDark: isDark),
          )
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: isDark ? 0.035 : 0.012),
            _softMenuSurface(scheme, isDark: isDark),
          );

    final Color border = accent
        ? scheme.primary.withValues(alpha: isDark ? 0.36 : 0.26)
        : scheme.outline.withValues(alpha: isDark ? 0.26 : 0.30);

    final Color fg = scheme.onSurface.withValues(alpha: accent ? 0.94 : 0.88);

    final shadow = isDark
        ? [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: accent ? 0.055 : 0.036),
              blurRadius: accent ? 20 : 16,
              offset: Offset(0, accent ? 8 : 6),
            ),
          ];

    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: shadow,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
