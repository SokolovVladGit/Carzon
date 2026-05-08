import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_cubit.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_state.dart';
import '../../../sellers/presentation/widgets/public_seller_name_section.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_state.dart';
import '../../../sellers/presentation/widgets/account_private_avatar.dart';

/// Secondary account hub: private session strip, buyer-visible seller identity
/// editors, scaffolding for forthcoming settings — marketplace shortcuts remain
/// on [MenuPage].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.menu),
        title: Text(l10n.profileTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CarzonIcons.user, size: 48),
                const SizedBox(height: 12),
                Text(l10n.profileSignInRequired, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onSignIn, child: Text(l10n.commonSignIn)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountView extends StatefulWidget {
  const _AccountView({required this.user});

  final AuthUser user;

  @override
  State<_AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<_AccountView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      unawaited(context.read<MessagingUnreadSummaryCubit>().sync(auth));
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _PrivateAccountHeaderCard(user: user),
        const SizedBox(height: 14),
        _AccountGroupedCard(
          title: l10n.profileActivitySectionTitle,
          childPadding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(AppRoutes.messages),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      CarzonIcons.chat,
                      size: 22,
                      color: scheme.primary.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.messagingTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.06,
                              height: 1.28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BlocBuilder<MessagingUnreadSummaryCubit,
                              MessagingUnreadSummaryState>(
                            buildWhen: (p, q) =>
                                p.phase != q.phase ||
                                p.unreadConversationCount !=
                                    q.unreadConversationCount,
                            builder: (context, u) {
                              final hasUnread = u.shouldShowUnreadIndicator;
                              final showNoUnreadCopy =
                                  u.phase == MessagingUnreadSummaryPhase.loaded &&
                                      u.unreadConversationCount == 0;
                              final style = theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: hasUnread ? 0.95 : 0.72,
                                ),
                                height: 1.32,
                              );
                              if (!hasUnread && !showNoUnreadCopy) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                hasUnread
                                    ? l10n.profileMessagesUnreadStatus
                                    : l10n.profileMessagesNoUnreadStatus,
                                style: style,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<MessagingUnreadSummaryCubit,
                        MessagingUnreadSummaryState>(
                      buildWhen: (p, q) =>
                          p.phase != q.phase ||
                          p.unreadConversationCount != q.unreadConversationCount,
                      builder: (context, u) {
                        final count = u.unreadConversationCount;
                        final showBadge = u.shouldShowUnreadIndicator;
                        final trailingIcon = Icon(
                          CarzonIcons.chevronRight,
                          size: 19,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.48),
                        );
                        if (!showBadge) {
                          return trailingIcon;
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _ProfileUnreadCountBadge(
                                count: count,
                              ),
                            ),
                            trailingIcon,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _AccountGroupedCard(
          title: l10n.profilePublicSellerProfileSectionTitle,
          subtitle: l10n.profilePublicSellerProfileSectionSubtitle,
          childPadding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: PublicSellerNameSection(embeddedInSection: true),
          ),
        ),
        const SizedBox(height: 14),
        _AccountGroupedCard(
          title: l10n.profileSettingsSectionTitle,
          childPadding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                ignoring: true,
                child: _FutureSettingsRow(
                  key: const ValueKey('profile_future_row_language'),
                  title: l10n.profileLanguageTitle,
                  subtitle: l10n.profileLanguageCurrentRussian,
                  badgeLabel: l10n.commonComingSoon,
                  scheme: scheme,
                  isDark: isDark,
                  dimmed: true,
                ),
              ),
              _MutedDivider(scheme: scheme, isDark: isDark),
              IgnorePointer(
                ignoring: true,
                child: _FutureSettingsRow(
                  key: const ValueKey('profile_future_row_notifications'),
                  title: l10n.profileNotificationsTitle,
                  subtitle: l10n.profileNotificationsSubtitle,
                  badgeLabel: l10n.commonComingSoon,
                  scheme: scheme,
                  isDark: isDark,
                  dimmed: true,
                ),
              ),
              _MutedDivider(scheme: scheme, isDark: isDark),
              IgnorePointer(
                ignoring: true,
                child: _FutureSettingsRow(
                  key: const ValueKey('profile_future_row_listing_alerts'),
                  title: l10n.profileListingAlertsTitle,
                  subtitle: l10n.profileListingAlertsSubtitle,
                  badgeLabel: l10n.commonComingSoon,
                  scheme: scheme,
                  isDark: isDark,
                  dimmed: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AccountGroupedCard(
          child: OutlinedButton.icon(
            key: const ValueKey('profileSignOutButton'),
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(CarzonIcons.signOut),
            label: Text(l10n.profileSignOut),
          ),
        ),
        ],
      ),
    );
  }
}

/// Compact unread conversation count for Profile → Activity → Messages row.
///
/// Displays [count] as `1`–`99`, or localized overflow (e.g. `99+`) when
/// greater than `99`; [count] must be positive.
class _ProfileUnreadCountBadge extends StatelessWidget {
  const _ProfileUnreadCountBadge({required this.count});

  final int count;

  static String badgeLabel(BuildContext context, int count) {
    if (count > 99) return context.l10n.profileMessagesUnreadCountOverflow;
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('profile_messages_unread_count_badge'),
      constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badgeLabel(context, count),
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onError,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _PrivateAccountHeaderCard extends StatelessWidget {
  const _PrivateAccountHeaderCard({required this.user});

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
    final bool hasDisplayedName =
        fullName != null && fullName.isNotEmpty;
    if (hasDisplayedName) {
      primary = fullName;
    } else if (hasEmail) {
      primary = email;
    } else {
      primary = l10n.profileSignedInFallback;
    }
    final secondary =
        hasDisplayedName && hasEmail ? email : null;

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
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.9,
                          ),
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

class _AccountGroupedCard extends StatelessWidget {
  const _AccountGroupedCard({
    required this.child,
    this.title,
    this.subtitle,
    this.childPadding,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry? childPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.065),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ];

    final Color cardFill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    final innerPad = childPadding ??
        (title != null
            ? const EdgeInsets.fromLTRB(4, 4, 4, 8)
            : const EdgeInsets.all(12));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardFill,
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color:
                      scheme.outline.withValues(alpha: isDark ? 0.18 : 0.13),
                  indent: 16,
                  endIndent: 16,
                ),
              ],
              Padding(
                padding: innerPad,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureSettingsRow extends StatelessWidget {
  const _FutureSettingsRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.scheme,
    required this.isDark,
    required this.dimmed,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final ColorScheme scheme;
  final bool isDark;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = scheme.onSurface
        .withValues(alpha: dimmed ? (isDark ? 0.55 : 0.52) : 1);

    final textCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            height: 1.28,
            color: fg,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(
              alpha: dimmed ? 0.5 : 0.88,
            ),
            height: 1.32,
          ),
        ),
      ],
    );

    return Semantics(
      enabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textCol),
            const SizedBox(width: 12),
            _ComingSoonBadge(
              label: badgeLabel,
              scheme: scheme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({
    required this.label,
    required this.scheme,
    required this.isDark,
  });

  final String label;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
        ),
        color: scheme.surfaceContainerHighest
            .withValues(alpha: isDark ? 0.35 : 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
          ),
        ),
      ),
    );
  }
}

class _MutedDivider extends StatelessWidget {
  const _MutedDivider({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        endIndent: 16,
        color: scheme.outline.withValues(alpha: isDark ? 0.16 : 0.11),
      ),
    );
  }
}
