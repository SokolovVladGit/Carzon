import 'package:equatable/equatable.dart';

import '../../../create_listing/domain/entities/cover_image_upload.dart';
import '../../../listings/domain/entities/listing.dart';

/// Lifecycle of the edit-listing screen:
///   * `initial` → page just opened
///   * `loading` → fetching the listing to seed the form
///   * `ready` → form is visible and editable
///   * `submitting` → save in flight (derived from [ready] semantics
///     but kept flat here to keep UI logic simple)
///   * `success` → save succeeded, carries the refreshed listing
///   * `failure` → either load failed or save failed; which one is
///     distinguished by [listing] being null vs non-null
enum EditListingStatus { initial, loading, ready, submitting, success, failure }

/// Discriminates why the current [EditListingState] is in
/// [EditListingStatus.failure]. The presentation layer maps this into
/// a localized message — the cubit itself never builds user-facing
/// text.
enum EditListingFailureKind {
  /// The initial load could not fetch the listing.
  load,

  /// The user is not allowed to edit this listing (owner check or
  /// auth issue reported by the RPC).
  notAllowed,

  /// The `update_listing_details` RPC rejected the input for data
  /// validation reasons (bad year range, missing required field, …).
  invalidDetails,

  /// Generic details-update failure that is neither auth nor
  /// validation.
  detailsFailed,

  /// Uploading the staged cover image to Storage failed.
  uploadFailed,

  /// The `update_listing_cover_image` RPC rejected the new URL.
  coverUpdateFailed,
}

/// Pending user-initiated change to the cover image, staged locally
/// until the Save action. Exactly one of the three branches is active
/// at a time:
///   * a [CoverImageUpload] value → user picked a new image to upload
///     on save
///   * pending removal flag → user tapped "Remove photo"; on save the
///     cover will be cleared
///   * neither → cover stays exactly as it is on the server
class EditListingState extends Equatable {
  const EditListingState({
    this.status = EditListingStatus.initial,
    this.listing,
    this.failureKind,
    this.pendingCoverReplacement,
    this.pendingCoverRemoval = false,
  });

  final EditListingStatus status;

  /// The listing we are editing. Populated by [load] when the fetch
  /// succeeds and replaced on save success. Null while loading or
  /// if the initial load failed.
  final Listing? listing;

  /// Reason for the current failure state, when [status] is
  /// [EditListingStatus.failure]. Presentation maps this to a
  /// localized message via [AppLocalizations].
  final EditListingFailureKind? failureKind;

  /// A locally-picked replacement image that has not been uploaded
  /// yet. When non-null, [pendingCoverRemoval] is always false.
  final CoverImageUpload? pendingCoverReplacement;

  /// True when the user tapped "Remove photo" and has not yet saved.
  /// When true, [pendingCoverReplacement] is always null.
  final bool pendingCoverRemoval;

  const EditListingState.initial() : this();

  const EditListingState.loading()
      : this(status: EditListingStatus.loading);

  const EditListingState.ready(Listing listing)
      : this(status: EditListingStatus.ready, listing: listing);

  const EditListingState.submitting(Listing listing)
      : this(status: EditListingStatus.submitting, listing: listing);

  const EditListingState.success(Listing listing)
      : this(status: EditListingStatus.success, listing: listing);

  const EditListingState.loadFailure()
      : this(
          status: EditListingStatus.failure,
          failureKind: EditListingFailureKind.load,
        );

  const EditListingState.saveFailure(
    Listing listing,
    EditListingFailureKind kind,
  ) : this(
          status: EditListingStatus.failure,
          listing: listing,
          failureKind: kind,
        );

  EditListingState copyWith({
    EditListingStatus? status,
    Listing? listing,
    EditListingFailureKind? failureKind,
    bool clearFailureKind = false,
    CoverImageUpload? pendingCoverReplacement,
    bool clearPendingCoverReplacement = false,
    bool? pendingCoverRemoval,
  }) {
    return EditListingState(
      status: status ?? this.status,
      listing: listing ?? this.listing,
      failureKind:
          clearFailureKind ? null : (failureKind ?? this.failureKind),
      pendingCoverReplacement: clearPendingCoverReplacement
          ? null
          : (pendingCoverReplacement ?? this.pendingCoverReplacement),
      pendingCoverRemoval: pendingCoverRemoval ?? this.pendingCoverRemoval,
    );
  }

  @override
  List<Object?> get props => [
        status,
        listing,
        failureKind,
        pendingCoverReplacement,
        pendingCoverRemoval,
      ];
}
