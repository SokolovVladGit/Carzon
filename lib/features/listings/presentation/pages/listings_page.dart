import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../bloc/listings_bloc.dart';
import '../bloc/listings_event.dart';
import '../bloc/listings_state.dart';
import '../widgets/listing_tile.dart';

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ListingsBloc>()..add(const ListingsRequested()),
      child: const _ListingsView(),
    );
  }
}

class _ListingsView extends StatefulWidget {
  const _ListingsView();

  @override
  State<_ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<_ListingsView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final threshold = _scrollCtrl.position.maxScrollExtent - 200;
    if (_scrollCtrl.position.pixels >= threshold) {
      context.read<ListingsBloc>().add(const ListingsNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carzon'),
        actions: [
          IconButton(
            tooltip: 'Sell a car',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.go(AppRoutes.createListing),
          ),
          IconButton(
            tooltip: 'My listings',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => context.go(AppRoutes.myListings),
          ),
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.go(AppRoutes.favorites),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          switch (state.status) {
            case ListingsStatus.initial:
            case ListingsStatus.loading:
              return const LoadingView();
            case ListingsStatus.failure:
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load listings.',
                onRetry: () =>
                    context.read<ListingsBloc>().add(const ListingsRefreshed()),
              );
            case ListingsStatus.success:
            case ListingsStatus.loadingMore:
              if (state.items.isEmpty) {
                return const Center(child: Text('No listings yet.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ListingsBloc>().add(const ListingsRefreshed());
                },
                child: ListView.separated(
                  controller: _scrollCtrl,
                  itemCount: state.items.length + (state.hasReachedEnd ? 0 : 1),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = state.items[index];
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
      ),
    );
  }
}
