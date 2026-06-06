import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/presentation/widgets/listing_card.dart';
import '../bloc/my_listings_cubit.dart';
import '../bloc/my_listings_state.dart';
import '../widgets/my_listing_tile.dart';
import '../widgets/my_listings_empty_state.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TopLevelScaffold(
      destination: TopLevelDestination.menu,
      backgroundColor: isDark ? scheme.surface : null,
      appBar: AppBar(title: Text(l10n.myListingsTitle)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated ||
              authState.user == null) {
            return AuthRequiredPrompt(
              icon: const Icon(Icons.directions_car_filled_outlined, size: 48),
              message: l10n.myListingsSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: () => context.go(AppRoutes.signIn),
            );
          }
          return BlocProvider(
            create: (_) => sl<MyListingsCubit>()..load(authState.user!.id),
            child: _MyListingsView(sellerId: authState.user!.id),
          );
        },
      ),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView({required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<MyListingsCubit, MyListingsState>(
      listenWhen: (prev, curr) => prev.lastActionError != curr.lastActionError,
      listener: (context, state) {
        final err = state.lastActionError;
        if (err == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_actionErrorMessage(l10n, err.kind))),
          );
        context.read<MyListingsCubit>().acknowledgeActionError();
      },
      child: BlocBuilder<MyListingsCubit, MyListingsState>(
        builder: (context, state) {
          switch (state.status) {
            case MyListingsStatus.initial:
            case MyListingsStatus.loading:
              return const LoadingView();
            case MyListingsStatus.failure:
              return ErrorView(
                message: l10n.myListingsLoadFailed,
                onRetry: () => context.read<MyListingsCubit>().load(sellerId),
              );
            case MyListingsStatus.success:
              if (state.items.isEmpty) {
                return MyListingsEmptyState(
                  onCreate: () => context.go(AppRoutes.createListing),
                );
              }
              return RefreshIndicator(
                onRefresh: () => context.read<MyListingsCubit>().load(sellerId),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    kFloatingCapsuleNavClearance,
                  ),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 28),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final pending =
                        state.pendingStatusIds.contains(item.id) ||
                        state.pendingDeleteIds.contains(item.id);
                    return MyListingTile(
                      listing: item,
                      isPending: pending,
                      onAction: (action) =>
                          _handleAction(context, item.id, action),
                      onTap: () => context.push(
                        AppRoutes.listingDetailsPath(item.id),
                        extra: ListingDetailsExtra(
                          coverImageUrl: item.coverImageUrl,
                          coverHeroFlightTopRadius:
                              ListingCard.coverHeroFlightTopRadius(
                                ListingCardVariant.regular,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

/// Routes a [MyListingAction] to either navigation, a status update,
/// or a permanent delete. Delete goes through a modal confirmation
/// dialog; other actions are dispatched directly to the cubit as
/// before.
Future<void> _handleAction(
  BuildContext context,
  String listingId,
  MyListingAction action,
) async {
  if (action == MyListingAction.edit) {
    context.push(AppRoutes.editListingPath(listingId));
    return;
  }
  if (action == MyListingAction.deletePermanently) {
    final confirmed = await showDeleteListingDialog(context);
    if (!confirmed) return;
    if (!context.mounted) return;
    await context.read<MyListingsCubit>().deleteListing(listingId);
    return;
  }
  final target = statusTargetFor(action);
  if (target != null) {
    await context.read<MyListingsCubit>().updateStatus(listingId, target);
  }
}

/// Confirmation dialog shown before calling the permanent-delete RPC.
///
/// Exposed at library level so widget tests can pump a host that opens
/// the dialog directly without reaching into `_handleAction`.
/// Resolves to `true` when the user taps Delete, `false` for Cancel,
/// dismiss, or back-press.
Future<bool> showDeleteListingDialog(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final errorColor = Theme.of(ctx).colorScheme.error;
      return AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(l10n.deleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Maps a [MyListingActionFailureKind] to a localized snackbar message.
/// Kept at library level so tests can assert the mapping without
/// pumping the full page.
String _actionErrorMessage(
  AppLocalizations l10n,
  MyListingActionFailureKind kind,
) {
  return switch (kind) {
    MyListingActionFailureKind.statusNotAllowed => l10n.notAllowedUpdateStatus,
    MyListingActionFailureKind.statusInvalid => l10n.statusNotSupported,
    MyListingActionFailureKind.statusGeneric => l10n.updateStatusFailedRetry,
    MyListingActionFailureKind.deleteNotAllowed => l10n.notAllowedDelete,
    MyListingActionFailureKind.deleteNotFound => l10n.listingNotFound,
    MyListingActionFailureKind.deleteGeneric => l10n.deleteListingFailedRetry,
  };
}
