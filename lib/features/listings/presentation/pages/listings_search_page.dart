import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../bloc/listings_state.dart';
import '../cubit/browse_catalog_filter_alerts_cubit.dart';
import '../utils/listing_filter_apply_to_criteria.dart';
import '../widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import '../widgets/filters/catalog_browse_filter_alert_sheet_notice.dart';
import '../widgets/filters/catalog_filter_sheet_feedback.dart';
import '../widgets/filters/listings_filter_apply_result.dart';
import '../widgets/filters/listings_filter_form.dart';
import '../widgets/filters/listings_filter_host.dart';

/// Top-level Search tab: configure discovery criteria only.
///
/// Does not instantiate [ListingsBloc] or render a listings feed.
/// Apply navigates to Home with [ListingsFeedLaunch].
class ListingsSearchPage extends StatelessWidget {
  const ListingsSearchPage({super.key, this.initialCriteria});

  final ListingDiscoveryCriteria? initialCriteria;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
      value: sl<BrowseCatalogFilterAlertsCubit>(),
      child: _ListingsSearchView(initialCriteria: initialCriteria),
    );
  }
}

class _ListingsSearchView extends StatefulWidget {
  const _ListingsSearchView({this.initialCriteria});

  final ListingDiscoveryCriteria? initialCriteria;

  @override
  State<_ListingsSearchView> createState() => _ListingsSearchViewState();
}

class _ListingsSearchViewState extends State<_ListingsSearchView> {
  final GlobalKey<ListingsFilterFormState> _formKey =
      GlobalKey<ListingsFilterFormState>();
  ListingsFilterFormSeed? _seed;
  ListingsState _appliedState = const ListingsState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadSeed());
    });
  }

  Future<void> _loadSeed() async {
    if (!mounted) return;
    ListingDiscoveryCriteria? snapshot = widget.initialCriteria;
    snapshot ??= await sl<LastAppliedListingDiscoveryRepository>().load();
    if (!mounted) return;
    final state = snapshot == null
        ? const ListingsState()
        : listingsStateFromDiscoveryCriteria(snapshot);
    setState(() {
      _appliedState = state;
      _seed = ListingsFilterFormSeed.fromListingsState(state);
    });
  }

  void _goHomeWithoutApply() {
    context.go(AppRoutes.listings);
  }

  void _applyAndGoHome(ListingsFilterApplyResult result) {
    final criteria = listingDiscoveryCriteriaFromFilterApply(result);
    context.go(
      AppRoutes.listings,
      extra: ListingsFeedLaunch(snapshot: criteria),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seed = _seed;
    final scheme = Theme.of(context).colorScheme;
    return TopLevelScaffold(
      destination: TopLevelDestination.search,
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: seed == null
          ? const LoadingView()
          : Padding(
              padding: const EdgeInsets.only(
                bottom: kFloatingCapsuleNavClearance,
              ),
              child: _SearchFilterSurface(
                formKey: _formKey,
                seed: seed,
                appliedState: _appliedState,
                onDismiss: _goHomeWithoutApply,
                onApply: _applyAndGoHome,
              ),
            ),
    );
  }
}

class _SearchFilterSurface extends StatefulWidget {
  const _SearchFilterSurface({
    required this.formKey,
    required this.seed,
    required this.appliedState,
    required this.onDismiss,
    required this.onApply,
  });

  final GlobalKey<ListingsFilterFormState> formKey;
  final ListingsFilterFormSeed seed;
  final ListingsState appliedState;
  final VoidCallback onDismiss;
  final ValueChanged<ListingsFilterApplyResult> onApply;

  @override
  State<_SearchFilterSurface> createState() => _SearchFilterSurfaceState();
}

class _SearchFilterSurfaceState extends State<_SearchFilterSurface> {
  CatalogBellInlineNotice? _inlineNotice;
  CatalogFilterSheetFeedback? _sheetFeedback;

  void _clearNotices() {
    setState(() {
      _inlineNotice = null;
      _sheetFeedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListingsFilterHost(
      filterFormExternalKey: widget.formKey,
      seed: widget.seed,
      onDismiss: widget.onDismiss,
      onApply: widget.onApply,
      onBrowseDraftMutated: _clearNotices,
      onBrowseFeedReset: _clearNotices,
      browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
        sheetFormKey: widget.formKey,
        sheetContext: context,
        searchSnippet: () {
          return widget.formKey.currentState?.draftSeed.search?.trim() ?? '';
        },
        appliedState: widget.appliedState,
        onInlineNoticeRequested: (notice) =>
            setState(() => _inlineNotice = notice),
        onSheetFeedbackRequested: (feedback) =>
            setState(() => _sheetFeedback = feedback),
      ),
      browseHeaderNotice: _inlineNotice == null
          ? null
          : CatalogBrowseFilterAlertSheetNotice(notice: _inlineNotice!),
      browseSheetFeedbackOverlay: _sheetFeedback == null
          ? null
          : CatalogFilterSheetFeedbackOverlay(
              feedback: _sheetFeedback!,
              onDismissed: () => setState(() => _sheetFeedback = null),
            ),
    );
  }
}
