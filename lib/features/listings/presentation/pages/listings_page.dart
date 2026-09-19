import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/presentation/localized_user_failure_message.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../domain/catalog/listing_brands.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../bloc/listings_bloc.dart';
import '../bloc/listings_event.dart';
import '../bloc/listings_state.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/browse_catalog_filter_alerts_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../sellers/presentation/bloc/self_seller_visual_cubit.dart';
import '../widgets/category_chip.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_tile.dart';
import '../widgets/listings_active_discovery_summary_strip.dart';
import '../widgets/listings_brand_filter_row.dart';
import '../widgets/listings_catalog_header.dart';
import '../widgets/listings_feed_empty_state.dart';
import '../utils/feed_home_body_chips.dart';

Future<void> _awaitListingsFeedRefresh(ListingsBloc bloc) async {
  bloc.add(const ListingsRefreshed());
  await bloc.stream.firstWhere(
    (state) => state.status != ListingsStatus.loading,
  );
}

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key, this.feedLaunch});

  final ListingsFeedLaunch? feedLaunch;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ListingsBloc>()),
        BlocProvider.value(value: sl<BrowseCatalogFilterAlertsCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) =>
                curr.publicFeedRefreshNonce > prev.publicFeedRefreshNonce,
            listener: (context, _) {
              context.read<ListingsBloc>().add(const ListingsRequested());
            },
          ),
        ],
        child: _ListingsDiscoveryBootstrap(
          feedLaunch: feedLaunch,
          child: const _ListingsView(),
        ),
      ),
    );
  }
}

class _ListingsDiscoveryBootstrap extends StatefulWidget {
  const _ListingsDiscoveryBootstrap({
    required this.feedLaunch,
    required this.child,
  });

  final ListingsFeedLaunch? feedLaunch;
  final Widget child;

  @override
  State<_ListingsDiscoveryBootstrap> createState() =>
      _ListingsDiscoveryBootstrapState();
}

