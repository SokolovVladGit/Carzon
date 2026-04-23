import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_listing_by_id.dart';
import 'listing_details_state.dart';

/// Single load action — Cubit is sufficient.
class ListingDetailsCubit extends Cubit<ListingDetailsState> {
  ListingDetailsCubit({required GetListingById getListingById})
      : _getListingById = getListingById,
        super(const ListingDetailsState.initial());

  final GetListingById _getListingById;

  Future<void> load(String id) async {
    emit(const ListingDetailsState.loading());
    final result = await _getListingById(id);
    result.fold(
      (failure) => emit(ListingDetailsState.failure(failure.message)),
      (listing) => emit(ListingDetailsState.success(listing)),
    );
  }
}
