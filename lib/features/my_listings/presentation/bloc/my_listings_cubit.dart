import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../listings/domain/repositories/listings_repository.dart';
import '../../../listings/domain/usecases/get_listings.dart';
import 'my_listings_state.dart';

/// Single load action — Cubit is sufficient. Reuses the existing
/// listings use case with a sellerId-scoped query.
class MyListingsCubit extends Cubit<MyListingsState> {
  MyListingsCubit({required GetListings getListings})
      : _getListings = getListings,
        super(const MyListingsState.initial());

  final GetListings _getListings;

  static const int _pageSize = 50;

  Future<void> load(String sellerId) async {
    emit(const MyListingsState.loading());
    final result = await _getListings(
      ListingsQuery(sellerId: sellerId, page: 0, pageSize: _pageSize),
    );
    result.fold(
      (failure) => emit(MyListingsState.failure(failure.message)),
      (items) => emit(MyListingsState.success(items)),
    );
  }
}
