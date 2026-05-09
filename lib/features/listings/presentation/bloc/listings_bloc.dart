import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../data/local/last_applied_listing_discovery_repository.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../../domain/usecases/get_listings.dart';
import 'listings_event.dart';
import 'listings_state.dart';

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({
    required GetListings getListings,
    required LastAppliedListingDiscoveryRepository lastAppliedDiscovery,
  }) : _getListings = getListings,
       _lastAppliedDiscovery = lastAppliedDiscovery,
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
  }

  final GetListings _getListings;
  final LastAppliedListingDiscoveryRepository _lastAppliedDiscovery;

  Future<void> _onHydratedFromDiscovery(
    ListingsHydratedFromDiscovery event,
    Emitter<ListingsState> emit,
  ) async {
    final next = listingsStateFromDiscoveryCriteria(event.criteria)
        .copyWith(
          status: ListingsStatus.loading,
          page: 0,
          hasReachedEnd: false,
          items: const [],
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
        state.status == ListingsStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: ListingsStatus.loadingMore));
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
        regionFilter: MarketRegionFilter.transnistria,
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
        clearSort: true,
        clearPriceCurrencyFilter: true,
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
    final query = ListingDiscoveryCriteria(
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
        emit(
          source.copyWith(
            status: ListingsStatus.failure,
            errorMessage: failure.message,
          ),
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
          errorMessage: null,
        );
        emit(nextState);
        final snapshot = listingDiscoveryCriteriaFromListingsState(nextState);
        unawaited(_lastAppliedDiscovery.persistIfNeeded(snapshot));
    }
  }
}
