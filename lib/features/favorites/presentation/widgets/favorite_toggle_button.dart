import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';

class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({super.key, required this.listingId});

  final String listingId;

  void _handleTap(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to favorite listings.'),
          action: SnackBarAction(
            label: 'Sign in',
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
    return BlocConsumer<FavoritesCubit, FavoritesState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      },
      buildWhen: (prev, curr) =>
          prev.isFavorite(listingId) != curr.isFavorite(listingId) ||
          prev.isPending(listingId) != curr.isPending(listingId),
      builder: (context, state) {
        final isFav = state.isFavorite(listingId);
        final pending = state.isPending(listingId);
        return IconButton(
          tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
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
