import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/saved_search.dart';
import '../cubit/saved_searches_cubit.dart';
import '../widgets/filter_alert_criteria_summary.dart';

String? _savedSearchesNoticeMessage(
  AppLocalizations l10n,
  SavedSearchesUserNotice notice,
) {
  return switch (notice) {
    SavedSearchesUserNotice.osPermissionDenied =>
      l10n.notificationSettingsOsPermissionDenied,
    SavedSearchesUserNotice.pushUnavailableInBuild =>
      l10n.notificationSettingsPushUnavailableInBuild,
    SavedSearchesUserNotice.prefsUpdateFailed =>
      l10n.notificationSettingsSaveFailed,
    SavedSearchesUserNotice.none => null,
  };
}

/// Saved searches manager (`/filter-alert`).
class FilterAlertSettingsPage extends StatelessWidget {
  const FilterAlertSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final l10n = context.l10n;
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: AppBar(
              leading: const AppBackButton(fallback: AppRoutes.profile),
              title: Text(l10n.savedSearchesTitle),
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: scheme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
            ),
            body: AuthRequiredPrompt(
              message: l10n.savedSearchesSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
            ),
          );
        }
        return BlocProvider(
          create: (_) => sl<SavedSearchesCubit>()..refresh(),
          child: const _SavedSearchesBody(),
        );
      },
    );
  }
}

class _SavedSearchesBody extends StatelessWidget {
  const _SavedSearchesBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBar chromeAppBar() => AppBar(
      leading: const AppBackButton(fallback: AppRoutes.profile),
      title: Text(l10n.savedSearchesTitle),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    Widget chromeScaffold({required Widget body, required AppBar appBar}) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: appBar,
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
            color: isDark ? null : scheme.surface,
          ),
          child: body,
        ),
      );
    }

    return BlocConsumer<SavedSearchesCubit, SavedSearchesState>(
      listenWhen: (previous, current) =>
          previous.userNotice != current.userNotice &&
          current.userNotice != SavedSearchesUserNotice.none,
      listener: (context, state) {
        final text = _savedSearchesNoticeMessage(l10n, state.userNotice);
        if (text != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text)));
        }
        context.read<SavedSearchesCubit>().clearUserNotice();
      },
      builder: (context, state) {
        final appBar = chromeAppBar();
        switch (state.status) {
          case SavedSearchesLoadStatus.initial:
          case SavedSearchesLoadStatus.loading:
            return chromeScaffold(appBar: appBar, body: const LoadingView());
          case SavedSearchesLoadStatus.failure:
            return chromeScaffold(
              appBar: appBar,
              body: ErrorView(
                message: l10n.savedSearchesLoadFailed,
                onRetry: () => context.read<SavedSearchesCubit>().refresh(),
              ),
            );
          case SavedSearchesLoadStatus.loaded:
            return chromeScaffold(
              appBar: appBar,
              body: _SavedSearchesContent(state: state),
            );
        }
      },
    );
  }
}

class _SavedSearchesContent extends StatelessWidget {
  const _SavedSearchesContent({required this.state});

  final SavedSearchesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pushOn = Env.pushNotificationsEnabled;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            l10n.savedSearchesHeaderEyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.savedSearchesSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.savedSearchesMaxHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (state.savedSearches.isEmpty)
            _EmptySavedSearchesCard()
          else
            ...state.savedSearches.map(
              (SavedSearch row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SavedSearchTile(
                  row: row,
                  pushOn: pushOn,
                  toggling: state.isToggling(row.id),
                  deleting: state.isDeleting(row.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySavedSearchesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey<String>('saved_searches_empty_card'),
      decoration: AppTheme.filterAlertManagementSurface(scheme),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.savedSearchesEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.savedSearchesEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.36,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey<String>('saved_searches_go_to_catalog'),
            onPressed: () => context.go(AppRoutes.listings),
            child: Text(l10n.savedSearchesGoToCatalog),
          ),
        ],
      ),
    );
  }
}

class _SavedSearchTile extends StatelessWidget {
  const _SavedSearchTile({
    required this.row,
    required this.pushOn,
    required this.toggling,
    required this.deleting,
  });

  final SavedSearch row;
  final bool pushOn;
  final bool toggling;
  final bool deleting;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.savedSearchDeleteConfirmTitle),
        content: Text(l10n.savedSearchDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const ValueKey<String>('saved_search_delete_confirm_cta'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.savedSearchDeleteConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cubit = context.read<SavedSearchesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.deleteSavedSearch(row.id);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedSearchRemovedSnack)),
        );
      case FailureResult():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedSearchDeleteFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = toggling || deleting;
    final deliveryOn = pushOn && row.alertsEnabled;

    return Container(
      decoration: AppTheme.filterAlertManagementSurface(scheme),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey<String>('saved_search_delete_${row.id}'),
                tooltip: l10n.savedSearchDeleteAction,
                onPressed: busy ? null : () => _confirmDelete(context),
                icon: deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
              ),
            ],
          ),
          FilterAlertCriteriaSummary(criteria: row.criteria),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.savedSearchAlertsToggleTitle),
            subtitle: Text(
              !pushOn
                  ? l10n.filterAlertNotificationsPushDisabled
                  : deliveryOn
                  ? l10n.savedSearchAlertsEnabledLabel
                  : l10n.savedSearchAlertsDisabledLabel,
            ),
            value: deliveryOn,
            onChanged: !pushOn || busy
                ? null
                : (enabled) async {
                    final cubit = context.read<SavedSearchesCubit>();
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await cubit.setAlertsEnabled(
                      row.id,
                      enabled,
                    );
                    if (!context.mounted) return;
                    switch (result) {
                      case Success():
                        break;
                      case FailureResult():
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.savedSearchToggleFailed)),
                        );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
