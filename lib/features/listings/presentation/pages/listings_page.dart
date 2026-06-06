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
import '../widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import '../widgets/filters/catalog_browse_filter_alert_sheet_notice.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../sellers/presentation/bloc/self_seller_visual_cubit.dart';
import '../widgets/category_chip.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_tile.dart';
import '../widgets/listings_active_discovery_summary_strip.dart';
import '../widgets/listings_brand_filter_row.dart';
import '../widgets/listings_catalog_header.dart';
import '../widgets/listings_feed_empty_state.dart';
import '../widgets/listings_search_filter_bar.dart';
import '../utils/feed_home_body_chips.dart';
import '../widgets/filters/listings_filter_apply_result.dart';
import '../widgets/filters/listings_filter_form.dart';
import '../widgets/filters/listings_filter_host.dart';
import '../../domain/browse_state_for_alert_criteria.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ListingsBloc>()),
        BlocProvider(create: (_) => sl<BrowseCatalogFilterAlertsCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, auth) {
          context.read<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth);
        },
        child: _ListingsDiscoveryBootstrap(
          feedLaunch: feedLaunch,
          child: _ListingsView(
            openFilterSheetOnEntry: feedLaunch?.openFilterSheetOnEntry ?? false,
          ),
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
    if (widget.feedLaunch != null) {
      bloc.add(ListingsHydratedFromDiscovery(widget.feedLaunch!.snapshot));
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
  const _ListingsView({this.openFilterSheetOnEntry = false});

  /// When `true`, the catalog filter sheet auto-opens after the first
  /// frame. Used by `/filter-alert` "Edit in catalog" so the management
  /// page sends the user straight into the filter UX where alerts are
  /// edited.
  final bool openFilterSheetOnEntry;

  @override
  State<_ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<_ListingsView> {
  final GlobalKey<ListingsFilterFormState> _catalogFilterSheetFormKey =
      GlobalKey<ListingsFilterFormState>();
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
      context.read<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth);
      if (widget.openFilterSheetOnEntry) {
        unawaited(_openFiltersSheet(context));
      }
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
        final browseAlerts = context.read<BrowseCatalogFilterAlertsCubit>();
        final h = MediaQuery.sizeOf(sheetContext).height;
        // Sheet-scoped inline notice (e.g. "Refine the filter to save
        // an alert"). Owned by the sheet builder so it lives and dies
        // with the modal — guaranteeing the message never reappears
        // on the listings page after the user closes the sheet, which
        // was the root-snackbar bleed bug we're fixing here.
        CatalogBellInlineNotice? inlineNotice;
        return BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
          value: browseAlerts,
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SizedBox(
                height: h,
                child: Builder(
                  builder: (sheetContext) {
                    String resolvedSearchSnippet() {
                      final typed = _searchCtrl.text.trim();
                      if (typed.isNotEmpty) return typed;
                      return bloc.state.search?.trim() ?? '';
                    }

                    // The "Show cars" CTA intentionally stays unaffected
                    // by `alerts.bellBusy`: the bell already disables
                    // itself while a save/clear is in flight, and tying
                    // the apply CTA to the same flag made the button
                    // briefly flash to its disabled style every time the
                    // user toggled the bell. Apply remains visually stable.
                    return ListingsFilterHost(
                      filterFormExternalKey: _catalogFilterSheetFormKey,
                      onBrowseDraftMutated: () => setSheetState(() {
                        // Any draft edit clears the "refine filter"
                        // notice — the user has acknowledged it and
                        // is iterating on the draft.
                        inlineNotice = null;
                      }),
                      browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
                        sheetFormKey: _catalogFilterSheetFormKey,
                        sheetContext: sheetContext,
                        searchSnippet: resolvedSearchSnippet,
                        // Canonical seed: the same catalog applied state
                        // that drove the main FAB indicator. Used by the
                        // bell as initial draft criteria so the bell and
                        // FAB never disagree on the first sheet frame.
                        appliedState: current,
                        onInlineNoticeRequested: (notice) =>
                            setSheetState(() => inlineNotice = notice),
                      ),
                      browseHeaderNotice: inlineNotice == null
                          ? null
                          : CatalogBrowseFilterAlertSheetNotice(
                              notice: inlineNotice!,
                            ),
                      // Bell visual + tooltip are the only saved-state
                      // surface in the catalog filter sheet now: a tech
                      // "push disabled" inline banner was removed because
                      // the saved/off colour + tap-to-remove tooltip carry
                      // the same information without product-unfriendly
                      // build-flag copy.
                      seed: ListingsFilterFormSeed.fromListingsState(current),
                      onDismiss: () => Navigator.of(sheetContext).pop(),
                      onApply: (r) => Navigator.of(sheetContext).pop(r),
                      onBrowseFeedReset: () {
                        _searchCtrl.clear();
                        bloc.add(const ListingsFiltersCleared());
                        setSheetState(() => inlineNotice = null);
                      },
                    );
                  },
                ),
              );
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
                      final l10n = context.l10n;
                      final msg = state.loadFailure != null
                          ? localizedUserFailureMessage(
                              l10n,
                              state.loadFailure!,
                              surface: LocalizedFailureSurface.listingsFeed,
                            )
                          : l10n.listingsLoadFailed;
                      return ErrorView(
                        message: msg,
                        onRetry: () => context.read<ListingsBloc>().add(
                          const ListingsRefreshed(),
                        ),
                      );
                    case ListingsStatus.success:
                    case ListingsStatus.loadingMore:
                    case ListingsStatus.paginationFailure:
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
                              return _ListingsPaginationFooter(
                                state: state,
                                onRetry: () => context.read<ListingsBloc>().add(
                                  const ListingsNextPageRequested(),
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

class _ListingsPaginationFooter extends StatelessWidget {
  const _ListingsPaginationFooter({required this.state, required this.onRetry});

  final ListingsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.status != ListingsStatus.paginationFailure) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
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
    final layerColor = isDark ? scheme.surfaceContainerLow : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layerColor,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListingsCatalogHeader(),
          // CARZON → search/filter: 4 (the wordmark already has 14
          // of bottom padding inside ListingsCatalogHeader, keep this tight
          // so the wordmark reads as "of the" controls, not adrift
          // from them).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child:
                BlocBuilder<
                  BrowseCatalogFilterAlertsCubit,
                  BrowseCatalogFilterAlertsState
                >(
                  builder: (context, _) {
                    return BlocBuilder<ListingsBloc, ListingsState>(
                      buildWhen: (prev, curr) {
                        final pActive =
                            listingsDiscoveryActiveFilterGroupCount(prev) > 0;
                        final qActive =
                            listingsDiscoveryActiveFilterGroupCount(curr) > 0;
                        final pCrit =
                            listingDiscoveryCriteriaFromBrowseStateForAlert(
                              prev,
                            );
                        final qCrit =
                            listingDiscoveryCriteriaFromBrowseStateForAlert(
                              curr,
                            );
                        return pActive != qActive || pCrit != qCrit;
                      },
                      builder: (context, state) {
                        final alertsCubit = context
                            .read<BrowseCatalogFilterAlertsCubit>();
                        final active =
                            listingsDiscoveryActiveFilterGroupCount(state) > 0;
                        final bellBadge = alertsCubit
                            .catalogBellBadgeVisibleForApplied(state);
                        final savedNoDeliveryBadge =
                            !bellBadge &&
                            alertsCubit
                                .catalogBellSavedWithoutDeliveryVisibleForApplied(
                                  state,
                                );
                        return ListingsSearchFilterBar(
                          searchCtrl: searchCtrl,
                          onOpenFilters: onOpenFilters,
                          onSearchSubmitted: (value) => context
                              .read<ListingsBloc>()
                              .add(ListingsSearchChanged(value)),
                          onClearSearch: () {
                            searchCtrl.clear();
                            context.read<ListingsBloc>().add(
                              const ListingsSearchChanged(null),
                            );
                          },
                          active: active,
                          bellBadge: bellBadge,
                          savedNoDeliveryBadge: savedNoDeliveryBadge,
                        );
                      },
                    );
                  },
                ),
          ),
          // search → brand row: 16
          const SizedBox(height: 16),
          BlocSelector<ListingsBloc, ListingsState, String?>(
            selector: (state) => state.make,
            builder: (context, currentMake) {
              return ListingsBrandFilterRow(
                currentMake: currentMake,
                onBrandSelected: onBrandSelected,
              );
            },
          ),
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
              return ListingsActiveDiscoverySummaryStrip(state: listState);
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
