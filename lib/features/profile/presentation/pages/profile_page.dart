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
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_state.dart';
import '../../../sellers/presentation/bloc/public_seller_identity_cubit.dart';
import '../widgets/profile_account_header_card.dart';
import '../widgets/profile_activity_messages_row.dart';
import '../widgets/profile_grouped_card.dart';
import '../widgets/profile_seller_identity_section.dart';
import '../widgets/profile_settings_navigation_row.dart';
import '../widgets/profile_sign_in_required_prompt.dart';
import '../widgets/profile_sign_out_button.dart';

/// Secondary account hub: private session strip, buyer-visible seller identity
/// editors, and activity — app preferences live on [SettingsPage].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _profilePageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.menu),
        title: Text(l10n.profileTitle),
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
              child: _ProfileShowroomBackground(
                child: _AccountView(user: state.user!),
              ),
            );
          }
          return _ProfileShowroomBackground(
            child: ProfileSignInRequiredPrompt(
              onSignIn: () => context.go(AppRoutes.signIn),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileShowroomBackground extends StatelessWidget {
  const _ProfileShowroomBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _profileCanvasGradient(context),
          stops: const [0, 0.42, 1],
        ),
      ),
      child: child,
    );
  }
}

Color _profilePageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
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

List<Color> _profileCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    final top = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.075),
      scheme.surfaceContainerLow,
    );
    final mid = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.030),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileAccountHeaderCard(user: user),
          const SizedBox(height: 16),
          ProfileGroupedCard(
            title: l10n.profileActivitySectionTitle,
            childPadding: const EdgeInsets.symmetric(vertical: 6),
            child:
                BlocBuilder<
                  MessagingUnreadSummaryCubit,
                  MessagingUnreadSummaryState
                >(
                  buildWhen: (p, q) =>
                      p.phase != q.phase ||
                      p.unreadConversationCount != q.unreadConversationCount,
                  builder: (context, unread) {
                    final hasUnread = unread.shouldShowUnreadIndicator;
                    final showNoUnreadCopy =
                        unread.phase == MessagingUnreadSummaryPhase.loaded &&
                        unread.unreadConversationCount == 0;
                    return ProfileActivityMessagesRow(
                      hasUnread: hasUnread,
                      showNoUnreadCopy: showNoUnreadCopy,
                      unreadConversationCount: unread.unreadConversationCount,
                      onTap: () => context.push(AppRoutes.messages),
                    );
                  },
                ),
          ),
          const SizedBox(height: 16),
          ProfileSellerIdentitySection(
            title: l10n.profilePublicSellerProfileSectionTitle,
            subtitle: l10n.profilePublicSellerProfileSectionSubtitle,
          ),
          const SizedBox(height: 16),
          ProfileGroupedCard(
            title: l10n.profileSettingsSectionTitle,
            childPadding: const EdgeInsets.symmetric(vertical: 6),
            child: ProfileSettingsNavigationRow(
              rowKey: const ValueKey<String>('profile_open_settings_row'),
              icon: CarzonIcons.settings,
              title: l10n.profileOpenSettingsTitle,
              subtitle: l10n.profileOpenSettingsSubtitle,
              theme: theme,
              scheme: scheme,
              onTap: () => context.push(AppRoutes.settings),
            ),
          ),
          const SizedBox(height: 18),
          ProfileGroupedCard(
            childPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: ProfileSignOutButton(
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
