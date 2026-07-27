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
  int _replacementGeneration = 0;
  int _paginationOperationSequence = 0;
  int? _activePaginationOperation;
  bool _isClosing = false;

  @override
  Future<void> close() {
    _isClosing = true;
    _beginReplacement();
    return super.close();
  }

  Future<void> _onHydratedFromDiscovery(
    ListingsHydratedFromDiscovery event,
    Emitter<ListingsState> emit,
  ) async {
    final generation = _beginReplacement();
    final next = listingsStateFromDiscoveryCriteria(event.criteria).copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
      skipRecentSearchRecord: true,
    );
  }

  Future<void> _onRequested(
    ListingsRequested event,
    Emitter<ListingsState> emit,
  ) async {
    final generation = _beginReplacement();
    final next = state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _onRefreshed(
    ListingsRefreshed event,
    Emitter<ListingsState> emit,
  ) async {
    final generation = _beginReplacement();
    final next = state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
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
    final source = state;
    final generation = _replacementGeneration;
    final page = source.page + 1;
    final paginationOperation = ++_paginationOperationSequence;
    _activePaginationOperation = paginationOperation;
    emit(
      source.copyWith(
        status: ListingsStatus.loadingMore,
        clearLoadFailure: true,
      ),
    );
    await _loadWithState(
      source,
      emit,
      page: page,
      replace: false,
      replacementGeneration: generation,
      paginationOperation: paginationOperation,
    );
  }

  Future<void> _onRegionFilterChanged(
    ListingsRegionFilterChanged event,
    Emitter<ListingsState> emit,
  ) async {
    if (event.filter == state.regionFilter) return;
    final generation = _beginReplacement();
    final next = state.copyWith(
      status: ListingsStatus.loading,
      regionFilter: event.filter,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _onBodyTypeFilterChanged(
    ListingsBodyTypeFilterChanged event,
    Emitter<ListingsState> emit,
  ) async {
    if (event.bodyType == state.bodyTypeFilter) return;
    final generation = _beginReplacement();
    final next = state.copyWith(
      status: ListingsStatus.loading,
      bodyTypeFilter: event.bodyType,
      clearBodyType: event.bodyType == null,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _onSearchChanged(
    ListingsSearchChanged event,
    Emitter<ListingsState> emit,
  ) async {
    final trimmed = event.search?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (normalized == state.search) return;
    final generation = _beginReplacement();
    final next = state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      search: normalized,
      clearSearch: normalized == null,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
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
    final generation = _beginReplacement();
    final next = state.copyWith(
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
      drivetrainFilter: event.drivetrain,
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
      clearDrivetrain: event.drivetrain == null,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _onFiltersCleared(
    ListingsFiltersCleared event,
    Emitter<ListingsState> emit,
  ) async {
    final generation = _beginReplacement();
    final next = state.copyWith(
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
      clearDrivetrain: true,
      clearSort: true,
      clearPriceCurrencyFilter: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _onDiscoveryFilterRemoved(
    ListingsDiscoveryFilterRemoved event,
    Emitter<ListingsState> emit,
  ) async {
    final cleared = listingsStateAfterDiscoveryChipRemoved(state, event.kind);
    if (cleared == state) return;
    final generation = _beginReplacement();
    final next = cleared.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      clearLoadFailure: true,
    );
    emit(next);
    await _loadWithState(
      next,
      emit,
      page: 0,
      replace: true,
      replacementGeneration: generation,
    );
  }

  Future<void> _loadWithState(
    ListingsState source,
    Emitter<ListingsState> emit, {
    required int page,
    required bool replace,
    required int replacementGeneration,
    int? paginationOperation,
    bool skipRecentSearchRecord = false,
  }) async {
    final criteria = listingDiscoveryCriteriaFromListingsState(source);
    final query = criteria.toListingsQuery(
      page: page,
      pageSize: AppConstants.defaultPageSize,
      status: ListingStatus.active,
    );

    final result = await _getListings(query);
    if (!_isAuthoritative(
      emit,
      source: source,
      criteria: criteria,
      page: page,
      replacementGeneration: replacementGeneration,
      paginationOperation: paginationOperation,
    )) {
      return;
    }
    if (paginationOperation != null) {
      _activePaginationOperation = null;
    }
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
          if (!skipRecentSearchRecord &&
              browseStateEligibleForFilterAlertSnapshot(nextState)) {
            unawaited(_recordRecentSearch(snapshot));
          }
        }
    }
  }

  int _beginReplacement() {
    _activePaginationOperation = null;
    return ++_replacementGeneration;
  }

  bool _isAuthoritative(
    Emitter<ListingsState> emit, {
    required ListingsState source,
    required ListingDiscoveryCriteria criteria,
    required int page,
    required int replacementGeneration,
    required int? paginationOperation,
  }) {
    if (_isClosing ||
        isClosed ||
        emit.isDone ||
        replacementGeneration != _replacementGeneration ||
        criteria != listingDiscoveryCriteriaFromListingsState(state)) {
      return false;
    }
    if (paginationOperation == null) {
      return page == 0 && state.status == ListingsStatus.loading;
    }
    return _activePaginationOperation == paginationOperation &&
        state.status == ListingsStatus.loadingMore &&
        state.page == source.page &&
        page == source.page + 1;
  }
}
