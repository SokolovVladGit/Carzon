import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';

class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({super.key, required this.listingId});

  final String listingId;

  void _handleTap(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final l10n = context.l10n;
    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.favoriteSignInRequired),
          action: SnackBarAction(
            label: l10n.commonSignIn,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ),
      );
      return;
    }
    context.read<FavoritesCubit>().toggle(listingId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FavoritesCubit, FavoritesState>(
      listenWhen: (prev, curr) =>
          prev.lastError != curr.lastError && curr.lastError != null,
      listener: (context, state) {
        final err = state.lastError;
        if (err == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_favoritesErrorMessage(l10n, err.kind))),
        );
      },
      buildWhen: (prev, curr) =>
          prev.isFavorite(listingId) != curr.isFavorite(listingId) ||
          prev.isPending(listingId) != curr.isPending(listingId),
      builder: (context, state) {
        final isFav = state.isFavorite(listingId);
        final pending = state.isPending(listingId);
        return IconButton(
          tooltip: isFav ? l10n.favoriteRemove : l10n.favoriteAdd,
          onPressed: pending ? null : () => _handleTap(context),
          icon: pending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
        );
      },
    );
  }
}

String _favoritesErrorMessage(AppLocalizations l10n, FavoritesFailureKind kind) {
  return switch (kind) {
    FavoritesFailureKind.loadFailed => l10n.favoritesLoadFailed,
    FavoritesFailureKind.toggleFailed => l10n.favoriteToggleFailed,
  };
}
