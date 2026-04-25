import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum CreateListingStatus { idle, submitting, success, failure }

/// Discriminates which stage of the create-listing flow failed so the
/// presentation layer can pick the correct localized message without
/// embedding English strings in the cubit.
enum CreateListingFailureKind { upload, create }

class CreateListingState extends Equatable {
  const CreateListingState({
    this.status = CreateListingStatus.idle,
    this.created,
    this.failureKind,
  });

  final CreateListingStatus status;
  final Listing? created;
  final CreateListingFailureKind? failureKind;

  /// Legacy getter kept for widget snackbar fallbacks. Always null —
  /// translation lives in the widget now.
  String? get errorMessage => null;

  const CreateListingState.idle() : this();
  const CreateListingState.submitting() : this(status: CreateListingStatus.submitting);
  const CreateListingState.success(Listing listing)
      : this(status: CreateListingStatus.success, created: listing);
  const CreateListingState.failure(CreateListingFailureKind kind)
      : this(status: CreateListingStatus.failure, failureKind: kind);

  @override
  List<Object?> get props => [status, created, failureKind];
}
