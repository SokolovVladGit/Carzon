import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/filter_alert_settings_cubit.dart';
import '../widgets/filter_alert_criteria_summary.dart';

String? _filterAlertNoticeMessage(
  AppLocalizations l10n,
  FilterAlertSettingsUserNotice notice,
) {
  return switch (notice) {
    FilterAlertSettingsUserNotice.osPermissionDenied =>
      l10n.notificationSettingsOsPermissionDenied,
    FilterAlertSettingsUserNotice.pushUnavailableInBuild =>
      l10n.notificationSettingsPushUnavailableInBuild,
    FilterAlertSettingsUserNotice.saveFilterBeforeNotifications =>
      l10n.filterAlertNotificationsNeedsSavedFilter,
    FilterAlertSettingsUserNotice.prefsUpdateFailed =>
      l10n.notificationSettingsSaveFailed,
    FilterAlertSettingsUserNotice.none => null,
  };
}

/// Phase 3 lightweight alert-management surface.
///
/// `/filter-alert` no longer duplicates the catalog filter editor.
/// It loads the user's saved filter-alert row, surfaces a read-only
/// criteria summary, and offers focused actions:
///
/// * **Edit in catalog** – navigates to the listings feed seeded with the
///   saved criteria and auto-opens the filter sheet so the user edits the
///   alert exactly where catalog filters are configured.
/// * **Disable deliveries** – flips `filter_alert_settings.notifications_enabled`
///   only; saved criteria stay intact.
/// * **Delete saved filter** – clears `filter_alert_settings.criteria` after
///   a confirmation dialog.
///
/// Push-disabled builds keep the existing semantics: no permission prompt,
/// no FirebaseMessaging access, localized notice surfaced.
class FilterAlertSettingsPage extends StatelessWidget {
  const FilterAlertSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final l10n = context.l10n;
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallback: AppRoutes.profile),
              title: Text(l10n.filterAlertEditorTitle),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.filterAlertSignInRequired,
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
          create: (_) => sl<FilterAlertSettingsCubit>()..refresh(),
          child: const _FilterAlertManagementBody(),
        );
      },
    );
  }
}

class _FilterAlertManagementBody extends StatelessWidget {
  const _FilterAlertManagementBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FilterAlertSettingsCubit, FilterAlertSettingsState>(
      listenWhen: (previous, current) =>
          previous.userNotice != current.userNotice &&
          current.userNotice != FilterAlertSettingsUserNotice.none,
      listener: (context, state) {
        final text = _filterAlertNoticeMessage(l10n, state.userNotice);
        if (text != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
        }
        context.read<FilterAlertSettingsCubit>().clearUserNotice();
      },
      builder: (context, state) {
        AppBar chromeAppBar() => AppBar(
              leading: const AppBackButton(fallback: AppRoutes.profile),
              title: Text(l10n.filterAlertEditorTitle),
              elevation: 0,
              scrolledUnderElevation: 0,
            );

        switch (state.status) {
          case FilterAlertSettingsLoadStatus.initial:
          case FilterAlertSettingsLoadStatus.loading:
            return Scaffold(
              appBar: chromeAppBar(),
              body: const LoadingView(),
            );
          case FilterAlertSettingsLoadStatus.failure:
            return Scaffold(
              appBar: chromeAppBar(),
              body: ErrorView(
                message: l10n.filterAlertLoadFailed,
                onRetry:
                    () => context.read<FilterAlertSettingsCubit>().refresh(),
              ),
            );
          case FilterAlertSettingsLoadStatus.loaded:
            return Scaffold(
              appBar: chromeAppBar(),
              body: _ManagementContent(state: state),
            );
        }
      },
    );
  }
}

class _ManagementContent extends StatelessWidget {
  const _ManagementContent({required this.state});

  final FilterAlertSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final settings = state.settings;
    final criteria = settings?.criteria;
    final hasCriteria = criteria != null;

