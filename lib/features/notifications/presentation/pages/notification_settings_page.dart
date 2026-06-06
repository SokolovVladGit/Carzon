import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../services/push_messaging_permission_status.dart';
import '../cubit/notification_settings_cubit.dart';
import '../widgets/notification_settings_section_card.dart';

/// Hosts notification settings UI under [AuthCubit] + [NotificationSettingsCubit]
/// without calling [NotificationSettingsCubit.load]. For widget tests only.
@visibleForTesting
Widget notificationSettingsTestHarness({
  required AuthCubit authCubit,
  required NotificationSettingsCubit settingsCubit,
}) {
  return BlocProvider<AuthCubit>.value(
    value: authCubit,
    child: BlocProvider<NotificationSettingsCubit>.value(
      value: settingsCubit,
      child: const _NotificationSettingsBody(),
    ),
  );
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return _NotificationSettingsChrome(
            body: AuthRequiredPrompt(
              message: l10n.notificationSettingsSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
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

class _NotificationSettingsChrome extends StatelessWidget {
  const _NotificationSettingsChrome({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.editorialDarkFilterCanvasGradient(scheme),
                  stops: const [0, 0.4, 1],
                )
              : null,
          color: isDark
              ? null
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.02),
                  scheme.surface,
                ),
        ),
        child: body,
      ),
    );
  }
}

class _NotificationSettingsBody extends StatelessWidget {
  const _NotificationSettingsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        return _NotificationSettingsChrome(
          body: switch (state.phase) {
            NotificationSettingsLoadPhase.initial ||
            NotificationSettingsLoadPhase.loading => const LoadingView(),
            NotificationSettingsLoadPhase.failure => ErrorView(
              message: l10n.notificationSettingsLoadFailed,
              onRetry: () => context.read<NotificationSettingsCubit>().load(),
            ),
            NotificationSettingsLoadPhase.ready => _NotificationSettingsContent(
              state: state,
            ),
          },
        );
      },
    );
  }
}

class _NotificationSettingsContent extends StatelessWidget {
  const _NotificationSettingsContent({required this.state});

