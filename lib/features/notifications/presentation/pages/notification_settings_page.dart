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
      backgroundColor: _notificationPageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.profile),
        title: Text(l10n.notificationSettingsTitle),
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
            colors: _notificationCanvasGradient(context),
            stops: const [0, 0.42, 1],
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
    final pushOn = Env.pushNotificationsEnabled;
    final prefs = state.preferences!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MessagesNotificationsCard(
            pushOn: pushOn,
            busy: state.busy,
            messagesEnabled: prefs.messagesEnabled,
          ),
          const SizedBox(height: 14),
          const _SavedSearchAlertsNote(),
        ],
      ),
    );
  }
}

class _MessagesNotificationsCard extends StatelessWidget {
  const _MessagesNotificationsCard({
    required this.pushOn,
    required this.busy,
    required this.messagesEnabled,
  });

  final bool pushOn;
  final bool busy;
  final bool messagesEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NotificationSettingsSectionCard(
      key: const ValueKey<String>('notification_settings_messages_card'),
      child: _NotificationSwitchRow(
        icon: CarzonIcons.chat,
        title: l10n.notificationSettingsMessagesTitle,
        subtitle: l10n.notificationSettingsMessagesSubtitle,
        value: messagesEnabled,
        onChanged: busy || !pushOn
            ? null
            : (v) => context
                  .read<NotificationSettingsCubit>()
                  .setMessagesEnabled(v),
      ),
    );
  }
}

class _SavedSearchAlertsNote extends StatelessWidget {
  const _SavedSearchAlertsNote();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        l10n.notificationSettingsSavedSearchAlertsNote,
        key: const ValueKey<String>(
          'notification_settings_saved_search_alerts_note',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
          height: 1.38,
        ),
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
    NotificationUserNotice.pushUnavailableInBuild ||
    NotificationUserNotice.none => null,
  };
}

Color _notificationPageBackground(BuildContext context) {
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

List<Color> _notificationCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  if (isDark) {
    return AppTheme.editorialDarkFilterCanvasGradient(scheme);
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
