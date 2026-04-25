import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../../domain/usecases/get_listings.dart';
import 'listings_event.dart';
import 'listings_state.dart';

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({required GetListings getListings})
      : _getListings = getListings,
        super(const ListingsState()) {
    on<ListingsRequested>(_onRequested);
    on<ListingsRefreshed>(_onRefreshed);
    on<ListingsNextPageRequested>(_onNextPage);
    on<ListingsRegionFilterChanged>(_onRegionFilterChanged);
    on<ListingsSearchChanged>(_onSearchChanged);
    on<ListingsFiltersApplied>(_onFiltersApplied);
    on<ListingsFiltersCleared>(_onFiltersCleared);
  }

  final GetListings _getListings;

  Future<void> _onRequested(
    ListingsRequested event,
    Emitter<ListingsState> emit,
  ) async {
    emit(state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
    ));
    await _load(emit, page: 0);
  }

  Future<void> _onRefreshed(
    ListingsRefreshed event,
    Emitter<ListingsState> emit,
  ) async {
    emit(state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
    ));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onNextPage(
    ListingsNextPageRequested event,
    Emitter<ListingsState> emit,
  ) async {
    // Guard against both `loadingMore` (another page already in flight) and
    // `loading` (a page-0 reload from a filter/region/search change that has
    // not completed yet). Without the `loading` guard, a fast scroll during
    // a filter change can issue a concurrent page-1 fetch off an empty list.
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
    emit(state.copyWith(
      status: ListingsStatus.loading,
      regionFilter: event.filter,
      page: 0,
      hasReachedEnd: false,
      items: const [],
    ));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onSearchChanged(
    ListingsSearchChanged event,
    Emitter<ListingsState> emit,
  ) async {
    final trimmed = event.search?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (normalized == state.search) return;
    emit(state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      search: normalized,
      clearSearch: normalized == null,
    ));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onFiltersApplied(
    ListingsFiltersApplied event,
    Emitter<ListingsState> emit,
  ) async {
    final make = (event.make == null || event.make!.trim().isEmpty)
        ? null
        : event.make!.trim();
    emit(state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      make: make,
      minYear: event.minYear,
      maxYear: event.maxYear,
      typeFilter: event.typeFilter,
      clearMake: make == null,
      clearMinYear: event.minYear == null,
      clearMaxYear: event.maxYear == null,
    ));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onFiltersCleared(
    ListingsFiltersCleared event,
    Emitter<ListingsState> emit,
  ) async {
    emit(state.copyWith(
      status: ListingsStatus.loading,
      page: 0,
      hasReachedEnd: false,
      items: const [],
      typeFilter: ListingTypeFilter.any,
      clearSearch: true,
      clearMake: true,
      clearMinYear: true,
      clearMaxYear: true,
    ));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _load(
    Emitter<ListingsState> emit, {
    required int page,
    bool replace = false,
  }) async {
    final query = ListingsQuery(
      search: state.search,
      make: state.make,
      minYear: state.minYear,
      maxYear: state.maxYear,
      typeIn: state.typeFilter.asListingTypes,
      marketRegion: state.regionFilter.asMarketRegion,
      // Public feed is always explicitly active-only, regardless of RLS.
      // This prevents authenticated owners from seeing their own
      // hidden/sold/archived listings in the main feed.
      status: ListingStatus.active,
      page: page,
      pageSize: AppConstants.defaultPageSize,
    );

    final result = await _getListings(query);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ListingsStatus.failure,
        errorMessage: failure.message,
      )),
      (newItems) {
        final merged = (replace || page == 0)
            ? newItems
            : [...state.items, ...newItems];
        emit(state.copyWith(
          status: ListingsStatus.success,
          items: merged,
          page: page,
          hasReachedEnd: newItems.length < AppConstants.defaultPageSize,
        ));
      },
    );
  }
}
