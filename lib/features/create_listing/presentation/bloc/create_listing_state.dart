import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/seller_listing_defaults.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

enum CreateListingStatus { idle, submitting, success, failure }

/// Discriminates which stage of the create-listing flow failed so the
/// presentation layer can pick the correct localized message without
/// embedding English strings in the cubit.
/// User-facing buckets for localized copy (never expose raw RPC/SQL strings).
enum CreateListingFailureKind {
  /// Cover upload/storage failed before RPC.
  upload,

  /// Auth/session revoked or insufficient rights for the RPC layer.
  sessionExpired,

  /// Transport / reachability failures.
  serviceUnavailable,

  /// Server rejected syntactic VIN (`invalid vin` / related wire hints).
  invalidVin,

  /// PostgREST schema cache / missing RPC signature / undefined function.
  rpcSchemaNotReady,

  /// Explicit permission / privilege denial on the RPC path.
  permissionDenied,

  /// PostgreSQL `CHECK` constraint failure on persisted listing rows.
  checkConstraintViolation,

  /// Server rejected input (validation/business-rule style messages).
  validationRejected,

  /// Server-authoritative UGC filter rejected user-authored text.
  contentRejected,

  /// Other server/transient failures — generic retry messaging.
  genericCreate,
}

enum CreateListingVinResolveStatus {
  idle,
  resolving,
  resolved,
  partial,
  noData,
  failure,
  manual,
  likelyInputError,
}

enum CreateListingDefaultsStatus { idle, loading, ready }

class CreateListingVehicleResolve extends Equatable {
  const CreateListingVehicleResolve({
    this.status = CreateListingVinResolveStatus.idle,
    this.normalizedVin,
    this.lastFetchedNormalizedVin,
    this.suggestion,
    this.confirmed = false,
    this.applyRevision = 0,
    this.confirmedIdentity,
    this.failureKind,
  });

  final CreateListingVinResolveStatus status;
  final String? normalizedVin;
  final String? lastFetchedNormalizedVin;
  final VehicleResolveResult? suggestion;
  final bool confirmed;
  final int applyRevision;
  final ConfirmedVehicleIdentity? confirmedIdentity;
  final VehicleResolveFailureKind? failureKind;

  bool get hasUnconfirmedSuggestion => suggestion != null && !confirmed;

  CreateListingVehicleResolve copyWith({
    CreateListingVinResolveStatus? status,
    String? normalizedVin,
    String? lastFetchedNormalizedVin,
    VehicleResolveResult? suggestion,
    bool? confirmed,
    int? applyRevision,
    ConfirmedVehicleIdentity? confirmedIdentity,
    VehicleResolveFailureKind? failureKind,
    bool clearSuggestion = false,
    bool clearFailure = false,
    bool clearConfirmedIdentity = false,
    bool clearNormalizedVin = false,
  }) {
    return CreateListingVehicleResolve(
      status: status ?? this.status,
      normalizedVin: clearNormalizedVin
          ? null
          : (normalizedVin ?? this.normalizedVin),
      lastFetchedNormalizedVin:
          lastFetchedNormalizedVin ?? this.lastFetchedNormalizedVin,
      suggestion: clearSuggestion ? null : (suggestion ?? this.suggestion),
      confirmed: confirmed ?? this.confirmed,
      applyRevision: applyRevision ?? this.applyRevision,
      confirmedIdentity: clearConfirmedIdentity
          ? null
          : (confirmedIdentity ?? this.confirmedIdentity),
      failureKind: clearFailure ? null : (failureKind ?? this.failureKind),
    );
  }

  @override
  List<Object?> get props => [
    status,
    normalizedVin,
    lastFetchedNormalizedVin,
    suggestion,
    confirmed,
    applyRevision,
    confirmedIdentity,
    failureKind,
  ];
}

class CreateListingListingDefaults extends Equatable {
  const CreateListingListingDefaults({
    this.status = CreateListingDefaultsStatus.idle,
    this.requestedUserId,
    this.values = const SellerListingDefaults.empty(),
    this.prefill = const SellerListingDefaultsPrefill(),
    this.applyRevision = 0,
    this.phoneEdited = false,
    this.telegramEdited = false,
    this.whatsappEdited = false,
    this.regionEdited = false,
    this.cityEdited = false,
  });