  final NotificationSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pushOn = Env.pushNotificationsEnabled;
    final prefs = state.preferences!;
    final globalOn = prefs.globalEnabled;
    final masterEnabled = pushOn && globalOn;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.notificationSettingsPageIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _DevicePermissionCard(
            pushOn: pushOn,
            osPermission: state.osPermission,
          ),
          const SizedBox(height: 12),
          _MasterPushCard(
            pushOn: pushOn,
            busy: state.busy,
            globalEnabled: globalOn,
          ),
          const SizedBox(height: 12),
          _MessagesNotificationsCard(
            pushOn: pushOn,
            busy: state.busy,
            globalOn: globalOn,
            messagesEnabled: prefs.messagesEnabled,
          ),
          const SizedBox(height: 12),
          _FilterAlertsNotificationsCard(
            pushOn: pushOn,
            busy: state.busy,
            globalOn: globalOn,
            filterAlertsEnabled: prefs.filterAlertsEnabled,
          ),
          const SizedBox(height: 12),
          NotificationSettingsSectionCard(
            key: const ValueKey<String>('notification_settings_delivery_card'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificationSettingsDeliveryCardTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.notificationSettingsDeliveryDisclaimer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!pushOn) ...[
            const SizedBox(height: 12),
            Text(
              l10n.notificationSettingsPushBuildDisabledHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                height: 1.32,
              ),
            ),
          ] else if (!masterEnabled) ...[
            const SizedBox(height: 12),
            Text(
              l10n.notificationSettingsMasterOffHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                height: 1.32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DevicePermissionCard extends StatelessWidget {
  const _DevicePermissionCard({
    required this.pushOn,
    required this.osPermission,
  });

  final bool pushOn;
  final PushMessagingPermissionStatus? osPermission;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = _permissionVisuals(
      l10n,
      scheme: scheme,
      pushOn: pushOn,
      status: osPermission,
    );

    return NotificationSettingsSectionCard(
      key: const ValueKey<String>('notification_settings_status_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smartphone_outlined,
                size: 22,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.notificationSettingsStatusCardTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              _StatusPill(label: visuals.pillLabel, colors: visuals.pillColors),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            visuals.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionVisuals {
  const _PermissionVisuals({
    required this.pillLabel,
    required this.pillColors,
    required this.description,
  });

  final String pillLabel;
  final _StatusPillColors pillColors;
  final String description;
}

class _StatusPillColors {
  const _StatusPillColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

_PermissionVisuals _permissionVisuals(
  AppLocalizations l10n, {
  required ColorScheme scheme,
  required bool pushOn,
  required PushMessagingPermissionStatus? status,
}) {
  final accent = AppTheme.editorialAccentColor(scheme);

  if (!pushOn) {
    return _PermissionVisuals(
      pillLabel: l10n.notificationSettingsOsPillUnavailable,
      pillColors: _StatusPillColors(
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        border: scheme.outlineVariant.withValues(alpha: 0.45),
      ),
      description: l10n.notificationSettingsOsDescriptionUnavailable,
    );
  }

  return switch (status) {
    PushMessagingPermissionStatus.authorized => _PermissionVisuals(
      pillLabel: l10n.notificationSettingsOsPillAllowed,
      pillColors: _StatusPillColors(
        background: Color.alphaBlend(
          const Color(0xFF2E7D32).withValues(alpha: 0.14),
          scheme.surfaceContainerHigh,
        ),
        foreground: scheme.onSurface.withValues(alpha: 0.92),
        border: const Color(0xFF2E7D32).withValues(alpha: 0.35),
      ),
      description: l10n.notificationSettingsOsDescriptionAuthorized,
    ),
    PushMessagingPermissionStatus.provisional => _PermissionVisuals(
      pillLabel: l10n.notificationSettingsOsPillProvisional,
      pillColors: _StatusPillColors(
        background: Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          scheme.surfaceContainerHigh,
        ),
        foreground: accent,
        border: accent.withValues(alpha: 0.40),
      ),
      description: l10n.notificationSettingsOsDescriptionProvisional,
    ),
    PushMessagingPermissionStatus.denied => _PermissionVisuals(
      pillLabel: l10n.notificationSettingsOsPillDenied,
      pillColors: _StatusPillColors(
        background: Color.alphaBlend(
          scheme.error.withValues(alpha: 0.12),
          scheme.surfaceContainerHigh,
        ),
        foreground: scheme.error,
        border: scheme.error.withValues(alpha: 0.35),
      ),
      description: l10n.notificationSettingsOsDescriptionDenied,
    ),
    PushMessagingPermissionStatus.notDetermined || null => _PermissionVisuals(
      pillLabel: l10n.notificationSettingsOsPillNotDetermined,
      pillColors: _StatusPillColors(
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        border: scheme.outlineVariant.withValues(alpha: 0.40),
      ),
      description: l10n.notificationSettingsOsDescriptionNotDetermined,
    ),
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.colors});

  final String label;
  final _StatusPillColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _MasterPushCard extends StatelessWidget {
  const _MasterPushCard({
    required this.pushOn,
    required this.busy,
    required this.globalEnabled,
  });

  final bool pushOn;
  final bool busy;
  final bool globalEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NotificationSettingsSectionCard(
      key: const ValueKey<String>('notification_settings_master_card'),
      child: _NotificationSwitchRow(
        icon: CarzonIcons.notificationsOutline,
        title: l10n.notificationSettingsGlobalTitle,
        subtitle: pushOn
            ? l10n.notificationSettingsGlobalSubtitle
            : l10n.notificationSettingsPushBuildDisabledBanner,
        value: globalEnabled,
        onChanged: busy || !pushOn
            ? null
            : (v) =>
                  context.read<NotificationSettingsCubit>().setGlobalEnabled(v),
      ),
    );
  }
}

class _MessagesNotificationsCard extends StatelessWidget {
  const _MessagesNotificationsCard({
    required this.pushOn,
    required this.busy,
    required this.globalOn,
    required this.messagesEnabled,
  });

  final bool pushOn;
  final bool busy;
  final bool globalOn;
  final bool messagesEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NotificationSettingsSectionCard(
      key: const ValueKey<String>('notification_settings_messages_card'),
      child: _NotificationSwitchRow(
        icon: CarzonIcons.chat,
        title: l10n.notificationSettingsMessagesTitle,
        subtitle: globalOn
            ? l10n.notificationSettingsMessagesSubtitle
            : l10n.notificationSettingsMessagesNeedsGlobal,
        value: messagesEnabled && globalOn,
        onChanged: busy || !pushOn || !globalOn
            ? null
            : (v) => context
                  .read<NotificationSettingsCubit>()
                  .setMessagesEnabled(v),
      ),
    );
  }
}

class _FilterAlertsNotificationsCard extends StatelessWidget {
  const _FilterAlertsNotificationsCard({
    required this.pushOn,
    required this.busy,
    required this.globalOn,
    required this.filterAlertsEnabled,
  });

  final bool pushOn;
  final bool busy;
  final bool globalOn;
  final bool filterAlertsEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return NotificationSettingsSectionCard(
      key: const ValueKey<String>('notification_settings_filter_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotificationSwitchRow(
            icon: CarzonIcons.filter,
            title: l10n.notificationSettingsFilterAlertsTitle,
            subtitle: globalOn
                ? l10n.notificationSettingsFilterAlertsSubtitle
                : l10n.notificationSettingsFilterAlertsNeedsGlobal,
            value: filterAlertsEnabled && globalOn,
            onChanged: busy || !pushOn || !globalOn
                ? null
                : (v) => context
                      .read<NotificationSettingsCubit>()
                      .setFilterAlertsEnabled(v),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.notificationSettingsFilterAlertsSavedFilterNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              height: 1.32,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey<String>('notification_settings_filter_cta'),
              onPressed: () => context.push(AppRoutes.filterAlert),
              child: Text(l10n.notificationSettingsFilterAlertsOpenCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitchRow extends StatelessWidget {
  const _NotificationSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 22,
            color: AppTheme.editorialAccentColor(scheme).withValues(
              alpha: theme.brightness == Brightness.light ? 0.95 : 0.88,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

String? _noticeMessage(AppLocalizations l10n, NotificationUserNotice notice) {
  return switch (notice) {
    NotificationUserNotice.osPermissionDenied =>
      l10n.notificationSettingsOsPermissionDenied,
    NotificationUserNotice.loadFailed => l10n.notificationSettingsLoadFailed,
    NotificationUserNotice.saveFailed => l10n.notificationSettingsSaveFailed,
    NotificationUserNotice.pushUnavailableInBuild =>
      l10n.notificationSettingsPushUnavailableInBuild,
    NotificationUserNotice.none => null,
  };
}
