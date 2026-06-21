import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../messaging/domain/usecases/get_or_create_support_conversation.dart';
import '../../../messaging/presentation/utils/support_conversation_user_messages.dart';
import '../../../profile/presentation/widgets/profile_grouped_card.dart';
import '../../../profile/presentation/widgets/profile_settings_navigation_row.dart';
import '../widgets/settings_about_section.dart';
import '../widgets/settings_dark_theme_row.dart';
import '../widgets/settings_language_row.dart';

/// Standalone app settings hub: account shortcuts, preferences, notifications,
/// privacy, and support/legal links.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _settingsPageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.menu),
        title: Text(l10n.settingsTitle),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _settingsCanvasGradient(context),
            stops: const [0, 0.42, 1],
          ),
        ),
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, auth) {
            if (auth.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.profileSignOutFailedRetry)),
              );
            }
          },
          builder: (context, auth) {
            final authenticated =
                auth.status == AuthStatus.authenticated && auth.user != null;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.78 : 0.82,
                      ),
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ProfileGroupedCard(
                    title: l10n.settingsSectionAccount,
                    childPadding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authenticated) ...[
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_account_profile_row',
                            ),
                            icon: CarzonIcons.user,
                            title: l10n.settingsAccountProfileTitle,
                            subtitle: l10n.settingsAccountProfileSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.push(AppRoutes.profile),
                          ),
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_change_password_row',
                            ),
                            icon: CarzonIcons.lock,
                            title: l10n.profileChangePasswordTitle,
                            subtitle: l10n.profileChangePasswordSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.push(AppRoutes.changePassword),
                          ),
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_sign_out_row',
                            ),
                            icon: CarzonIcons.signOut,
                            title: l10n.profileSignOut,
                            subtitle: l10n.settingsSignOutSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.read<AuthCubit>().signOut(),
                          ),
                        ] else
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_sign_in_row',
                            ),
                            icon: CarzonIcons.signIn,
                            title: l10n.commonSignIn,
                            subtitle: l10n.settingsSignInForAccountSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.go(AppRoutes.signIn),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProfileGroupedCard(
                    title: l10n.settingsSectionPreferences,
                    childPadding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SettingsDarkThemeRow(),
                        ProfileMutedDivider(scheme: scheme, isDark: isDark),
                        const SettingsLanguageRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProfileGroupedCard(
                    title: l10n.settingsSectionNotifications,
                    childPadding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileSettingsNavigationRow(
                          rowKey: const ValueKey<String>(
                            'settings_notifications_row',
                          ),
                          icon: CarzonIcons.notificationsOutline,
                          title: l10n.profileNotificationsTitle,
                          subtitle: l10n.profileNotificationsSubtitle,
                          theme: theme,
                          scheme: scheme,
                          onTap: () =>
                              context.push(AppRoutes.notificationSettings),
                        ),
                        if (authenticated) ...[
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_filter_alerts_row',
                            ),
                            icon: CarzonIcons.filter,
                            title: l10n.savedSearchesSettingsTitle,
                            subtitle: l10n.savedSearchesSettingsSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.push(AppRoutes.filterAlert),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (authenticated) ...[
                    const SizedBox(height: 16),
                    ProfileGroupedCard(
                      title: l10n.settingsSectionPrivacySafety,
                      childPadding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_blocked_users_row',
                            ),
                            icon: CarzonIcons.userBlock,
                            title: l10n.messagingSafetyBlockedUsersTitle,
                            subtitle: l10n.settingsBlockedUsersSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.push(AppRoutes.blockedUsers),
                          ),
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_request_data_row',
                            ),
                            icon: CarzonIcons.chat,
                            title: l10n.settingsRequestDataTitle,
                            subtitle: l10n.settingsRequestDataSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: _openingSupport
                                ? () {}
                                : () => _onContactSupportTap(context),
                          ),
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_delete_account_row',
                            ),
                            icon: CarzonIcons.delete,
                            title: l10n.settingsDeleteAccountTitle,
                            subtitle: l10n.settingsDeleteAccountSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: () => context.push(AppRoutes.deleteAccount),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ProfileGroupedCard(
                    title: l10n.settingsSectionSupportLegal,
                    childPadding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authenticated)
                          ProfileSettingsNavigationRow(
                            rowKey: const ValueKey<String>(
                              'settings_support_row',
                            ),
                            icon: CarzonIcons.chat,
                            title: l10n.contactSupport,
                            subtitle: l10n.contactSupportSubtitle,
                            theme: theme,
                            scheme: scheme,
                            onTap: _openingSupport
                                ? () {}
                                : () => _onContactSupportTap(context),
                          ),
                        if (authenticated)
                          ProfileMutedDivider(scheme: scheme, isDark: isDark),
                        ProfileSettingsNavigationRow(
                          rowKey: const ValueKey<String>('settings_legal_row'),
                          icon: CarzonIcons.privacy,
                          title: l10n.profileLegal,
                          subtitle: l10n.settingsLegalLinkSubtitle,
                          theme: theme,
                          scheme: scheme,
                          onTap: () => context.push(AppRoutes.legal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsAboutSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Color _settingsPageBackground(BuildContext context) {
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

List<Color> _settingsCanvasGradient(BuildContext context) {
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
