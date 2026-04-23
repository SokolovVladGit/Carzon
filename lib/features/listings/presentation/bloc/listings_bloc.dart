import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
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
      search: event.search,
      make: event.make,
    ));
    await _load(emit, page: 0);
  }

  Future<void> _onRefreshed(
    ListingsRefreshed event,
    Emitter<ListingsState> emit,
  ) async {
    emit(state.copyWith(status: ListingsStatus.loading, page: 0, hasReachedEnd: false));
    await _load(emit, page: 0, replace: true);
  }

  Future<void> _onNextPage(
    ListingsNextPageRequested event,
    Emitter<ListingsState> emit,
  ) async {
    if (state.hasReachedEnd || state.status == ListingsStatus.loadingMore) return;
    emit(state.copyWith(status: ListingsStatus.loadingMore));
    await _load(emit, page: state.page + 1);
  }

  Future<void> _load(
    Emitter<ListingsState> emit, {
    required int page,
    bool replace = false,
  }) async {
    final query = ListingsQuery(
      search: state.search,
      make: state.make,
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
