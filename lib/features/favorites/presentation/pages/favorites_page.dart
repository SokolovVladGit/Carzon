import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/presentation/widgets/listing_tile.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';
import '../widgets/favorites_empty_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TopLevelScaffold(
      destination: TopLevelDestination.favorites,
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
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
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CarzonIcons.heartOutline, size: 48),
            const SizedBox(height: 12),
            Text(l10n.favoritesSignInRequired, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSignIn, child: Text(l10n.commonSignIn)),
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
    final l10n = context.l10n;
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        switch (state.status) {
          case FavoritesStatus.unknown:
          case FavoritesStatus.loading:
            return const LoadingView();
          case FavoritesStatus.failure:
            return ErrorView(
              message: l10n.favoritesLoadFailed,
              onRetry: () => context.read<FavoritesCubit>().loadListings(),
            );
          case FavoritesStatus.ready:
            if (state.listings.isEmpty) {
              return FavoritesEmptyState(
                onRefresh: () => context.read<FavoritesCubit>().loadListings(),
                onBrowseListings: () => context.go(AppRoutes.listings),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<FavoritesCubit>().loadListings(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  kFloatingCapsuleNavClearance,
                ),
                itemCount: state.listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 28),
                itemBuilder: (context, index) {
                  final item = state.listings[index];
                  return ListingTile(
                    listing: item,
                    onTap: () => context.push(
                      AppRoutes.listingDetailsPath(item.id),
                      extra: ListingDetailsExtra(
                        coverImageUrl: item.coverImageUrl,
                      ),
                    ),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
