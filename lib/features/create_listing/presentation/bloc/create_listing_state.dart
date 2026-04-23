import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum CreateListingStatus { idle, submitting, success, failure }

class CreateListingState extends Equatable {
  const CreateListingState({
    this.status = CreateListingStatus.idle,
    this.created,
    this.errorMessage,
  });

  final CreateListingStatus status;
  final Listing? created;
  final String? errorMessage;

  const CreateListingState.idle() : this();
  const CreateListingState.submitting() : this(status: CreateListingStatus.submitting);
  const CreateListingState.success(Listing listing)
      : this(status: CreateListingStatus.success, created: listing);
  const CreateListingState.failure(String message)
      : this(status: CreateListingStatus.failure, errorMessage: message);

  @override
  List<Object?> get props => [status, created, errorMessage];
}
