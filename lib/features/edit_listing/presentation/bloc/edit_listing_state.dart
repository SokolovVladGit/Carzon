import 'package:equatable/equatable.dart';

import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../models/edit_listing_gallery_slot.dart';

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
/// localized copy — the cubit itself never builds user-facing text.
enum EditListingFailureKind {
  /// The initial load could not fetch the listing.
  load,

  /// The user is not allowed to edit this listing (owner check or
  /// auth issue reported by the RPC).
  notAllowed,

  /// The `update_listing_details_v2` RPC rejected the input for data
  /// validation reasons (bad year range, missing required field, …).
  invalidDetails,

  /// Generic details-update failure that is neither auth nor
  /// validation.
  detailsFailed,

  /// Uploading one or more new gallery images to Storage failed.
  uploadFailed,

  /// The `replace_listing_images` RPC failed after successful uploads.
  galleryReplaceFailed,

  /// Legacy: cover-only path (kept for localization / tests that still
  /// reference historical failure kinds). No longer produced by the v2
  /// save flow when using [EditListingCubit.save].
  coverUpdateFailed,
}

class EditListingState extends Equatable {
  const EditListingState({
    this.status = EditListingStatus.initial,
    this.listing,
    this.failureKind,
    this.listingGalleryImages = const <ListingImage>[],
    this.galleryLoadSucceeded = false,
    this.initialGallerySlots = const <EditListingGallerySlot>[],
    this.ownerVinNormalizedForEdit,
    this.ownerVinLookupFailed = false,
    this.ownerVinReportStatus,
    this.ownerVinReportLookupFailed = false,
    this.ownerVinSourceResults = const [],
    this.ownerVinSourceResultsLookupFailed = false,
  });

  final EditListingStatus status;
  final Listing? listing;
  final List<ListingImage> listingGalleryImages;
  final bool galleryLoadSucceeded;
  final List<EditListingGallerySlot> initialGallerySlots;
  final EditListingFailureKind? failureKind;

  /// Normalized VIN from owner RPC when present; used only to seed the field.
  final String? ownerVinNormalizedForEdit;

  /// When true, preserve semantics apply if the user leaves the field unchanged.
  final bool ownerVinLookupFailed;

  /// Owner-only decode/processing snapshot from `get_my_listing_vin_report_status`.
  final OwnerListingVinReportStatus? ownerVinReportStatus;

  /// Non-fatal: VIN report RPC failed; editing must still work.
  final bool ownerVinReportLookupFailed;

  /// Owner-only rows from `get_my_listing_vin_source_results` (sanitized).
  final List<OwnerListingVinSourceResult> ownerVinSourceResults;

  /// Non-fatal: source-results RPC failed.
  final bool ownerVinSourceResultsLookupFailed;

  const EditListingState.initial() : this();

  const EditListingState.loading()
    : this(
        status: EditListingStatus.loading,
        listingGalleryImages: const <ListingImage>[],
      );

  const EditListingState.ready(
    Listing listing, {
    List<ListingImage> listingGalleryImages = const <ListingImage>[],
    bool galleryLoadSucceeded = true,
    List<EditListingGallerySlot> initialGallerySlots =
        const <EditListingGallerySlot>[],
    String? ownerVinNormalizedForEdit,
    bool ownerVinLookupFailed = false,
    OwnerListingVinReportStatus? ownerVinReportStatus,
    bool ownerVinReportLookupFailed = false,
    List<OwnerListingVinSourceResult> ownerVinSourceResults =
        const <OwnerListingVinSourceResult>[],
    bool ownerVinSourceResultsLookupFailed = false,
  }) : this(
         status: EditListingStatus.ready,
         listing: listing,
         listingGalleryImages: listingGalleryImages,
         galleryLoadSucceeded: galleryLoadSucceeded,
         initialGallerySlots: initialGallerySlots,
         ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
         ownerVinLookupFailed: ownerVinLookupFailed,
         ownerVinReportStatus: ownerVinReportStatus,
         ownerVinReportLookupFailed: ownerVinReportLookupFailed,
         ownerVinSourceResults: ownerVinSourceResults,
         ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
       );

  const EditListingState.submitting(
    Listing listing, {
    List<ListingImage> listingGalleryImages = const <ListingImage>[],
    bool galleryLoadSucceeded = true,
    List<EditListingGallerySlot> initialGallerySlots =
        const <EditListingGallerySlot>[],
    String? ownerVinNormalizedForEdit,
    bool ownerVinLookupFailed = false,
    OwnerListingVinReportStatus? ownerVinReportStatus,
    bool ownerVinReportLookupFailed = false,
    List<OwnerListingVinSourceResult> ownerVinSourceResults =
        const <OwnerListingVinSourceResult>[],
    bool ownerVinSourceResultsLookupFailed = false,
  }) : this(
         status: EditListingStatus.submitting,
         listing: listing,
         listingGalleryImages: listingGalleryImages,
         galleryLoadSucceeded: galleryLoadSucceeded,
         initialGallerySlots: initialGallerySlots,
         ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
         ownerVinLookupFailed: ownerVinLookupFailed,
         ownerVinReportStatus: ownerVinReportStatus,
         ownerVinReportLookupFailed: ownerVinReportLookupFailed,
         ownerVinSourceResults: ownerVinSourceResults,
         ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
       );

