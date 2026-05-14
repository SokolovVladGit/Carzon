import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../services/push_messaging_permission_status.dart';
import '../cubit/notification_settings_cubit.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallback: AppRoutes.profile),
              title: Text(l10n.notificationSettingsTitle),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.notificationSettingsSignInRequired,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.signIn),
                      child: Text(l10n.commonSignIn),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => sl<NotificationSettingsCubit>()..load(),
          child: const _NotificationSettingsBody(),
        );
      },
    );
  }
}

class _NotificationSettingsBody extends StatelessWidget {
  const _NotificationSettingsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      listenWhen: (p, c) =>
          p.notice != c.notice && c.notice != NotificationUserNotice.none,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        final text = _noticeMessage(l10n, state.notice);
        if (text != null) {
          messenger.showSnackBar(SnackBar(content: Text(text)));
        }
        context.read<NotificationSettingsCubit>().clearNotice();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            leading: const AppBackButton(fallback: AppRoutes.profile),
            title: Text(l10n.notificationSettingsTitle),
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            systemOverlayStyle: scheme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
          body: switch (state.phase) {
            NotificationSettingsLoadPhase.initial ||
            NotificationSettingsLoadPhase.loading =>
              const LoadingView(),
            NotificationSettingsLoadPhase.failure => ErrorView(
                message: l10n.notificationSettingsLoadFailed,
                onRetry: () =>
                    context.read<NotificationSettingsCubit>().load(),
              ),
            NotificationSettingsLoadPhase.ready => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (!Env.pushNotificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n.notificationSettingsPushBuildDisabledBanner,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  if (Env.pushNotificationsEnabled &&
                      state.osPermission != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _osStatusLabel(l10n, state.osPermission!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  SwitchListTile.adaptive(
                    title: Text(l10n.notificationSettingsGlobalTitle),
                    subtitle: Text(l10n.notificationSettingsGlobalSubtitle),
                    value: state.preferences!.globalEnabled,
                    onChanged: state.busy || !Env.pushNotificationsEnabled
                        ? null
                        : (v) => context
                            .read<NotificationSettingsCubit>()
                            .setGlobalEnabled(v),
                  ),
                  SwitchListTile.adaptive(
                    title: Text(l10n.notificationSettingsMessagesTitle),
                    subtitle: Text(
                      state.preferences!.globalEnabled
                          ? l10n.notificationSettingsMessagesSubtitle
                          : l10n.notificationSettingsMessagesNeedsGlobal,
                    ),
                    value: state.preferences!.messagesEnabled &&
                        state.preferences!.globalEnabled,
                    onChanged: state.busy ||
                            !Env.pushNotificationsEnabled ||
                            !state.preferences!.globalEnabled
                        ? null
                        : (v) => context
                            .read<NotificationSettingsCubit>()
                            .setMessagesEnabled(v),
                  ),
                  SwitchListTile.adaptive(
                    title: Text(l10n.notificationSettingsFilterAlertsTitle),
                    subtitle: Text(
                      state.preferences!.globalEnabled
                          ? l10n.notificationSettingsFilterAlertsSubtitle
                          : l10n.notificationSettingsFilterAlertsNeedsGlobal,
                    ),
                    value: state.preferences!.filterAlertsEnabled &&
                        state.preferences!.globalEnabled,
                    onChanged: state.busy ||
                            !Env.pushNotificationsEnabled ||
                            !state.preferences!.globalEnabled
                        ? null
                        : (v) => context
                            .read<NotificationSettingsCubit>()
                            .setFilterAlertsEnabled(v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      l10n.notificationSettingsDeliveryDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.86),
                          ),
                    ),
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

String? _noticeMessage(AppLocalizations l10n, NotificationUserNotice notice) {
  return switch (notice) {
    NotificationUserNotice.osPermissionDenied =>
      l10n.notificationSettingsOsPermissionDenied,
    NotificationUserNotice.loadFailed =>
      l10n.notificationSettingsLoadFailed,
    NotificationUserNotice.saveFailed =>
      l10n.notificationSettingsSaveFailed,
    NotificationUserNotice.pushUnavailableInBuild =>
      l10n.notificationSettingsPushUnavailableInBuild,
    NotificationUserNotice.none => null,
  };
}

String _osStatusLabel(
  AppLocalizations l10n,
  PushMessagingPermissionStatus status,
) {
  return switch (status) {
    PushMessagingPermissionStatus.authorized =>
      l10n.notificationSettingsOsStatusAuthorized,
    PushMessagingPermissionStatus.provisional =>
      l10n.notificationSettingsOsStatusProvisional,
    PushMessagingPermissionStatus.denied =>
      l10n.notificationSettingsOsStatusDenied,
    PushMessagingPermissionStatus.notDetermined =>
      l10n.notificationSettingsOsStatusNotDetermined,
  };
}
