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
import '../../../../core/utils/result.dart';
import '../../../messaging/domain/usecases/get_or_create_support_conversation.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_state.dart';
import '../../../messaging/presentation/utils/support_conversation_user_messages.dart';
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
  bool _openingSupport = false;

  Future<void> _onContactSupportTap(BuildContext context) async {
    if (_openingSupport) return;
    setState(() => _openingSupport = true);
    try {
      final result = await sl<GetOrCreateSupportConversation>().call();
      if (!context.mounted) return;
      switch (result) {
        case Success(:final value):
          await context.push(AppRoutes.messagesThreadPath(value));
        case FailureResult(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                supportConversationOpenFailureMessage(context.l10n, failure),
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _openingSupport = false);
    }
  }

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
                ProfileMutedDivider(scheme: scheme, isDark: isDark),
                ProfileSettingsNavigationRow(
                  rowKey: const ValueKey<String>('profile_contact_support_row'),
                  icon: CarzonIcons.chat,
                  title: l10n.contactSupport,
                  subtitle: l10n.contactSupportSubtitle,
                  theme: theme,
                  scheme: scheme,
                  onTap: _openingSupport
                      ? () {}
                      : () => _onContactSupportTap(context),
                ),
              ],
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
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('profile_future_row_language'),
              borderRadius: BorderRadius.circular(18),
              splashFactory: InkRipple.splashFactory,
              splashColor: scheme.onSurface.withValues(alpha: 0.038),
              highlightColor: Colors.transparent,
              onTap: () => _showLanguageSheet(context),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 12.5, 6, 12.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSettingsIconCapsule(
                        icon: Icons.language_outlined,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profileLanguageTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.04,
                                height: 1.28,
                                color: scheme.onSurface.withValues(alpha: 0.94),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLanguageLabel(
                                l10n,
                                localeState.preference,
                              ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SizedBox(
                          width: 26,
                          height: 32,
                          child: Icon(
                            CarzonIcons.chevronRight,
                            size: 18,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.56 : 0.42,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 12.5, 10, 12.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileSettingsIconCapsule(
              icon: CarzonIcons.darkTheme,
              scheme: scheme,
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileDarkThemeTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.04,
                        height: 1.28,
                        color: scheme.onSurface.withValues(alpha: 0.94),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Switch.adaptive(
                    key: const ValueKey<String>('profile_dark_theme_switch'),
                    value: state.themeMode == ThemeMode.dark,
                    onChanged: (enabled) {
                      context.read<ThemeModeCubit>().setDarkEnabled(enabled);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsIconCapsule extends StatelessWidget {
  const _ProfileSettingsIconCapsule({
    required this.icon,
    required this.scheme,
    required this.isDark,
  });

  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.14 : 0.085),
          scheme.surfaceContainerLowest,
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: 19,
        color: scheme.primary.withValues(alpha: isDark ? 0.90 : 0.84),
      ),
    );
  }
}