  const EditListingState.success(
    Listing listing, {
    List<ListingImage> listingGalleryImages = const <ListingImage>[],
    bool galleryLoadSucceeded = true,
    List<EditListingGallerySlot> initialGallerySlots =
        const <EditListingGallerySlot>[],
    String? ownerVinNormalizedForEdit,
    bool ownerVinLookupFailed = false,
    OwnerListingVinReportStatus? ownerVinReportStatus,
    bool ownerVinReportLookupFailed = false,
    List<OwnerListingVinSourceResult> ownerVinSourceResults =
        const <OwnerListingVinSourceResult>[],
    bool ownerVinSourceResultsLookupFailed = false,
  }) : this(
         status: EditListingStatus.success,
         listing: listing,
         listingGalleryImages: listingGalleryImages,
         galleryLoadSucceeded: galleryLoadSucceeded,
         initialGallerySlots: initialGallerySlots,
         ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
         ownerVinLookupFailed: ownerVinLookupFailed,
         ownerVinReportStatus: ownerVinReportStatus,
         ownerVinReportLookupFailed: ownerVinReportLookupFailed,
         ownerVinSourceResults: ownerVinSourceResults,
         ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
       );

  const EditListingState.loadFailure({
    EditListingFailureKind kind = EditListingFailureKind.load,
  }) : this(
         status: EditListingStatus.failure,
         failureKind: kind,
         listingGalleryImages: const <ListingImage>[],
         galleryLoadSucceeded: false,
         initialGallerySlots: const <EditListingGallerySlot>[],
       );

  const EditListingState.saveFailure(
    Listing listing,
    EditListingFailureKind kind, {
    List<ListingImage> listingGalleryImages = const <ListingImage>[],
    bool galleryLoadSucceeded = true,
    List<EditListingGallerySlot> initialGallerySlots =
        const <EditListingGallerySlot>[],
    String? ownerVinNormalizedForEdit,
    bool ownerVinLookupFailed = false,
    OwnerListingVinReportStatus? ownerVinReportStatus,
    bool ownerVinReportLookupFailed = false,
    List<OwnerListingVinSourceResult> ownerVinSourceResults =
        const <OwnerListingVinSourceResult>[],
    bool ownerVinSourceResultsLookupFailed = false,
  }) : this(
         status: EditListingStatus.failure,
         listing: listing,
         failureKind: kind,
         listingGalleryImages: listingGalleryImages,
         galleryLoadSucceeded: galleryLoadSucceeded,
         initialGallerySlots: initialGallerySlots,
         ownerVinNormalizedForEdit: ownerVinNormalizedForEdit,
         ownerVinLookupFailed: ownerVinLookupFailed,
         ownerVinReportStatus: ownerVinReportStatus,
         ownerVinReportLookupFailed: ownerVinReportLookupFailed,
         ownerVinSourceResults: ownerVinSourceResults,
         ownerVinSourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
       );

  EditListingState copyWith({
    EditListingStatus? status,
    Listing? listing,
    List<ListingImage>? listingGalleryImages,
    bool? galleryLoadSucceeded,
    List<EditListingGallerySlot>? initialGallerySlots,
    EditListingFailureKind? failureKind,
    bool clearFailureKind = false,
    String? ownerVinNormalizedForEdit,
    bool? ownerVinLookupFailed,
    OwnerListingVinReportStatus? ownerVinReportStatus,
    bool? ownerVinReportLookupFailed,
    List<OwnerListingVinSourceResult>? ownerVinSourceResults,
    bool? ownerVinSourceResultsLookupFailed,
  }) {
    return EditListingState(
      status: status ?? this.status,
      listing: listing ?? this.listing,
      listingGalleryImages: listingGalleryImages ?? this.listingGalleryImages,
      galleryLoadSucceeded: galleryLoadSucceeded ?? this.galleryLoadSucceeded,
      initialGallerySlots: initialGallerySlots ?? this.initialGallerySlots,
      failureKind: clearFailureKind ? null : (failureKind ?? this.failureKind),
      ownerVinNormalizedForEdit:
          ownerVinNormalizedForEdit ?? this.ownerVinNormalizedForEdit,
      ownerVinLookupFailed: ownerVinLookupFailed ?? this.ownerVinLookupFailed,
      ownerVinReportStatus: ownerVinReportStatus ?? this.ownerVinReportStatus,
      ownerVinReportLookupFailed:
          ownerVinReportLookupFailed ?? this.ownerVinReportLookupFailed,
      ownerVinSourceResults:
          ownerVinSourceResults ?? this.ownerVinSourceResults,
      ownerVinSourceResultsLookupFailed:
          ownerVinSourceResultsLookupFailed ??
          this.ownerVinSourceResultsLookupFailed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    listing,
    listingGalleryImages,
    galleryLoadSucceeded,
    initialGallerySlots,
    failureKind,
    ownerVinNormalizedForEdit,
    ownerVinLookupFailed,
    ownerVinReportStatus,
    ownerVinReportLookupFailed,
    ownerVinSourceResults,
    ownerVinSourceResultsLookupFailed,
  ];
}