  final CreateListingDefaultsStatus status;
  final String? requestedUserId;
  final SellerListingDefaults values;
  final SellerListingDefaultsPrefill prefill;
  final int applyRevision;
  final bool phoneEdited;
  final bool telegramEdited;
  final bool whatsappEdited;
  final bool regionEdited;
  final bool cityEdited;

  SellerListingDefaultsPrefill buildPrefill(SellerListingDefaults defaults) {
    final region = !regionEdited ? defaults.marketRegion : null;
    final cityCompatible =
        !cityEdited && !regionEdited && defaults.marketRegion != null;
    return SellerListingDefaultsPrefill(
      contactPhone: !phoneEdited ? defaults.contactPhone : null,
      telegramUsername: !telegramEdited ? defaults.telegramUsername : null,
      whatsappEnabled: !whatsappEdited && defaults.whatsappEnabled
          ? true
          : null,
      marketRegion: region,
      city: cityCompatible ? defaults.city : null,
    );
  }

  CreateListingListingDefaults copyWith({
    CreateListingDefaultsStatus? status,
    String? requestedUserId,
    SellerListingDefaults? values,
    SellerListingDefaultsPrefill? prefill,
    int? applyRevision,
    bool? phoneEdited,
    bool? telegramEdited,
    bool? whatsappEdited,
    bool? regionEdited,
    bool? cityEdited,
    bool clearRequestedUserId = false,
  }) {
    return CreateListingListingDefaults(
      status: status ?? this.status,
      requestedUserId: clearRequestedUserId
          ? null
          : (requestedUserId ?? this.requestedUserId),
      values: values ?? this.values,
      prefill: prefill ?? this.prefill,
      applyRevision: applyRevision ?? this.applyRevision,
      phoneEdited: phoneEdited ?? this.phoneEdited,
      telegramEdited: telegramEdited ?? this.telegramEdited,
      whatsappEdited: whatsappEdited ?? this.whatsappEdited,
      regionEdited: regionEdited ?? this.regionEdited,
      cityEdited: cityEdited ?? this.cityEdited,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requestedUserId,
    values,
    prefill,
    applyRevision,
    phoneEdited,
    telegramEdited,
    whatsappEdited,
    regionEdited,
    cityEdited,
  ];
}

class CreateListingState extends Equatable {
  const CreateListingState({
    this.status = CreateListingStatus.idle,
    this.created,
    this.failureKind,
    this.vehicleResolve = const CreateListingVehicleResolve(),
    this.listingDefaults = const CreateListingListingDefaults(),
  });

  final CreateListingStatus status;
  final Listing? created;
  final CreateListingFailureKind? failureKind;
  final CreateListingVehicleResolve vehicleResolve;
  final CreateListingListingDefaults listingDefaults;

  /// Legacy getter kept for widget snackbar fallbacks. Always null —
  /// translation lives in the widget now.
  String? get errorMessage => null;

  const CreateListingState.idle() : this();
  const CreateListingState.submitting()
    : this(status: CreateListingStatus.submitting);
  const CreateListingState.success(Listing listing)
    : this(status: CreateListingStatus.success, created: listing);
  const CreateListingState.failure(CreateListingFailureKind kind)
    : this(status: CreateListingStatus.failure, failureKind: kind);

  CreateListingState copyWith({
    CreateListingStatus? status,
    Listing? created,
    CreateListingFailureKind? failureKind,
    CreateListingVehicleResolve? vehicleResolve,
    CreateListingListingDefaults? listingDefaults,
  }) {
    return CreateListingState(
      status: status ?? this.status,
      created: created ?? this.created,
      failureKind: failureKind ?? this.failureKind,
      vehicleResolve: vehicleResolve ?? this.vehicleResolve,
      listingDefaults: listingDefaults ?? this.listingDefaults,
    );
  }

  @override
  List<Object?> get props => [
    status,
    created,
    failureKind,
    vehicleResolve,
    listingDefaults,
  ];
}
