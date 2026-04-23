import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/my_listings_cubit.dart';
import '../bloc/my_listings_state.dart';
import '../widgets/my_listing_tile.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated || authState.user == null) {
            return _SignInRequired(onSignIn: () => context.go(AppRoutes.signIn));
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
            const Icon(Icons.directions_car_filled_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Sign in to see the listings you have published.',
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

class _MyListingsView extends StatelessWidget {
  const _MyListingsView({required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyListingsCubit, MyListingsState>(
      builder: (context, state) {
        switch (state.status) {
          case MyListingsStatus.initial:
          case MyListingsStatus.loading:
            return const LoadingView();
          case MyListingsStatus.failure:
            return ErrorView(
              message: state.errorMessage ?? 'Failed to load your listings.',
              onRetry: () => context.read<MyListingsCubit>().load(sellerId),
            );
          case MyListingsStatus.success:
            if (state.items.isEmpty) {
              return _EmptyState(
                onCreate: () => context.go(AppRoutes.createListing),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<MyListingsCubit>().load(sellerId),
              child: ListView.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return MyListingTile(
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'You have not published any listings yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Sell a car'),
            ),
          ],
        ),
      ),
    );
  }
}
