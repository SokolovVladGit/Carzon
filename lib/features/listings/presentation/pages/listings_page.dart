import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../bloc/listings_bloc.dart';
import '../bloc/listings_event.dart';
import '../bloc/listings_state.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../sellers/presentation/bloc/self_seller_visual_cubit.dart';
import '../widgets/category_chip.dart';
import '../widgets/feed_home_account_avatar_button.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_tile.dart';
import '../widgets/listings_feed_empty_state.dart';
import '../utils/feed_home_body_chips.dart';
import '../widgets/filters/listings_filter_apply_result.dart';
import '../widgets/filters/listings_filter_form.dart';
import '../widgets/filters/listings_filter_host.dart';
import '../utils/discovery_feed_chip_labels.dart';

bool _listingsFilterChromeChanged(ListingsState p, ListingsState q) {
  return p.search != q.search ||
      p.make != q.make ||
      p.model != q.model ||
      p.minYear != q.minYear ||
      p.maxYear != q.maxYear ||
      p.minPrice != q.minPrice ||
      p.maxPrice != q.maxPrice ||
      p.maxMileage != q.maxMileage ||
      p.city != q.city ||
      p.typeFilter != q.typeFilter ||
      p.regionFilter != q.regionFilter ||
      p.bodyTypeFilter != q.bodyTypeFilter ||
      p.sortOption != q.sortOption ||
      p.priceCurrencyFilter != q.priceCurrencyFilter ||
      p.hasActiveDiscoveryConstraints != q.hasActiveDiscoveryConstraints;
}

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key, this.feedLaunch});

  final ListingsFeedLaunch? feedLaunch;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ListingsBloc>(),
      child: _ListingsDiscoveryBootstrap(
        feedLaunch: feedLaunch,
        child: const _ListingsView(),
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

class _ListingsDiscoveryBootstrapState extends State<_ListingsDiscoveryBootstrap> {
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
    if (widget.feedLaunch != null) {
      bloc.add(
        ListingsHydratedFromDiscovery(widget.feedLaunch!.snapshot),
      );
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
  final _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
    _feedScrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    _feedScrollOffset.value = _scrollCtrl.position.pixels;
    final threshold = _scrollCtrl.position.maxScrollExtent - 200;
    if (_scrollCtrl.position.pixels >= threshold) {
      context.read<ListingsBloc>().add(const ListingsNextPageRequested());
    }
  }

  Future<void> _openFiltersSheet(BuildContext context) async {
    final bloc = context.read<ListingsBloc>();
    final current = bloc.state;
    final result = await showModalBottomSheet<ListingsFilterApplyResult?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final h = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: h,
          child: ListingsFilterHost(
            seed: ListingsFilterFormSeed.fromListingsState(current),
            onDismiss: () => Navigator.of(sheetContext).pop(),
            onApply: (r) => Navigator.of(sheetContext).pop(r),
            onBrowseFeedReset: () {
              _searchCtrl.clear();
              bloc.add(const ListingsFiltersCleared());
            },
          ),
        );
      },
    );
    if (result == null) return;
    if (result.cleared) {
      _searchCtrl.clear();
      bloc.add(const ListingsFiltersCleared());
    } else {
      bloc.add(
        ListingsFiltersApplied(
          make: result.make,
          model: result.model,
          minYear: result.minYear,
          maxYear: result.maxYear,
          minPrice: result.minPrice,
          maxPrice: result.maxPrice,
          maxMileage: result.maxMileage,
          city: result.city,
          typeFilter: result.typeFilter,
          sort: result.sort,
          regionFilter: result.region ?? MarketRegionFilter.transnistria,
          bodyType: result.bodyType,
          priceCurrencyFilter: result.priceCurrencyFilter,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Pass 1.7 flattens the feed background: pure white in light
    // mode (the brief's "clean editorial canvas"), theme surface in
    // dark. The old `_HomeBackdrop` gradient was removed because it
    // pulled a primary tint over the top of the screen that made
    // controls feel washed and "generic Flutter".
    final feedBackground = isDark ? scheme.surface : Colors.white;
    return TopLevelScaffold(
      destination: TopLevelDestination.listings,
      backgroundColor: feedBackground,
      // Deliberately invisible AppBar: no title, no elevation, no
      // tint — it only exists so Scaffold keeps the correct status-bar
      // inset. The editorial `_CatalogHeader` immediately below the
      // status bar carries the brand. Its background tracks the
      // scaffold's so the header and feed read as one canvas.
      appBar: AppBar(
        backgroundColor: feedBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: BlocListener<ListingsBloc, ListingsState>(
        listenWhen: (prev, curr) => prev.search != curr.search,
        listener: (context, state) {
          final next = state.search ?? '';
          if (_searchCtrl.text != next) _searchCtrl.text = next;
        },
        child: Column(
          children: [
            _FeedHeaderLayer(
              searchCtrl: _searchCtrl,
              onOpenFilters: () => _openFiltersSheet(context),
              onBrandSelected: _onBrandSelected,
            ),
            Expanded(
              child: BlocBuilder<ListingsBloc, ListingsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ListingsStatus.initial:
                    case ListingsStatus.loading:
                      return const LoadingView();
                    case ListingsStatus.failure:
                      return ErrorView(
                        message:
                            state.errorMessage ??
                            context.l10n.listingsLoadFailed,
                        onRetry: () => context.read<ListingsBloc>().add(
                          const ListingsRefreshed(),
                        ),
                      );
                    case ListingsStatus.success:
                    case ListingsStatus.loadingMore:
                      if (state.items.isEmpty) {
                        return ListingsFeedEmptyState(
                          hasFilters: state.hasActiveDiscoveryConstraints,
                          includeBodyFilterEmptyHint:
                              state.bodyTypeFilter != null,
                          onResetFilters: () {
                            _searchCtrl.clear();
                            context.read<ListingsBloc>().add(
                              const ListingsFiltersCleared(),
                            );
                          },
                          onRefresh: () async {
                            context.read<ListingsBloc>().add(
                              const ListingsRefreshed(),
                            );
                          },
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ListingsBloc>().add(
                            const ListingsRefreshed(),
                          );
                        },
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          // iOS-style bounce on both platforms so the
                          // feed reads as one cohesive, buttery scroll
                          // surface — overscroll at the top also plays
                          // well with the RefreshIndicator above.
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          // Shared 20 px gutter with the header + search
                          // row so header, search, and cards line up on
                          // one editorial column. Top `10` lands
                          // directly under the header layer's chip row
                          // (which already carries 8 px bottom air),
                          // yielding an ~18 px visual gap from chip
                          // bottom → first card — squarely in the
                          // 16–20 target. The bottom clearance is
                          // driven by `kFloatingCapsuleNavClearance`
                          // so the last card lands above the floating
                          // pill (the scaffold uses `extendBody: true`,
                          // so content renders behind the pill).
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            kFloatingCapsuleNavClearance,
                          ),
                          itemCount:
                              state.items.length +
                              (state.hasReachedEnd ? 0 : 1),
                          // Larger gap after the feature card (30) so the
                          // first/second cards read as two beats rather
                          // than a tight stack; regular rhythm (24)
                          // everywhere else. Both values are sized so the
                          // overlapping info panel of card N never feels
                          // glued to the image of card N+1.
                          separatorBuilder: (_, index) => SizedBox(
                            // Larger gaps than Pass 2 because the
                            // panel's shadow (blur 20 / offset y 8)
                            // now bleeds ~12 px below the panel rect;
                            // 34 after featured / 28 between regulars
                            // preserves the 22–28 px visual air target.
                            height: index == 0 ? 34 : 28,
                          ),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = state.items[index];
                            final isFeatured = index == 0;
                            return _AppearAnimation(
                              // Keyed by listing id so scroll-recycling
                              // in the `ListView` does NOT re-trigger
                              // the entrance animation for the same
                              // listing; each card animates in once
                              // per logical identity.
                              key: ValueKey<String>('appear-${item.id}'),
                              // Subtle staggered cascade: 0/30/60/90/120
                              // ms based on feed index, capped at 120
                              // so the 6th+ cards don't feel laggy.
                              // Using `index * 30` keeps the stagger
                              // invisible under casual scroll while
                              // reading as deliberate on first paint.
                              delay: Duration(
                                milliseconds: (index * 30).clamp(0, 120),
                              ),
                              child: ListingTile(
                                listing: item,
                                variant: isFeatured
                                    ? ListingCardVariant.featured
                                    : ListingCardVariant.regular,
                                // Only the featured hero wires the
                                // scroll-offset listenable → parallax
                                // cover. Regulars stay inert to keep
                                // the scroll-tick rebuild surface tiny.
                                coverParallax: isFeatured
                                    ? _feedScrollOffset
                                    : null,
                                onTap: () => context.push(
                                  AppRoutes.listingDetailsPath(item.id),
                                  extra: ListingDetailsExtra(
                                    coverImageUrl: item.coverImageUrl,
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
            ),
          ],
        ),
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
    // Short-circuit redundant taps: selecting the already-selected
    // chip (or tapping "All" when no make filter is active) must
    // not trigger a loading state / refetch.
    if ((current ?? '') == (brand ?? '')) return;
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
        priceCurrencyFilter: s.priceCurrencyFilter,
      ),
    );
  }
}

/// Premium white surface layer that hosts every control at the top
/// of the feed: the CARZON wordmark, the search+filter row, the
/// horizontal brand-logo row, and the body-type chips.
///
/// The goal (Pass 1.9) is to give the top of the feed a single
/// intentional "layer" that sits above the list, so the eye reads
/// "header surface → list" instead of "stack of independent rows".
/// The layer is NOT a card — it is edge-to-edge and sits flush with
/// the page surface — but it earns a soft bottom shadow so it lifts
/// off the list below.
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

class _FeedHeaderLayer extends StatelessWidget {
  const _FeedHeaderLayer({
    required this.searchCtrl,
    required this.onOpenFilters,
    required this.onBrandSelected,
  });

  final TextEditingController searchCtrl;
  final VoidCallback onOpenFilters;
  final ValueChanged<String?> onBrandSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Light mode: the layer is pure white on a pure-white page —
    // the only thing separating the two is the soft bottom shadow.
    // Dark mode: a one-step-lifted surface so the shadow has
    // something to read against.
    final layerColor = isDark ? scheme.surfaceContainer : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CatalogHeader(),
          // CARZON → search/filter: 4 (the wordmark already has 14
          // of bottom padding inside _CatalogHeader, keep this tight
          // so the wordmark reads as "of the" controls, not adrift
          // from them).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _SearchAndFilterBar(
              searchCtrl: searchCtrl,
              onOpenFilters: onOpenFilters,
            ),
          ),
          // search → brand row: 16
          const SizedBox(height: 16),
          _BrandFilterRow(onBrandSelected: onBrandSelected),
          // brand row → body chips: 4 (brand row already carries
          // its own 8 px vertical padding from the ListView).
          const SizedBox(height: 4),
          BlocBuilder<ListingsBloc, ListingsState>(
            buildWhen: (p, q) => p.bodyTypeFilter != q.bodyTypeFilter,
            builder: (context, listState) {
              final l10n = context.l10n;
              final chipId = listState.bodyTypeFilter == null
                  ? 'all'
                  : listState.bodyTypeFilter!.name;
              return CategoryChipsRow(
                categories: feedHomeBodyChipDescriptors(l10n),
                selectedId: chipId,
                onSelected: (id) {
                  context.read<ListingsBloc>().add(
                    ListingsBodyTypeFilterChanged(
                      listingBodyTypeFromFeedChipId(id),
                    ),
                  );
                },
              );
            },
          ),
          BlocBuilder<ListingsBloc, ListingsState>(
            buildWhen: _listingsFilterChromeChanged,
            builder: (context, listState) {
              if (!listState.hasActiveDiscoveryConstraints) {
                return const SizedBox.shrink();
              }
              return _ActiveDiscoverySummaryStrip(state: listState);
            },
          ),
          // Tight bottom air inside the layer — the chip row's
          // own 8 px vertical padding is the real bottom gap; the
          // 2 px here just lifts the shadow edge clear of the
          // chip silhouette.
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// Editorial wordmark header at the top of the feed.
///
/// Pass 1.8 simplifies the header to a single centered "CARZON"
/// wordmark. The earlier large catalog title was pulling the page
/// into "generic app" territory; the magazine masthead treatment
/// lets the brand sit alone at the top and hands visual authority
/// to the discovery controls and brand-logo row below.
///
/// The wordmark is deliberately compact (label-size, heavily
/// letter-spaced, onSurface with moderate opacity) so it reads as
/// identity, not as a loud title. It carries no tagline, no large
/// heading, and no trailing controls.
/// The wordmark stays centered; mirrored leading width keeps the masthead
/// balanced with the trailing account control.
class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader();

  static const double _mastheadSideSlot =
      FeedHomeAccountAvatarButton.avatarDiameter + 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wordmark = Text(
      'CARZON',
      textAlign: TextAlign.center,
      style: theme.textTheme.titleSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.82),
        fontWeight: FontWeight.w700,
        letterSpacing: 4.0,
        height: 1.0,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 10),
      child: Row(
        children: [
          const SizedBox(width: _mastheadSideSlot),
          Expanded(child: Center(child: wordmark)),
          const SizedBox(
            width: _mastheadSideSlot,
            child: Align(
              alignment: Alignment.centerRight,
              child: FeedHomeAccountAvatarButton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped search field next to a rounded filter button. Overrides
/// the global `InputDecorationTheme` outlines so the search stays
/// borderless and "settled" inside the feed surface, without changing
/// how the filters sheet renders its own text fields.
class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.searchCtrl,
    required this.onOpenFilters,
  });

  final TextEditingController searchCtrl;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    // Feed background is now pure white in light mode. Controls sit
    // almost flush on the canvas — a close-to-white fill with a
    // hairline border + whisper shadow reads as a premium elevated
    // pill, not a grey utility bar.
    final fill = isDark ? scheme.surfaceContainerHighest : Colors.white;
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : scheme.outlineVariant.withValues(alpha: 0.45);
    // Slightly shorter, squarer controls than Pass 1.5 so the search
    // row reads as a compact utility bar (not a fluffy pill that
    // competes with the editorial headline above it).
    const barHeight = 50.0;
    const searchRadius = 16.0;
    // Locked to the brand-tile radius (14) so the filter button
    // reads as part of the same control family as the brand row
    // directly below it, rather than a separate form element.
    const filterRadius = 14.0;
    // Whisper shadow only — the header layer itself carries the
    // main drop shadow now, so the individual controls need just a
    // hairline lift to read as distinct surfaces without stacking
    // visual noise.
    final searchShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.025),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
    return SizedBox(
      height: barHeight,
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(searchRadius),
                boxShadow: [searchShadow],
              ),
              child: TextField(
                controller: searchCtrl,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.listingsSearchHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                  prefixIcon: Icon(
                    CarzonIcons.search,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchCtrl,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(CarzonIcons.close, size: 18),
                        tooltip: l10n.listingsSearchClearTooltip,
                        onPressed: () {
                          searchCtrl.clear();
                          context.read<ListingsBloc>().add(
                            const ListingsSearchChanged(null),
                          );
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor: fill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide(color: pillBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onSubmitted: (value) => context.read<ListingsBloc>().add(
                  ListingsSearchChanged(value),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<ListingsBloc, ListingsState>(
            buildWhen: (prev, curr) {
              final pa = listingsDiscoveryActiveFilterGroupCount(prev) > 0;
              final qa = listingsDiscoveryActiveFilterGroupCount(curr) > 0;
              return pa != qa;
            },
            builder: (context, state) {
              final active = listingsDiscoveryActiveFilterGroupCount(state) > 0;
              // Align with search pill: inactive reads as crisp white/light;
              // active uses clearer primary tint + icon + small check badge.
              final restingBg = isDark
                  ? scheme.surfaceContainerHighest
                  : Colors.white;
              final bg = active
                  ? Color.alphaBlend(
                      scheme.primary.withValues(
                        alpha: isDark ? 0.26 : 0.14,
                      ),
                      restingBg,
                    )
                  : restingBg;
              final fg = active
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.88);
              final border = active
                  ? scheme.primary.withValues(alpha: isDark ? 0.52 : 0.40)
                  : pillBorder;
              final badgeOutline = restingBg;
              return Container(
                height: barHeight,
                width: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(filterRadius),
                  boxShadow: [searchShadow],
                ),
                child: Material(
                  color: bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(filterRadius),
                    side: BorderSide(color: border, width: active ? 1.25 : 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    message: l10n.listingsFiltersTooltip,
                    child: InkWell(
                      onTap: onOpenFilters,
                      child: Semantics(
                        button: true,
                        label: l10n.listingsFiltersTooltip,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Icon(CarzonIcons.filter, size: 20, color: fg),
                            if (active)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: badgeOutline,
                                        width: 1.25,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.shadow.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.check,
                                        size: 10,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Horizontal brand-logo quick filter rendered directly under the
/// search/filter row on the feed.
///
/// Each brand is presented as an icon-only rounded tile. Tapping a
/// tile drives the `make` filter through the existing
/// [ListingsFiltersApplied] event (see [_ListingsViewState._onBrandSelected]);
/// it never introduces a new bloc event or query parameter. The
/// "All brands" tile at the front of the list is the unset state
/// (dispatches a `null` make).
///
/// The brand list is curated from brands whose SVG assets are known
/// to resolve via [getBrandIconPath] (no default fallback); order
/// favors brands common in the target market. No brand names are
/// rendered under the icons — semantics labels handle accessibility
/// and long-press tooltips.
class _BrandFilterRow extends StatelessWidget {
  const _BrandFilterRow({required this.onBrandSelected});

  final ValueChanged<String?> onBrandSelected;

  /// Curated brand ordering. Each string is the canonical make value
  /// passed to [getBrandIconPath] and dispatched as the make filter.
  /// Values match the seller-facing spelling in [brand_icon_resolver]
  /// aliases so the repository's case-insensitive `ilike` query
  /// reliably matches listings of that brand.
  static const List<String> _brands = [
    'Toyota',
    'Volkswagen',
    'Skoda',
    'Opel',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Tesla',
    'Renault',
    'Ford',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: BlocSelector<ListingsBloc, ListingsState, String?>(
        selector: (state) => state.make,
        builder: (context, currentMake) {
          final normalized = currentMake?.trim().toLowerCase();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            // Same 20 px gutter as the editorial column, with a bit
            // of trailing air so the last tile never clips the edge
            // of the viewport when fully scrolled.
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            itemCount: _brands.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BrandTile.all(
                  selected: normalized == null || normalized.isEmpty,
                  onTap: () => onBrandSelected(null),
                );
              }
              final brand = _brands[index - 1];
              final isSelected = normalized == brand.toLowerCase();
              return _BrandTile.brand(
                make: brand,
                selected: isSelected,
                onTap: () => onBrandSelected(brand),
              );
            },
          );
        },
      ),
    );
  }
}

/// Single rounded-square tile in the brand filter row. Two flavors:
///   * [_BrandTile.all] — the "All brands" entry at the head of the
///     row, rendered as a neutral search icon;
///   * [_BrandTile.brand] — a concrete brand, rendered from the
///     resolver-provided SVG asset.
class _BrandTile extends StatelessWidget {
  const _BrandTile._({
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    required this.assetPath,
    required this.fallbackIcon,
  });

  factory _BrandTile.all({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _BrandTile._(
      selected: selected,
      onTap: onTap,
      semanticsLabel: null,
      assetPath: null,
      fallbackIcon: CarzonIcons.allBrands,
    );
  }

  factory _BrandTile.brand({
    required String make,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _BrandTile._(
      selected: selected,
      onTap: onTap,
      semanticsLabel: make,
      assetPath: getBrandIconPath(make),
      fallbackIcon: null,
    );
  }

  final bool selected;
  final VoidCallback onTap;

  /// Raw brand string used for the semantics label. Null for the
  /// "All brands" tile — [Widget.build] pulls the localized string
  /// from the l10n bundle in that case.
  final String? semanticsLabel;

  /// SVG asset path for a concrete brand. Null for the "All" tile.
  final String? assetPath;

  /// Icon used when [assetPath] is null (i.e. the "All brands" head
  /// tile).
  final IconData? fallbackIcon;

  static const double _size = 48;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    // Close-to-white resting background so the tile reads as a
    // lifted chip on the pure-white feed surface, not a grey block.
    // Selection is expressed via a whisper primary tint + a tinted
    // hairline border rather than a strong fill, keeping the row
    // quiet while still clearly indicating which brand is active.
    final bg = selected
        ? (isDark
              ? scheme.primary.withValues(alpha: 0.14)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.04),
                  Colors.white,
                ))
        : (isDark ? scheme.surfaceContainerHighest : Colors.white);
    final borderColor = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.5 : 0.32)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : scheme.outlineVariant.withValues(alpha: 0.45));
    final shadow = BoxShadow(
      color: selected
          ? scheme.primary.withValues(alpha: isDark ? 0.16 : 0.07)
          : Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
      blurRadius: selected ? 10 : 6,
      offset: const Offset(0, 2),
    );

    final label = semanticsLabel != null
        ? l10n.brandFilterBrandSemantics(semanticsLabel!)
        : l10n.brandFilterAllSemantics;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      container: true,
      child: Tooltip(
        message: semanticsLabel ?? l10n.brandFilterAllSemantics,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [shadow],
          ),
          child: Material(
            color: bg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
              side: BorderSide(color: borderColor),
            ),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: assetPath != null
                      ? SvgPicture.asset(
                          assetPath!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          fallbackIcon,
                          size: 20,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ActiveDiscoverySummaryStrip extends StatelessWidget {
  const _ActiveDiscoverySummaryStrip({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chips = listingsDiscoveryChipLabels(state, l10n);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: l10n.filtersTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final label in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.88),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
