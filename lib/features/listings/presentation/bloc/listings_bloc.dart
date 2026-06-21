import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../recent_searches/domain/usecases/record_recent_search.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../../domain/browse_state_for_alert_criteria.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../../domain/usecases/get_listings.dart';
import '../utils/discovery_feed_chip_labels.dart';
import 'listings_event.dart';
import 'listings_state.dart';

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({
    required GetListings getListings,
    required LastAppliedListingDiscoveryRepository lastAppliedDiscovery,
    required RecordRecentSearch recordRecentSearch,
  }) : _getListings = getListings,
       _lastAppliedDiscovery = lastAppliedDiscovery,
       _recordRecentSearch = recordRecentSearch,
       super(const ListingsState()) {
    on<ListingsRequested>(_onRequested);
    on<ListingsRefreshed>(_onRefreshed);
    on<ListingsNextPageRequested>(_onNextPage);
    on<ListingsRegionFilterChanged>(_onRegionFilterChanged);
    on<ListingsBodyTypeFilterChanged>(_onBodyTypeFilterChanged);
    on<ListingsSearchChanged>(_onSearchChanged);
    on<ListingsFiltersApplied>(_onFiltersApplied);
    on<ListingsFiltersCleared>(_onFiltersCleared);
    on<ListingsHydratedFromDiscovery>(_onHydratedFromDiscovery);
    on<ListingsDiscoveryFilterRemoved>(_onDiscoveryFilterRemoved);
  }

  final GetListings _getListings;
  final LastAppliedListingDiscoveryRepository _lastAppliedDiscovery;
  final RecordRecentSearch _recordRecentSearch;
  bool _skipNextRecentSearchRecord = false;

  Future<void> _onHydratedFromDiscovery(
    ListingsHydratedFromDiscovery event,
    Emitter<ListingsState> emit,
  ) async {
    _skipNextRecentSearchRecord = true;
    final next = listingsStateFromDiscoveryCriteria(event.criteria).copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(next, emit, page: 0, replace: true);
  }

  Future<void> _onRequested(
    ListingsRequested event,
    Emitter<ListingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0);
  }

  Future<void> _onRefreshed(
    ListingsRefreshed event,
    Emitter<ListingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onNextPage(
    ListingsNextPageRequested event,
    Emitter<ListingsState> emit,
  ) async {
    if (state.hasReachedEnd ||
        state.status == ListingsStatus.loading ||
        state.status == ListingsStatus.loadingMore ||
        (state.status == ListingsStatus.paginationFailure &&
            !event.isExplicitRetry)) {
      return;
    }
    emit(
      state.copyWith(
        status: ListingsStatus.loadingMore,
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: state.page + 1);
  }

  Future<void> _onRegionFilterChanged(
    ListingsRegionFilterChanged event,
    Emitter<ListingsState> emit,
  ) async {
    if (event.filter == state.regionFilter) return;
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        regionFilter: event.filter,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onBodyTypeFilterChanged(
    ListingsBodyTypeFilterChanged event,
    Emitter<ListingsState> emit,
  ) async {
    if (event.bodyType == state.bodyTypeFilter) return;
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        bodyTypeFilter: event.bodyType,
        clearBodyType: event.bodyType == null,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onSearchChanged(
    ListingsSearchChanged event,
    Emitter<ListingsState> emit,
  ) async {
    final trimmed = event.search?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (normalized == state.search) return;
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        search: normalized,
        clearSearch: normalized == null,
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onFiltersApplied(
    ListingsFiltersApplied event,
    Emitter<ListingsState> emit,
  ) async {
    final make = (event.make == null || event.make!.trim().isEmpty)
        ? null
        : event.make!.trim();
    final model = (event.model == null || event.model!.trim().isEmpty)
        ? null
        : event.model!.trim();
    final city = (event.city == null || event.city!.trim().isEmpty)
        ? null
        : event.city!.trim();
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        make: make,
        model: model,
        minYear: event.minYear,
        maxYear: event.maxYear,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        maxMileage: event.maxMileage,
        city: city,
        typeFilter: event.typeFilter,
        sortOption: event.sort,
        regionFilter: event.regionFilter,
        bodyTypeFilter: event.bodyType,
        fuelTypeFilter: event.fuelType,
        transmissionTypeFilter: event.transmissionType,
        priceCurrencyFilter: event.priceCurrencyFilter,
        clearMake: make == null,
        clearModel: model == null,
        clearMinYear: event.minYear == null,
        clearMaxYear: event.maxYear == null,
        clearMinPrice: event.minPrice == null,
        clearMaxPrice: event.maxPrice == null,
        clearMaxMileage: event.maxMileage == null,
        clearCity: city == null,
        clearBodyType: event.bodyType == null,
        clearFuelType: event.fuelType == null,
        clearTransmissionType: event.transmissionType == null,
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onFiltersCleared(
    ListingsFiltersCleared event,
    Emitter<ListingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        typeFilter: ListingTypeFilter.any,
        regionFilter: MarketRegionFilter.both,
        clearSearch: true,
        clearMake: true,
        clearModel: true,
        clearMinYear: true,
        clearMaxYear: true,
        clearMinPrice: true,
        clearMaxPrice: true,
        clearMaxMileage: true,
        clearCity: true,
        clearBodyType: true,
        clearFuelType: true,
        clearTransmissionType: true,
        clearSort: true,
        clearPriceCurrencyFilter: true,
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onDiscoveryFilterRemoved(
    ListingsDiscoveryFilterRemoved event,
    Emitter<ListingsState> emit,
  ) async {
    final cleared = listingsStateAfterDiscoveryChipRemoved(state, event.kind);
    if (cleared == state) return;
    emit(
      cleared.copyWith(
        status: ListingsStatus.loading,
        page: 0,
        hasReachedEnd: false,
        items: const [],
        clearLoadFailure: true,
      ),
    );
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _load(
    Emitter<ListingsState> emit, {
    required int page,
    bool replace = false,
  }) async {
    await _loadWithState(state, emit, page: page, replace: replace);
  }

  Future<void> _loadWithState(
    ListingsState source,
    Emitter<ListingsState> emit, {
    required int page,
    required bool replace,
  }) async {
    final query =
        ListingDiscoveryCriteria(
          search: source.search,
          make: source.make,
          model: source.model,
          minYear: source.minYear,
          maxYear: source.maxYear,
          minPrice: source.minPrice,
          maxPrice: source.maxPrice,
          maxMileage: source.maxMileage,
          city: source.city,
          marketRegion: source.regionFilter.asMarketRegion,
          bodyType: source.bodyTypeFilter,
          fuelType: source.fuelTypeFilter,
          transmissionType: source.transmissionTypeFilter,
          typeIn: source.typeFilter.asListingTypes,
          sort: source.sortOption,
          priceCurrencyFilter: source.priceCurrencyFilter,
        ).toListingsQuery(
          page: page,
          pageSize: AppConstants.defaultPageSize,
          status: ListingStatus.active,
        );

    final result = await _getListings(query);
    switch (result) {
      case FailureResult(:final failure):
        if (!replace && page > 0) {
          emit(
            source.copyWith(
              status: ListingsStatus.paginationFailure,
              loadFailure: failure,
            ),
          );
          return;
        }
        emit(
          source.copyWith(status: ListingsStatus.failure, loadFailure: failure),
        );
      case Success(:final value):
        final newItems = value;
        final merged = (replace || page == 0)
            ? newItems
            : [...source.items, ...newItems];
        final nextState = source.copyWith(
          status: ListingsStatus.success,
          items: merged,
          page: page,
          hasReachedEnd: newItems.length < AppConstants.defaultPageSize,
          clearLoadFailure: true,
        );
        emit(nextState);
        final snapshot = listingDiscoveryCriteriaFromListingsState(nextState);
        unawaited(_lastAppliedDiscovery.persistIfNeeded(snapshot));
        if (page == 0) {
          if (_skipNextRecentSearchRecord) {
            _skipNextRecentSearchRecord = false;
          } else if (browseStateEligibleForFilterAlertSnapshot(nextState)) {
            unawaited(_recordRecentSearch(snapshot));
          }
        }
    }
  }
}
