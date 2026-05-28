import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/presentation/localized_user_failure_message.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../../../shared/ui/carzon_icons.dart';
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
import '../widgets/filters/catalog_filter_alert_ui_constants.dart';
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
    final fill = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final pillBorder = isDark
        ? scheme.outline.withValues(alpha: 0.32)
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
      color: scheme.shadow.withValues(alpha: isDark ? 0.22 : 0.025),
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
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.72 : 0.65,
                    ),
                  ),
                  prefixIcon: Icon(
                    CarzonIcons.search,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.78 : 0.7,
                    ),
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
                  final pCrit = listingDiscoveryCriteriaFromBrowseStateForAlert(
                    prev,
                  );
                  final qCrit = listingDiscoveryCriteriaFromBrowseStateForAlert(
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
                  // Mutually exclusive with [bellBadge]: active delivery
                  // wins. The helper itself guards `deliveryFullyEnabled`,
                  // so both flags cannot be true simultaneously.
                  final savedNoDeliveryBadge =
                      !bellBadge &&
                      alertsCubit
                          .catalogBellSavedWithoutDeliveryVisibleForApplied(
                            state,
                          );
                  final restingBg = isDark
                      ? scheme.surfaceContainerHigh
                      : Colors.white;
                  final bg = active
                      ? (isDark
                            ? AppTheme.selectedChipFill(scheme)
                            : Color.alphaBlend(
                                scheme.primary.withValues(alpha: 0.14),
                                restingBg,
                              ))
                      : restingBg;
                  final fg = active
                      ? (isDark
                            ? scheme.onSurface.withValues(alpha: 0.96)
                            : scheme.primary)
                      : AppTheme.chipForeground(scheme, selected: false);
                  final border = active
                      ? AppTheme.chipBorder(scheme, selected: true)
                      : pillBorder;
                  final badgeOutline = restingBg;
                  final semanticsLabel = bellBadge
                      ? '${l10n.listingsFiltersTooltip}. '
                            '${l10n.catalogBrowseFilterBellFilterChipSemantics}'
                      : savedNoDeliveryBadge
                      ? '${l10n.listingsFiltersTooltip}. '
                            '${l10n.catalogBrowseFilterBellSavedDeliveryUnavailableTooltip}'
                      : l10n.listingsFiltersTooltip;
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
                        side: BorderSide(
                          color: border,
                          width: active ? 1.25 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Tooltip(
                        message: l10n.listingsFiltersTooltip,
                        child: InkWell(
                          onTap: onOpenFilters,
                          child: Semantics(
                            button: true,
                            label: semanticsLabel,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Icon(CarzonIcons.filter, size: 20, color: fg),
                                // Two-corner badge system: filter-active
                                // marker top-right, alert-state marker
                                // bottom-right. Both are 16 dp circular
                                // badges with the same outline weight so
                                // they read as one polished component
                                // rather than two stuck-on stickers.
                                if (active)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: _FilterFabCornerBadge(
                                      background: scheme.primary,
                                      outline: badgeOutline,
                                      icon: Icons.check,
                                      iconColor: scheme.onPrimary,
                                      iconSize: 9,
                                    ),
                                  ),
                                if (bellBadge)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: _FilterFabCornerBadge(
                                      ornamentKey: CatalogFilterAlertAccent
                                          .discoveryFilterFABAlertBellKey,
                                      background:
                                          CatalogFilterAlertAccent.amber,
                                      outline: badgeOutline,
                                      icon: Icons.notifications,
                                      iconColor: scheme.onPrimary,
                                      iconSize: 9,
                                    ),
                                  )
                                else if (savedNoDeliveryBadge)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: _FilterFabCornerBadge(
                                      ornamentKey: CatalogFilterAlertAccent
                                          .discoveryFilterFABSavedNoDeliveryBellKey,
                                      background: Color.alphaBlend(
                                        CatalogFilterAlertAccent.amber
                                            .withValues(alpha: 0.22),
                                        restingBg,
                                      ),
                                      outline: CatalogFilterAlertAccent.amber
                                          .withValues(alpha: 0.55),
                                      icon: Icons.notifications,
                                      iconColor: CatalogFilterAlertAccent.amber,
                                      iconSize: 9,
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
/// Brands come from [kListingBrandFeedQuickFilterCatalog] (full catalog
/// except Other). Missing SVGs use a monogram fallback on Home only.
class _BrandFilterRow extends StatelessWidget {
  const _BrandFilterRow({required this.onBrandSelected});

  final ValueChanged<String?> onBrandSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: BlocSelector<ListingsBloc, ListingsState, String?>(
        selector: (state) => state.make,
        builder: (context, currentMake) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 24, 8),
            itemCount: kListingBrandFeedQuickFilterCatalog.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BrandTile.all(
                  selected: listingBrandFeedQuickFilterAllSelected(currentMake),
                  onTap: () => onBrandSelected(null),
                );
              }
              final brand = kListingBrandFeedQuickFilterCatalog[index - 1];
              return _BrandTile.brand(
                make: brand,
                selected: listingBrandFeedQuickFilterIsSelected(
                  currentMake,
                  brand,
                ),
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
///     resolver-provided SVG asset or a monogram when no SVG exists.
class _BrandTile extends StatelessWidget {
  const _BrandTile._({
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    required this.assetPath,
    required this.fallbackIcon,
    this.monogram,
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
    final resolvedPath = getBrandIconPath(make);
    final useMonogram = listingBrandFeedQuickFilterShouldUseMonogram(make);
    return _BrandTile._(
      selected: selected,
      onTap: onTap,
      semanticsLabel: make,
      assetPath: useMonogram ? null : resolvedPath,
      fallbackIcon: null,
      monogram: useMonogram ? listingBrandFeedQuickFilterMonogram(make) : null,
    );
  }

  final bool selected;
  final VoidCallback onTap;

  /// Raw brand string used for the semantics label. Null for the
  /// "All brands" tile — [Widget.build] pulls the localized string
  /// from the l10n bundle in that case.
  final String? semanticsLabel;

  /// SVG asset path for a concrete brand. Null for the "All" tile or
  /// monogram fallback brands.
  final String? assetPath;

  /// Icon used when [assetPath] is null (i.e. the "All brands" head
  /// tile).
  final IconData? fallbackIcon;

  /// Two-letter initials when no brand SVG is available on Home.
  final String? monogram;

  static const double _size = 48;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final bg = selected
        ? (isDark
              ? AppTheme.selectedChipFill(scheme)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.11),
                  Colors.white,
                ))
        : (isDark ? AppTheme.unselectedChipFill(scheme) : Colors.white);
    final borderColor = selected
        ? AppTheme.chipBorder(scheme, selected: true)
        : (isDark
              ? scheme.outline.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.42));
    final borderWidth = selected ? 2.0 : 1.0;
    final shadow = BoxShadow(
      color: selected
          ? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12)
          : scheme.shadow.withValues(alpha: isDark ? 0.16 : 0.025),
      blurRadius: selected ? 12 : 6,
      spreadRadius: selected ? 0.5 : 0,
      offset: Offset(0, selected ? 3 : 2),
    );

    final label = semanticsLabel != null
        ? l10n.brandFilterBrandSemantics(semanticsLabel!)
        : l10n.brandFilterAllSemantics;

    Widget glyph;
    if (assetPath != null) {
      glyph = BrandLogoGlyph(assetPath: assetPath!, size: 28);
    } else if (monogram != null) {
      glyph = _BrandMonogramMark(monogram: monogram!, selected: selected);
    } else {
      glyph = Icon(
        fallbackIcon,
        size: 20,
        color: selected
            ? scheme.primary
            : AppTheme.chipForeground(scheme, selected: false),
      );
    }

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
              side: BorderSide(color: borderColor, width: borderWidth),
            ),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      child: glyph,
                    ),
                    if (selected)
                      Positioned(
                        bottom: 5,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? scheme.surface : Colors.white,
                              width: 1,
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
      ),
    );
  }
}

