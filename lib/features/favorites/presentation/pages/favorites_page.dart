import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/presentation/widgets/listing_tile.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated) {
            return _SignInRequired(
              onSignIn: () => context.go(AppRoutes.signIn),
            );
          }
          return const _FavoritesList();
        },
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Sign in to view your favorite listings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSignIn, child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatefulWidget {
  const _FavoritesList();

  @override
  State<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList> {
  @override
  void initState() {
    super.initState();
    // Always refresh on entering the page so newly toggled items appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesCubit>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        switch (state.status) {
          case FavoritesStatus.unknown:
          case FavoritesStatus.loading:
            return const LoadingView();
          case FavoritesStatus.failure:
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load favorites.',
              onRetry: () => context.read<FavoritesCubit>().loadListings(),
            );
          case FavoritesStatus.ready:
            if (state.listings.isEmpty) {
              return const Center(child: Text('No favorites yet.'));
            }
            return RefreshIndicator(
              onRefresh: () => context.read<FavoritesCubit>().loadListings(),
              child: ListView.separated(
                itemCount: state.listings.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = state.listings[index];
                  return ListingTile(
                    listing: item,
                    onTap: () =>
                        context.go(AppRoutes.listingDetailsPath(item.id)),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