    final pushOn = Env.pushNotificationsEnabled;
    final deliveryOn =
        hasCriteria && (settings?.notificationsEnabled == true) && pushOn;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            l10n.filterAlertManagementHeaderEyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.filterAlertManagementSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 20),
          if (!hasCriteria)
            _EmptyAlertCard()
          else ...[
            _DeliveryStatusStrip(
              state: state,
              deliveryOn: deliveryOn,
              pushOn: pushOn,
            ),
            const SizedBox(height: 14),
            FilterAlertCriteriaSummary(criteria: criteria),
            const SizedBox(height: 16),
            _ManagementActions(state: state, deliveryOn: deliveryOn),
          ],
        ],
      ),
    );
  }
}

class _EmptyAlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey<String>('filter_alert_management_empty_card'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.filterAlertManagementEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.filterAlertManagementEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.36,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey<String>(
              'filter_alert_management_go_to_catalog',
            ),
            onPressed: () => context.go(AppRoutes.listings),
            child: Text(l10n.filterAlertManagementGoToCatalog),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStatusStrip extends StatelessWidget {
  const _DeliveryStatusStrip({
    required this.state,
    required this.deliveryOn,
    required this.pushOn,
  });

  final FilterAlertSettingsState state;
  final bool deliveryOn;
  final bool pushOn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCriteria = state.settings?.criteria != null;

    final subtitle = !pushOn
        ? l10n.filterAlertNotificationsPushDisabled
        : !hasCriteria
            ? l10n.filterAlertNotificationsNeedsSavedFilter
            : l10n.filterAlertNotificationsToggleSubtitle;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            l10n.filterAlertNotificationsToggleTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(subtitle),
          value: deliveryOn,
          onChanged: !pushOn ||
                  !hasCriteria ||
                  state.busyNotificationToggle ||
                  state.busyClearing
              ? null
              : (enabled) async {
                  final cubit = context.read<FilterAlertSettingsCubit>();
                  if (enabled) {
                    await cubit.enableFilterAlertNotifications();
                  } else {
                    await cubit.disableFilterAlertNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.filterAlertManagementDeliveryDisabledSnack,
                          ),
                        ),
                      );
                    }
                  }
                },
        ),
      ),
    );
  }
}

class _ManagementActions extends StatelessWidget {
  const _ManagementActions({required this.state, required this.deliveryOn});

  final FilterAlertSettingsState state;
  final bool deliveryOn;

  Future<void> _onEdit(BuildContext context) async {
    final criteria = state.settings?.criteria;
    if (criteria == null) {
      context.go(AppRoutes.listings);
      return;
    }
    context.go(
      AppRoutes.listings,
      extra: ListingsFeedLaunch(
        snapshot: criteria,
        openFilterSheetOnEntry: true,
      ),
    );
  }

  Future<void> _onDisable(BuildContext context) async {
    final cubit = context.read<FilterAlertSettingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await cubit.disableFilterAlertNotifications();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.filterAlertManagementDeliveryDisabledSnack),
          ),
        );
      case FailureResult():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.notificationSettingsSaveFailed)),
        );
    }
  }

  Future<void> _onClear(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.filterAlertManagementClearConfirmTitle),
        content: Text(l10n.filterAlertManagementClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const ValueKey<String>(
              'filter_alert_management_clear_confirm_cta',
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.filterAlertManagementClearConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final cubit = context.read<FilterAlertSettingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.clearPersistedCriteria();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.filterAlertManagementClearedSnack)),
        );
      case FailureResult():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.filterAlertResetFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = state.busyClearing || state.busyNotificationToggle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey<String>('filter_alert_management_edit_action'),
          onPressed: busy ? null : () => _onEdit(context),
          icon: const Icon(Icons.tune_rounded),
          label: Text(l10n.filterAlertManagementEditAction),
        ),
        const SizedBox(height: 10),
        if (deliveryOn)
          OutlinedButton.icon(
            key: const ValueKey<String>(
              'filter_alert_management_disable_action',
            ),
            onPressed: busy ? null : () => _onDisable(context),
            icon: const Icon(Icons.notifications_off_outlined),
            label: Text(l10n.filterAlertManagementDisableAction),
          ),
        if (deliveryOn) const SizedBox(height: 10),
        TextButton.icon(
          key: const ValueKey<String>('filter_alert_management_clear_action'),
          onPressed: busy ? null : () => _onClear(context),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.filterAlertManagementClearAction),
        ),
      ],
    );
  }
}
