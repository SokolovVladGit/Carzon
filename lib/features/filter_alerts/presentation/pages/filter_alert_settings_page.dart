import 'dart:async';

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
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import '../../domain/entities/saved_search.dart';
import '../cubit/saved_searches_cubit.dart';
import '../utils/saved_search_display_title.dart';
import '../widgets/filter_alert_criteria_summary.dart';

String? _savedSearchesNoticeMessage(
  AppLocalizations l10n,
  SavedSearchesUserNotice notice,
) {
  return switch (notice) {
    SavedSearchesUserNotice.osPermissionDenied =>
      l10n.notificationSettingsOsPermissionDenied,
    SavedSearchesUserNotice.pushUnavailableInBuild => null,
    SavedSearchesUserNotice.prefsUpdateFailed =>
      l10n.notificationSettingsSaveFailed,
    SavedSearchesUserNotice.none => null,
  };
}

void _refreshCatalogSavedSearchStateIfRegistered() {
  if (sl.isRegistered<BrowseCatalogFilterAlertsCubit>()) {
    unawaited(sl<BrowseCatalogFilterAlertsCubit>().refresh());
  }
}

/// Filter alerts manager (`/filter-alert`).
class FilterAlertSettingsPage extends StatelessWidget {
  const FilterAlertSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final l10n = context.l10n;
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return _FilterAlertsChrome(
            body: AuthRequiredPrompt(
              message: l10n.savedSearchesSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
            ),
          );
        }
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              _refreshCatalogSavedSearchStateIfRegistered();
            }
          },
          child: BlocProvider(
            create: (_) => sl<SavedSearchesCubit>()..refresh(),
            child: const _SavedSearchesBody(),
          ),
        );
      },
    );
  }
}

class _FilterAlertsChrome extends StatelessWidget {
  const _FilterAlertsChrome({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _pageBackground(context),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.profile),
        title: Text(l10n.savedSearchesTitle),
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
            colors: _canvasGradient(context),
            stops: const [0, 0.42, 1],
          ),
        ),
        child: body,
      ),
    );
  }
}

class _SavedSearchesBody extends StatelessWidget {
  const _SavedSearchesBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
        return _FilterAlertsChrome(
          body: switch (state.status) {
            SavedSearchesLoadStatus.initial ||
            SavedSearchesLoadStatus.loading => const LoadingView(),
            SavedSearchesLoadStatus.failure => ErrorView(
              message: l10n.savedSearchesLoadFailed,
              onRetry: () => context.read<SavedSearchesCubit>().refresh(),
            ),
            SavedSearchesLoadStatus.loaded => _SavedSearchesContent(state: state),
          },
        );
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
    final atCap = state.savedSearches.length >= SavedSearchesLimits.maxPerUser;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottomInset),
        children: [
          Text(
            l10n.savedSearchesHeaderEyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppTheme.editorialAccentColor(scheme).withValues(
                alpha: theme.brightness == Brightness.light ? 0.95 : 0.88,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.savedSearchesSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.savedSearchesMaxHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
            ),
          ),
          if (atCap) ...[
            const SizedBox(height: 12),
            _MaxLimitCallout(message: l10n.savedSearchesMaxReachedHint),
          ],
          const SizedBox(height: 16),
          const _HowToAddFilterCallout(),
          const SizedBox(height: 20),
          if (state.savedSearches.isEmpty)
            _EmptySavedSearchesCard()
          else
            ...state.savedSearches.map(
              (SavedSearch row) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
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

class _MaxLimitCallout extends StatelessWidget {
  const _MaxLimitCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey<String>('saved_searches_max_limit_callout'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(
          alpha: theme.brightness == Brightness.light ? 0.35 : 0.22,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.34,
        ),
      ),
    );
  }
}

class _HowToAddFilterCallout extends StatelessWidget {
  const _HowToAddFilterCallout();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = AppTheme.editorialAccentColor(scheme);

    return Container(
      key: const ValueKey<String>('saved_searches_how_to_add_callout'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: theme.brightness == Brightness.light ? 0.72 : 0.55,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              CarzonIcons.notificationsOutline,
              size: 20,
              color: accent.withValues(
                alpha: theme.brightness == Brightness.light ? 0.88 : 0.82,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedSearchesHowToAddTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.savedSearchesHowToAddBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.36,
                  ),
                ),
              ],
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
      decoration: AppTheme.filterAlertManagementSurface(scheme, borderRadius: 20),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.savedSearchesEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.savedSearchesEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 18),
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
        _refreshCatalogSavedSearchStateIfRegistered();
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
    final displayTitle = buildSavedSearchDisplayTitle(l10n, row.criteria);

    return Container(
      decoration: AppTheme.filterAlertManagementSurface(scheme, borderRadius: 20),
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.savedSearchCardCaption,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey<String>('saved_search_delete_${row.id}'),
                tooltip: l10n.savedSearchDeleteAction,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: busy ? null : () => _confirmDelete(context),
                icon: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilterAlertCriteriaSummary(criteria: row.criteria),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.savedSearchAlertsToggleTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.savedSearchAlertsToggleSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (toggling)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Switch.adaptive(
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
                              _refreshCatalogSavedSearchStateIfRegistered();
                              break;
                            case FailureResult():
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.savedSearchToggleFailed),
                                ),
                              );
                          }
                        },
                ),
            ],
          ),
          if (!pushOn) ...[
            const SizedBox(height: 10),
            Text(
              l10n.savedSearchAlertsPushUnavailableHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _pageBackground(BuildContext context) {
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

List<Color> _canvasGradient(BuildContext context) {
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