/// Home-only initials mark for catalog brands without a dedicated SVG.
class _BrandMonogramMark extends StatelessWidget {
  const _BrandMonogramMark({required this.monogram, required this.selected});

  final String monogram;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final ring = scheme.outline.withValues(alpha: isDark ? 0.38 : 0.38);
    final fill = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.05),
      isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
    );
    final textColor = AppTheme.chipForeground(scheme, selected: selected);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring),
      ),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            monogram,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
              color: textColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified corner badge used by the catalog filter FAB ornaments.
///
/// Renders a small circular chip in the same dimensions for the two
/// corners of the filter button, so the filter-active marker and the
/// alert-state marker (active delivery or saved-without-delivery) read
/// as one polished status system rather than ad-hoc stickers.
class _FilterFabCornerBadge extends StatelessWidget {
  const _FilterFabCornerBadge({
    this.ornamentKey,
    required this.background,
    required this.outline,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  final Key? ornamentKey;
  final Color background;
  final Color outline;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 16,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: outline, width: 1.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              key: ornamentKey,
              size: iconSize,
              color: iconColor,
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
    final chips = listingsDiscoveryChips(state, l10n);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: l10n.filtersTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == chips.length - 1 ? 0 : 8,
                  ),
                  child: _ActiveDiscoveryChip(data: chips[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium compact pill rendering a single active discovery dimension.
///
/// Renders a soft surface gradient with a hairline outline and a thin
/// `label · value` typographic split (muted label, medium-weight value,
/// faded mid-dot separator). Falls back to a single value-only line
/// when the chip carries no [ListingsDiscoveryChip.label] (e.g.
/// "Sale", region marker). Designed to scale gracefully when many
/// chips are active without feeling like generic Material `Chip`s.
class _ActiveDiscoveryChip extends StatelessWidget {
  const _ActiveDiscoveryChip({required this.data});

  final ListingsDiscoveryChip data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fill = isDark
        ? scheme.surfaceContainerHigh
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.025),
            scheme.surface,
          );
    final stroke = scheme.outline.withValues(alpha: isDark ? 0.32 : 0.32);

    final valueStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.94 : 0.92),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05,
      height: 1.1,
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.82 : 0.52),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.08,
      height: 1.1,
    );
    final dotStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.55 : 0.32),
      fontWeight: FontWeight.w500,
      height: 1.1,
    );

    final hasLabel = data.label != null && data.label!.isNotEmpty;

    return Semantics(
      label: data.flat,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: stroke, width: 1),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLabel) ...[
                Text(data.label!, style: labelStyle, maxLines: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·', style: dotStyle),
                ),
              ],
              Flexible(
                child: Text(
                  data.value,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
