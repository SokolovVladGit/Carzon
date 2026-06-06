import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/config/env.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/app_locale_cubit.dart';
import '../../../../core/l10n/app_locale_preference.dart';
import '../../../../core/theme/theme_mode_cubit.dart';
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
          return ProfileSignInRequiredPrompt(
            onSignIn: () => context.go(AppRoutes.signIn),
          );
        },
      ),
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
          ProfileAccountHeaderCard(user: user),
          const SizedBox(height: 14),
          ProfileGroupedCard(
            title: l10n.profileActivitySectionTitle,
            childPadding: EdgeInsets.zero,
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
          const SizedBox(height: 14),
          ProfileSellerIdentitySection(
            title: l10n.profilePublicSellerProfileSectionTitle,
            subtitle: l10n.profilePublicSellerProfileSectionSubtitle,
          ),
          const SizedBox(height: 14),
          ProfileGroupedCard(
            title: l10n.profileSettingsSectionTitle,
            childPadding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileSettingsNavigationRow(
                  rowKey: const ValueKey<String>('profile_change_password_row'),
                  icon: CarzonIcons.lock,
                  title: l10n.profileChangePasswordTitle,
                  subtitle: l10n.profileChangePasswordSubtitle,
                  theme: theme,
                  scheme: scheme,
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                ProfileMutedDivider(scheme: scheme, isDark: isDark),
                _ProfileDarkThemeRow(theme: theme, scheme: scheme),
                ProfileMutedDivider(scheme: scheme, isDark: isDark),
                _ProfileLanguageRow(theme: theme, scheme: scheme),
                ProfileMutedDivider(scheme: scheme, isDark: isDark),
                ProfileSettingsNavigationRow(
                  rowKey: const ValueKey<String>(
                    'profile_notification_settings_row',
                  ),
                  icon: CarzonIcons.notificationsOutline,
                  title: l10n.profileNotificationsTitle,
                  subtitle: l10n.profileNotificationsSubtitle,
                  theme: theme,
                  scheme: scheme,
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ProfileGroupedCard(
            child: ProfileSignOutButton(
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLanguageRow extends StatelessWidget {
  const _ProfileLanguageRow({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  static String _currentLanguageLabel(
    AppLocalizations l10n,
    AppLocalePreference preference,
  ) {
    return switch (preference) {
      AppLocalePreference.ru => l10n.profileLanguageCurrentRussian,
      AppLocalePreference.ro => l10n.profileLanguageCurrentRomanian,
    };
  }

  Future<void> _syncPushTokenLocaleAfterChange() async {
    if (!Env.pushNotificationsEnabled) {
      return;
    }
    unawaited(
      sl<PushNotificationRegistrationService>()
          .syncTokenWithBackendIfEligible(),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AppLocaleCubit>();
    final selected = cubit.state.preference;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('profile_language_option_ru'),
                title: Text(l10n.profileLanguageOptionRussian),
                trailing: selected == AppLocalePreference.ru
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () async {
                  await cubit.setPreference(AppLocalePreference.ru);
                  await _syncPushTokenLocaleAfterChange();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              ListTile(
                key: const ValueKey('profile_language_option_ro'),
                title: Text(l10n.profileLanguageOptionRomanian),
                trailing: selected == AppLocalePreference.ro
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () async {
                  await cubit.setPreference(AppLocalePreference.ro);
                  await _syncPushTokenLocaleAfterChange();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AppLocaleCubit, AppLocaleState>(
      builder: (context, localeState) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 10,
            top: 6,
            bottom: 6,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('profile_future_row_language'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showLanguageSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.language_outlined,
                      size: 22,
                      color: scheme.primary.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profileLanguageTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.06,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentLanguageLabel(l10n, localeState.preference),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.82,
                              ),
                              height: 1.32,
                            ),
                          ),
                        ],
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
        );
      },
    );
  }
}

class _ProfileDarkThemeRow extends StatelessWidget {
  const _ProfileDarkThemeRow({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12, top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CarzonIcons.darkTheme,
            size: 22,
            color: scheme.primary.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileDarkThemeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileDarkThemeSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<ThemeModeCubit, ThemeModeState>(
            builder: (context, state) {
              return Switch.adaptive(
                key: const ValueKey<String>('profile_dark_theme_switch'),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (enabled) {
                  context.read<ThemeModeCubit>().setDarkEnabled(enabled);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
