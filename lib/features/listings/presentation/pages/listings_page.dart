import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../bloc/listings_bloc.dart';
import '../bloc/listings_event.dart';
import '../bloc/listings_state.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_tile.dart';
import '../widgets/listings_feed_empty_state.dart';

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
  final _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final threshold = _scrollCtrl.position.maxScrollExtent - 200;
    if (_scrollCtrl.position.pixels >= threshold) {
      context.read<ListingsBloc>().add(const ListingsNextPageRequested());
    }
  }

  Future<void> _openFiltersSheet(BuildContext context) async {
    final bloc = context.read<ListingsBloc>();
    final current = bloc.state;
    final result = await showModalBottomSheet<_FiltersResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _FiltersBottomSheet(
        initialMake: current.make,
        initialMinYear: current.minYear,
        initialMaxYear: current.maxYear,
        initialType: current.typeFilter,
        initialRegion: current.regionFilter,
      ),
    );
    if (result == null) return;
    if (result.cleared) {
      _searchCtrl.clear();
      bloc.add(const ListingsFiltersCleared());
    } else {
      // Region is surfaced separately so the existing bloc contract
      // (ListingsFiltersApplied covers make/year/type only) stays
      // untouched. Dispatch only when the value actually changed to
      // avoid a redundant refetch.
      final region = result.region;
      if (region != null && region != current.regionFilter) {
        bloc.add(ListingsRegionFilterChanged(region));
      }
      bloc.add(ListingsFiltersApplied(
        make: result.make,
        minYear: result.minYear,
        maxYear: result.maxYear,
        typeFilter: result.typeFilter,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TopLevelScaffold(
      destination: TopLevelDestination.listings,
      // Deliberately invisible AppBar: no title, no elevation, no
      // tint — it only exists so Scaffold keeps the correct status-bar
      // inset. The editorial `_CatalogHeader` immediately below the
      // status bar carries the brand.
      appBar: AppBar(
        backgroundColor: scheme.surface,
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
        // Ambient backdrop behind the feed so the screen reads as a
        // lit editorial surface instead of a default Scaffold white.
        // The gradient is purely decorative (wrapped in an
        // IgnorePointer inside `_HomeBackdrop`) — it never intercepts
        // gestures from the cards above it.
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _HomeBackdrop(),
            Column(
              children: [
                const _CatalogHeader(),
                _DiscoveryHeader(
                  searchCtrl: _searchCtrl,
                  onOpenFilters: () => _openFiltersSheet(context),
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
                        message: state.errorMessage ??
                            context.l10n.listingsLoadFailed,
                        onRetry: () => context
                            .read<ListingsBloc>()
                            .add(const ListingsRefreshed()),
                      );
                    case ListingsStatus.success:
                    case ListingsStatus.loadingMore:
                      if (state.items.isEmpty) {
                        return ListingsFeedEmptyState(
                          hasFilters: state.hasActiveNonRegionFilters,
                          onResetFilters: () {
                            _searchCtrl.clear();
                            context
                                .read<ListingsBloc>()
                                .add(const ListingsFiltersCleared());
                          },
                          onRefresh: () async {
                            context
                                .read<ListingsBloc>()
                                .add(const ListingsRefreshed());
                          },
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<ListingsBloc>()
                              .add(const ListingsRefreshed());
                        },
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          // Shared 20 px gutter with the header + search
                          // row so header, search, and cards line up on
                          // one editorial column. Top `24` gives the
                          // feature card deliberate breathing room under
                          // the header; bottom `28` keeps the last card
                          // clear of the floating nav.
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                          itemCount: state.items.length +
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
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final item = state.items[index];
                            return ListingTile(
                              listing: item,
                              variant: index == 0
                                  ? ListingCardVariant.featured
                                  : ListingCardVariant.regular,
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
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ambient backdrop rendered behind the home feed.
///
/// A deliberately quiet top-to-bottom gradient: a low-alpha cool tint
/// at the top (pulled from the theme `primary` so it follows the
/// brand palette without looking like a paint job) fading into the
/// base `surface` over the first ~55% of the viewport. The remaining
/// space stays on the flat surface so cards sit on a neutral field.
///
/// The effect is meant to be *felt* — it gives the screen a sense of
/// lit depth instead of default Flutter white / grey — but it is
/// low-contrast on purpose and never demands attention.
///
/// Implementation notes:
///   * wrapped in [IgnorePointer] so the gradient never eats taps;
///   * uses a 3-stop gradient (`[top tint, surface, surface]`) rather
///     than a 2-stop so the bottom of the page is guaranteed to be
///     the flat surface color, even on very tall viewports.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Cool top tint. Dark mode lifts a touch harder (0.09) because the
    // surface is near-black and needs more signal to read; light mode
    // stays whisper-soft (0.035) so the header never looks colored.
    final topTint = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.09 : 0.035),
      scheme.surface,
    );
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topTint, scheme.surface, scheme.surface],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Editorial hero header at the top of the feed.
///
/// Carries the app's identity in place of an AppBar: a small
/// letter-spaced eyebrow ("CARZON") sits above a strong, editorial
/// catalog title. This mirrors how an automotive magazine opens a
/// section — quiet brand, confident title — and lets the AppBar stay
/// invisible.
class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // Header uses the same 20 px gutter as the search row and the
    // card list below, so the eyebrow, title, search, and cards line
    // up on a single editorial column instead of feeling randomly
    // inset like form controls.
    return Padding(
      // Bottom padding is 6 (not 0) so the editorial title has a
      // small air below it; combined with the 22 px top padding on
      // _DiscoveryHeader this gives a 28 px "title → search" gap,
      // which is what makes the header feel like two distinct
      // blocks (identity + controls) rather than one glued strip.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CARZON',
            textAlign: TextAlign.start,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              height: 1.0,
            ),
          ),
          // 12 (not 8) lets the eyebrow breathe away from the
          // title — the eyebrow is a brand signature, not a label.
          const SizedBox(height: 12),
          Text(
            l10n.catalogTitle,
            textAlign: TextAlign.start,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-of-feed discovery surface: pill search + filter icon on the
/// first row, horizontal region chips on the second. Rendered on the
/// scaffold background without a hard divider so the catalog header,
/// discovery controls, and cards read as a single editorial stack.
///
/// The chips row is intentionally structured so future active-filter
/// chips (e.g. applied make/year) can be appended inline without any
/// layout rewrite.
class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.searchCtrl,
    required this.onOpenFilters,
  });

  final TextEditingController searchCtrl;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    // Shares the 20 px gutter with the header and the list below so
    // the whole page reads as one editorial column. The extra top /
    // bottom breathing room (vs. Pass 2) lets the search + filter
    // row read as its own "control group" surface instead of a strip
    // glued to the editorial title.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: _SearchAndFilterBar(
        searchCtrl: searchCtrl,
        onOpenFilters: onOpenFilters,
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
    // With the ambient backdrop now tinting the top of the page,
    // controls need a touch more surface contrast so they read as
    // elevated pills rather than "white holes". One step up on each
    // tone (Highest / Low) gives a subtle lift without pushing the
    // pill into loud-grey territory.
    final fill = isDark
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLow;
    // Slightly shorter, squarer controls than Pass 1.5 so the search
    // row reads as a compact utility bar (not a fluffy pill that
    // competes with the editorial headline above it).
    const barHeight = 50.0;
    const searchRadius = 20.0;
    // 16 — locks the filter button onto the app-wide "buttons = 16"
    // radius token; slightly tighter than the search pill so the two
    // shapes layer visibly without looking identical.
    const filterRadius = 16.0;
    // Matches the filter button's shadow family (same direction,
    // slightly softer) so the two controls read as a single elevated
    // pair above the page surface.
    final searchShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
      blurRadius: 10,
      offset: const Offset(0, 3),
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
                  Icons.search_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 44, minHeight: 44),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchCtrl,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: l10n.listingsSearchClearTooltip,
                      onPressed: () {
                        searchCtrl.clear();
                        context
                            .read<ListingsBloc>()
                            .add(const ListingsSearchChanged(null));
                      },
                    );
                  },
                ),
                filled: true,
                fillColor: fill,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(searchRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(searchRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(searchRadius),
                  borderSide:
                      BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                ),
              ),
              onSubmitted: (value) => context
                  .read<ListingsBloc>()
                  .add(ListingsSearchChanged(value)),
            ),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<ListingsBloc, ListingsState>(
            buildWhen: (prev, curr) =>
                prev.hasActiveNonRegionFilters !=
                curr.hasActiveNonRegionFilters,
            builder: (context, state) {
              final active = state.hasActiveNonRegionFilters;
              // Icon-only utility control: same height as the search
              // pill, soft rounded square so it does not compete with
              // the headline. The base tone is one step *above* the
              // search fill (surfaceContainerHigh in light, Highest in
              // dark) so the two controls read as a related pair with
              // the filter clearly on top. Active state earns a
              // low-alpha primary tint and a tiny accent dot — no
              // loud fill, no label.
              final restingBg = isDark
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerHigh;
              final bg = active
                  ? scheme.primary.withValues(alpha: isDark ? 0.14 : 0.09)
                  : restingBg;
              final fg = active
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.85);
              return Container(
                height: barHeight,
                width: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(filterRadius),
                  // Whisper-level shadow — just enough to tell the
                  // button apart from the search pill without making
                  // the header look "overdressed".
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.22 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(filterRadius),
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
                          children: [
                            // Active state is already communicated by
                            // the tint + dot below; use a single icon
                            // variant so the silhouette stays stable
                            // across toggles.
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: fg,
                            ),
                            if (active)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
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

/// Result tuple returned by [_FiltersBottomSheet]. Either a set of
/// applied values, or a "clear all" signal.
///
/// Region was promoted into the sheet in Pass 1.3 (the home no longer
/// shows region chips), so callers dispatch a region change when the
/// returned [region] differs from the current bloc state.
class _FiltersResult {
  const _FiltersResult.apply({
    required this.make,
    required this.minYear,
    required this.maxYear,
    required this.typeFilter,
    required this.region,
  }) : cleared = false;

  const _FiltersResult.clear()
      : cleared = true,
        make = null,
        minYear = null,
        maxYear = null,
        typeFilter = ListingTypeFilter.any,
        region = null;

  final bool cleared;
  final String? make;
  final int? minYear;
  final int? maxYear;
  final ListingTypeFilter typeFilter;
  // Null when [cleared] is true — the bloc preserves the current
  // region on "clear filters" (see [ListingsFiltersCleared] contract).
  final MarketRegionFilter? region;
}

class _FiltersBottomSheet extends StatefulWidget {
  const _FiltersBottomSheet({
    required this.initialMake,
    required this.initialMinYear,
    required this.initialMaxYear,
    required this.initialType,
    required this.initialRegion,
  });

  final String? initialMake;
  final int? initialMinYear;
  final int? initialMaxYear;
  final ListingTypeFilter initialType;
  final MarketRegionFilter initialRegion;

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late final TextEditingController _make;
  late final TextEditingController _minYear;
  late final TextEditingController _maxYear;
  late ListingTypeFilter _type;
  late MarketRegionFilter _region;
  // Per-field error strings. Attached to the relevant `TextField` via
  // `InputDecoration.errorText` so the user can see which value is wrong
  // without scanning a generic message elsewhere in the sheet.
  String? _minYearError;
  String? _maxYearError;

  @override
  void initState() {
    super.initState();
    _make = TextEditingController(text: widget.initialMake ?? '');
    _minYear =
        TextEditingController(text: widget.initialMinYear?.toString() ?? '');
    _maxYear =
        TextEditingController(text: widget.initialMaxYear?.toString() ?? '');
    _type = widget.initialType;
    _region = widget.initialRegion;
  }

  @override
  void dispose() {
    _make.dispose();
    _minYear.dispose();
    _maxYear.dispose();
    super.dispose();
  }

  int? _parseYear(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void _apply() {
    final l10n = context.l10n;
    final make = _make.text.trim();
    final minYear = _parseYear(_minYear.text);
    final maxYear = _parseYear(_maxYear.text);

    String? minErr;
    String? maxErr;
    // Numeric errors are defensive — `FilteringTextInputFormatter.digitsOnly`
    // already blocks non-digits, but a paste or programmatic change could
    // still slip through.
    if (_minYear.text.trim().isNotEmpty && minYear == null) {
      minErr = l10n.filterMustBeNumber;
    }
    if (_maxYear.text.trim().isNotEmpty && maxYear == null) {
      maxErr = l10n.filterMustBeNumber;
    }
    if (minErr == null &&
        maxErr == null &&
        minYear != null &&
        maxYear != null &&
        minYear > maxYear) {
      // Show the range error on both fields so the user understands the
      // constraint affects the pair, not a single value.
      minErr = l10n.filterMustBeMaxYear;
      maxErr = l10n.filterMustBeMinYear;
    }

    if (minErr != null || maxErr != null) {
      setState(() {
        _minYearError = minErr;
        _maxYearError = maxErr;
      });
      return;
    }

    Navigator.of(context).pop(_FiltersResult.apply(
      make: make.isEmpty ? null : make,
      minYear: minYear,
      maxYear: maxYear,
      typeFilter: _type,
      region: _region,
    ));
  }

  void _clear() {
    Navigator.of(context).pop(const _FiltersResult.clear());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.filtersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _make,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.filterMake,
                hintText: l10n.filterMakeHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minYear,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      if (_minYearError != null || _maxYearError != null) {
                        setState(() {
                          _minYearError = null;
                          _maxYearError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l10n.filterMinYear,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _minYearError,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxYear,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      if (_minYearError != null || _maxYearError != null) {
                        setState(() {
                          _minYearError = null;
                          _maxYearError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l10n.filterMaxYear,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _maxYearError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.regionFilterLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<MarketRegionFilter>(
              segments: [
                ButtonSegment(
                  value: MarketRegionFilter.transnistria,
                  label: Text(l10n.regionTransnistria),
                ),
                ButtonSegment(
                  value: MarketRegionFilter.moldova,
                  label: Text(l10n.regionMoldova),
                ),
                ButtonSegment(
                  value: MarketRegionFilter.both,
                  label: Text(l10n.regionBoth),
                ),
              ],
              selected: {_region},
              onSelectionChanged: (selected) {
                if (selected.isEmpty) return;
                setState(() => _region = selected.first);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.filterType,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<ListingTypeFilter>(
              segments: [
                ButtonSegment(
                  value: ListingTypeFilter.any,
                  label: Text(l10n.typeAny),
                ),
                ButtonSegment(
                  value: ListingTypeFilter.sale,
                  label: Text(l10n.typeSale),
                ),
                ButtonSegment(
                  value: ListingTypeFilter.exchange,
                  label: Text(l10n.typeExchange),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selected) {
                if (selected.isEmpty) return;
                setState(() => _type = selected.first);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: Text(l10n.filterClear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.filterApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