class _ListingsDiscoveryBootstrapState
    extends State<_ListingsDiscoveryBootstrap> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_seed());
    });
  }

  Future<void> _seed() async {
    if (!mounted || _seeded) return;
    _seeded = true;
    final bloc = context.read<ListingsBloc>();
    final launch = widget.feedLaunch;
    if (launch != null) {
      bloc.add(ListingsHydratedFromDiscovery(launch.snapshot));
      if (launch.openFilterSheetOnEntry) {
        if (!mounted) return;
        context.go(AppRoutes.search, extra: launch.snapshot);
      }
      return;
    }
    final local = await sl<LastAppliedListingDiscoveryRepository>().load();
    if (!mounted) return;
    if (local != null) {
      bloc.add(ListingsHydratedFromDiscovery(local));
    } else {
      bloc.add(const ListingsRequested());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ListingsView extends StatefulWidget {
  const _ListingsView();

  @override
  State<_ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<_ListingsView> {
  final _scrollCtrl = ScrollController();

  /// Current feed scroll offset (pixels), mirrored from [_scrollCtrl]
  /// on every scroll tick. Piped into the featured tile's [ListingCard]
  /// so its cover photo parallaxes subtly as the feed scrolls. Only
  /// the featured card's image `Stack` listens — the rest of the
  /// feed has zero scroll-tick rebuild overhead.
  final ValueNotifier<double> _feedScrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      unawaited(context.read<SelfSellerVisualCubit>().prime(auth));
      unawaited(context.read<MessagingUnreadSummaryCubit>().sync(auth));
    });
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _feedScrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    _feedScrollOffset.value = _scrollCtrl.position.pixels;
    final status = context.read<ListingsBloc>().state.status;
    if (status != ListingsStatus.success &&
        status != ListingsStatus.loadingMore &&
        status != ListingsStatus.paginationFailure) {
      return;
    }
    final threshold = _scrollCtrl.position.maxScrollExtent - 200;
    if (_scrollCtrl.position.pixels >= threshold) {
      context.read<ListingsBloc>().add(const ListingsNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Warm editorial canvas in light mode (`scheme.surface`), theme surface in
    // dark. Avoids the colder pure-white feed that read as generic Material.
    final feedBackground = scheme.surface;
    return TopLevelScaffold(
      destination: TopLevelDestination.listings,
      backgroundColor: feedBackground,
      // Deliberately invisible AppBar: no title, no elevation, no
      // tint — it only exists so Scaffold keeps the correct status-bar
      // inset. The editorial `ListingsCatalogHeader` immediately below the
      // status bar carries the brand. Its background tracks the
      // scaffold's so the header and feed read as one canvas.
      appBar: AppBar(
        backgroundColor: feedBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          final scroll = CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FixedPinnedHeaderDelegate(
                  height: ListingsCatalogHeader.pinnedExtent,
                  child: const _PinnedMasthead(),
                ),
              ),
              SliverToBoxAdapter(
                child: _ScrollAwayDiscoveryRails(
                  onBrandSelected: _onBrandSelected,
                  showBottomShadow: !state.hasActiveDiscoveryConstraints,
                ),
              ),
              if (state.hasActiveDiscoveryConstraints)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FixedPinnedHeaderDelegate(
                    height: ListingsActiveDiscoverySummaryStrip.pinnedExtent,
                    child: _PinnedDiscoverySummary(state: state),
                  ),
                ),
              ..._feedSlivers(context, state),
            ],
          );
          switch (state.status) {
            case ListingsStatus.success:
            case ListingsStatus.loadingMore:
            case ListingsStatus.paginationFailure:
              return RefreshIndicator(
                onRefresh: () =>
                    _awaitListingsFeedRefresh(context.read<ListingsBloc>()),
                child: scroll,
              );
            case ListingsStatus.initial:
            case ListingsStatus.loading:
            case ListingsStatus.failure:
              return scroll;
          }
        },
      ),
    );
  }

  /// Dispatches a brand/make filter change from the horizontal brand
  /// row without touching the other filters. Passing `null` means
  /// "All brands" and clears the make.
  ///
  /// Re-uses the existing [ListingsFiltersApplied] event so the
  /// repository/query contract stays unchanged: only the `make`
  /// argument varies, all other filter dimensions are preserved
  /// from the current bloc state.
  void _onBrandSelected(String? brand) {
    final bloc = context.read<ListingsBloc>();
    final s = bloc.state;
    final current = s.make;
    // Short-circuit redundant taps using the same normalization as tile
    // selected-state (e.g. `mercedes benz` vs `Mercedes-Benz`).
    if (listingBrandFeedQuickFilterSelectionUnchanged(current, brand)) {
      return;
    }
    bloc.add(
      ListingsFiltersApplied(
        make: brand,
        model: s.model,
        minYear: s.minYear,
        maxYear: s.maxYear,
        minPrice: s.minPrice,
        maxPrice: s.maxPrice,
        maxMileage: s.maxMileage,
        city: s.city,
        typeFilter: s.typeFilter,
        sort: s.sortOption,
        regionFilter: s.regionFilter,
        bodyType: s.bodyTypeFilter,
        fuelType: s.fuelTypeFilter,
        transmissionType: s.transmissionTypeFilter,
        drivetrain: s.drivetrainFilter,
        priceCurrencyFilter: s.priceCurrencyFilter,
      ),
    );
  }

  double _feedPlaceholderHeight(BuildContext context) {
    final view = MediaQuery.sizeOf(context).height;
    return (view * 0.52).clamp(280.0, 720.0);
  }

  List<Widget> _feedSlivers(BuildContext context, ListingsState state) {
    switch (state.status) {
      case ListingsStatus.initial:
      case ListingsStatus.loading:
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: _feedPlaceholderHeight(context),
              child: const LoadingView(),
            ),
          ),
        ];
      case ListingsStatus.failure:
        final l10n = context.l10n;
        final msg = state.loadFailure != null
            ? localizedUserFailureMessage(
                l10n,
                state.loadFailure!,
                surface: LocalizedFailureSurface.listingsFeed,
              )
            : l10n.listingsLoadFailed;
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: _feedPlaceholderHeight(context),
              child: ErrorView(
                message: msg,
                onRetry: () =>
                    context.read<ListingsBloc>().add(const ListingsRefreshed()),
              ),
            ),
          ),
        ];
      case ListingsStatus.success:
      case ListingsStatus.loadingMore:
      case ListingsStatus.paginationFailure:
        if (state.items.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: SizedBox(
                height: _feedPlaceholderHeight(context),
                child: ListingsFeedEmptyState(
                  hasFilters: state.hasActiveDiscoveryConstraints,
                  includeBodyFilterEmptyHint: state.bodyTypeFilter != null,
                  embedInParentScroll: true,
                  onResetFilters: () {
                    context.read<ListingsBloc>().add(
                      const ListingsFiltersCleared(),
                    );
                  },
                  onRefresh: () =>
                      _awaitListingsFeedRefresh(context.read<ListingsBloc>()),
                ),
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            key: const ValueKey<String>('listingsFeedSliverPadding'),
            padding: const EdgeInsets.fromLTRB(
              20,
              6,
              20,
              kFloatingCapsuleNavClearance,
            ),
            sliver: SliverList.separated(
              itemCount: state.items.length + (state.hasReachedEnd ? 0 : 1),
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 18 : 16),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return _ListingsPaginationFooter(
                    state: state,
                    onRetry: () => context.read<ListingsBloc>().add(
                      const ListingsNextPageRequested(isExplicitRetry: true),
                    ),
                  );
                }
                final item = state.items[index];
                final isFeatured = index == 0;
                return _AppearAnimation(
                  key: ValueKey<String>('appear-${item.id}'),
                  delay: Duration(milliseconds: (index * 30).clamp(0, 120)),
                  child: ListingTile(
                    listing: item,
                    variant: isFeatured
                        ? ListingCardVariant.featured
                        : ListingCardVariant.regular,
                    coverParallax: isFeatured ? _feedScrollOffset : null,
                    onTap: () => context.push(
                      AppRoutes.listingDetailsPath(item.id),
                      extra: ListingDetailsExtra(
                        coverImageUrl: item.coverImageUrl,
                        coverHeroFlightTopRadius:
                            ListingCard.coverHeroFlightTopRadius(
                              isFeatured
                                  ? ListingCardVariant.featured
                                  : ListingCardVariant.regular,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ];
    }
  }
}

/// One-shot cinematic appear animation used for each tile as it first
/// builds into the home feed.
///
///   * opacity: 0 → 1
///   * translateY: +14 → 0
///   * 220 ms, `Curves.easeOutCubic`
///
/// Keyed by listing id at the call site so that [ListView]
/// recycling does NOT re-run the animation when the user scrolls
/// a previously-seen tile back into view — each card gets exactly
/// one entrance per logical identity.
///
/// A staggered `delay` is applied at the feed level so the first
/// few cards cascade in (20–30 ms between tiles) instead of
/// snapping in simultaneously.
class _AppearAnimation extends StatefulWidget {
  const _AppearAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<_AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<_AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      // Using `Future.delayed` + a mounted check is enough: the
      // delays stay short (≤ 120 ms) and we only schedule one
      // timer per tile, so there is no measurable overhead.
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ListingsPaginationFooter extends StatelessWidget {
  const _ListingsPaginationFooter({required this.state, required this.onRetry});

  final ListingsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (state.status != ListingsStatus.paginationFailure) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                l10n.listingsLoadingMore,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.listingsLoadMoreFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}

class _FixedPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedPinnedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _FixedPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

Color _feedHeaderLayerColor(ThemeData theme) {
  final scheme = theme.colorScheme;
  return theme.brightness == Brightness.dark
      ? scheme.surfaceContainerLow
      : scheme.surfaceContainerLowest;
}

List<BoxShadow> _feedHeaderLayerShadow(ThemeData theme) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: scheme.shadow.withValues(alpha: isDark ? 0.28 : 0.05),
      blurRadius: 22,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
}

class _PinnedMasthead extends StatelessWidget {
  const _PinnedMasthead();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey<String>('listingsCatalogMasthead'),
      color: _feedHeaderLayerColor(Theme.of(context)),
      child: const ListingsCatalogHeader(),
    );
  }
}

