import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/new_listing_input.dart';
import '../../domain/usecases/create_listing.dart';
import 'create_listing_state.dart';

/// Single submit action — Cubit is sufficient (no event-driven flow).
class CreateListingCubit extends Cubit<CreateListingState> {
  CreateListingCubit({required CreateListing createListing})
      : _createListing = createListing,
        super(const CreateListingState.idle());

  final CreateListing _createListing;

  Future<void> submit(NewListingInput input) async {
    if (state.status == CreateListingStatus.submitting) return;
    emit(const CreateListingState.submitting());
    final result = await _createListing(input);
    result.fold(
      (failure) => emit(CreateListingState.failure(failure.message)),
      (listing) => emit(CreateListingState.success(listing)),
    );
  }
}
