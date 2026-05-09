import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/listing_discovery_state_sync.dart';
import '../../../listings/presentation/bloc/listings_state.dart';
import '../../../listings/presentation/utils/listing_filter_apply_to_criteria.dart';
import '../../../listings/presentation/widgets/filters/listings_filter_form_seed.dart';
import '../../../listings/presentation/widgets/filters/listings_filter_host.dart';
import '../cubit/filter_alert_settings_cubit.dart';

/// Clears persisted alert criteria (`criteria` null) after local draft reset.
Future<void> _persistClearAlertFilter(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final cubit = context.read<FilterAlertSettingsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await cubit.clearPersistedCriteria();
  if (!context.mounted) return;
  switch (result) {
    case Success():
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.filterAlertResetPersistedSuccess)),
      );
    case FailureResult():
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.filterAlertResetFailed)),
      );
  }
}

void _popFilterAlertRoute(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
    return;
  }
  GoRouter.maybeOf(context)?.go(AppRoutes.profile);
}

/// Opens directly into [ListingsFilterHost] alert editor (single filter for
/// future notifications). Auth users load existing criteria first; `/filter-alert`
/// is not an intermediate summary page.
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
          child: const _FilterAlertDirectEditorBody(),
        );
      },
    );
  }
}

class _FilterAlertDirectEditorBody extends StatelessWidget {
  const _FilterAlertDirectEditorBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FilterAlertSettingsCubit, FilterAlertSettingsState>(
      buildWhen: (previous, current) {
        if (previous.status != current.status) return true;
        return previous.settings != current.settings;
      },
      builder: (context, state) {
        AppBar chromeAppBar(AppLocalizations strings) =>
            AppBar(
              leading: const AppBackButton(fallback: AppRoutes.profile),
              title: Text(strings.filterAlertEditorTitle),
              elevation: 0,
              scrolledUnderElevation: 0,
            );

        switch (state.status) {
          case FilterAlertSettingsLoadStatus.initial:
          case FilterAlertSettingsLoadStatus.loading:
            return Scaffold(
              appBar: chromeAppBar(l10n),
              body: const LoadingView(),
            );
          case FilterAlertSettingsLoadStatus.failure:
            return Scaffold(
              appBar: chromeAppBar(l10n),
              body: ErrorView(
                message: l10n.filterAlertLoadFailed,
                onRetry:
                    () => context.read<FilterAlertSettingsCubit>().refresh(),
              ),
            );
          case FilterAlertSettingsLoadStatus.loaded:
            final criteria = state.settings?.criteria;
            final preservedSearch = criteria?.search;
            final snapshotForSuccessCopy = state.hasBackendRow;
            final hostKey = ValueKey(
              Object.hash(
                state.settings?.userId,
                state.settings?.updatedAt,
                state.settings?.criteria,
              ),
            );
            final seedListingsState =
                criteria == null
                    ? const ListingsState()
                    : listingsStateFromDiscoveryCriteria(criteria);

            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: ListingsFilterHost(
                key: hostKey,
                mode: ListingsFilterHostMode.alertSetup,
                seed: ListingsFilterFormSeed.fromListingsState(
                  seedListingsState,
                ),
                onDismiss: () {
                  _popFilterAlertRoute(context);
                },
                onAlertResetPersist: () =>
                    _persistClearAlertFilter(context, l10n),
                onApplyBlockedByValidation: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.filterAlertApplyBlockedValidation),
                    ),
                  );
                },
                onApply: (r) async {
                  final cubit = context.read<FilterAlertSettingsCubit>();
                  final messenger = ScaffoldMessenger.of(context);

                  if (r.cleared) {
                    await _persistClearAlertFilter(context, l10n);
                    return;
                  }

                  final next = listingDiscoveryCriteriaFromFilterApply(
                    r,
                    preservedSearch: preservedSearch,
                  );
                  final result = await cubit.save(next);

                  switch (result) {
                    case Success():
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            snapshotForSuccessCopy
                                ? l10n.filterAlertUpdatedSuccess
                                : l10n.filterAlertSavedSuccess,
                          ),
                        ),
                      );
                      if (context.mounted) _popFilterAlertRoute(context);
                    case FailureResult():
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.filterAlertSaveFailed)),
                      );
                  }
                },
              ),
            );
        }
      },
    );
  }
}