class _ScrollAwayDiscoveryRails extends StatelessWidget {
  const _ScrollAwayDiscoveryRails({
    required this.onBrandSelected,
    required this.showBottomShadow,
  });

  final ValueChanged<String?> onBrandSelected;
  final bool showBottomShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _feedHeaderLayerColor(theme),
        boxShadow: showBottomShadow ? _feedHeaderLayerShadow(theme) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocSelector<ListingsBloc, ListingsState, String?>(
            selector: (state) => state.make,
            builder: (context, currentMake) {
              return KeyedSubtree(
                key: const ValueKey<String>('listingsHomeBrandRail'),
                child: ListingsBrandFilterRow(
                  currentMake: currentMake,
                  onBrandSelected: onBrandSelected,
                ),
              );
            },
          ),
          BlocBuilder<ListingsBloc, ListingsState>(
            buildWhen: (p, q) => p.bodyTypeFilter != q.bodyTypeFilter,
            builder: (context, listState) {
              final l10n = context.l10n;
              final chipId = listState.bodyTypeFilter == null
                  ? 'all'
                  : listState.bodyTypeFilter!.name;
              return KeyedSubtree(
                key: const ValueKey<String>('listingsHomeBodyRail'),
                child: CategoryChipsRow(
                  categories: feedHomeBodyChipDescriptors(l10n),
                  selectedId: chipId,
                  onSelected: (id) {
                    context.read<ListingsBloc>().add(
                      ListingsBodyTypeFilterChanged(
                        listingBodyTypeFromFeedChipId(id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _PinnedDiscoverySummary extends StatelessWidget {
  const _PinnedDiscoverySummary({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasActiveDiscoveryConstraints) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey<String>('listingsActiveDiscoverySummaryStrip'),
      decoration: BoxDecoration(
        color: _feedHeaderLayerColor(theme),
        boxShadow: _feedHeaderLayerShadow(theme),
      ),
      child: ListingsActiveDiscoverySummaryStrip(
        state: state,
        onFilterRemoved: (kind) {
          context.read<ListingsBloc>().add(
            ListingsDiscoveryFilterRemoved(kind),
          );
        },
      ),
    );
  }
}
