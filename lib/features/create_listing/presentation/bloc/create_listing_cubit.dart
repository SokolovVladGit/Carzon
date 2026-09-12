import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/validation/listing_vin.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../../domain/entities/seller_listing_defaults.dart';
import '../../domain/entities/uploaded_listing_image.dart';
import '../../domain/entities/vehicle_resolve_result.dart';
import '../../domain/usecases/create_listing_v2.dart';
import '../../domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../../domain/usecases/get_my_listing_defaults.dart';
import '../../domain/usecases/resolve_vehicle.dart';
import '../../domain/usecases/save_my_listing_defaults.dart';
import '../../domain/usecases/upload_listing_images_sequential.dart';
import '../utils/create_listing_failure_kind_for.dart';
import 'create_listing_state.dart';

/// Create listing via RPC `create_listing_v2` with optional sequential gallery uploads.
///
/// VIN resolve is an accelerator only. Unconfirmed suggestions are never
/// listing identity. Submit still uses seller-authored [NewListingInput].
class CreateListingCubit extends Cubit<CreateListingState> {
  CreateListingCubit({
    required CreateListingV2 createListingV2,
    required UploadListingImagesSequential uploadListingImagesSequential,
    required DeleteUploadedListingImagesBestEffort
    deleteUploadedListingImagesBestEffort,
    required ResolveVehicle resolveVehicle,
    required String? Function() currentUserId,
    Stream<String?>? authUserChanges,
    GetMyListingDefaults? getMyListingDefaults,
    SaveMyListingDefaults? saveMyListingDefaults,
    this.resolveDebounce = const Duration(milliseconds: 400),
  }) : _createListingV2 = createListingV2,
       _uploadSequential = uploadListingImagesSequential,
       _deleteStaging = deleteUploadedListingImagesBestEffort,
       _resolveVehicle = resolveVehicle,
       _readCurrentUserId = currentUserId,
       _getMyListingDefaults = getMyListingDefaults,
       _saveMyListingDefaults = saveMyListingDefaults,
       super(const CreateListingState.idle()) {
    _currentUserId = currentUserId();
    _authSubscription = authUserChanges?.listen(syncWithAuth);
  }

  final CreateListingV2 _createListingV2;
  final UploadListingImagesSequential _uploadSequential;
  final DeleteUploadedListingImagesBestEffort _deleteStaging;
  final ResolveVehicle _resolveVehicle;
  final GetMyListingDefaults? _getMyListingDefaults;
  final SaveMyListingDefaults? _saveMyListingDefaults;
  final Duration resolveDebounce;
  final String? Function() _readCurrentUserId;
  StreamSubscription<String?>? _authSubscription;
  String? _currentUserId;
  int _sessionGeneration = 0;

  /// Identity transitions invalidate all outstanding work, including A→B→A.
  /// The live getter also catches changes before the auth stream is delivered.
  void syncWithAuth(String? userId) {
    if (isClosed || userId == _currentUserId) return;
    _currentUserId = userId;
    _sessionGeneration += 1;
    _defaultsGeneration += 1;
    _resolveGeneration += 1;
    _debounce?.cancel();
    _inFlightNormalizedVin = null;
    emit(const CreateListingState.idle());
  }

  bool _isCurrentSession(String userId, int generation) {
    if (isClosed) return false;
    syncWithAuth(_readCurrentUserId());
    return generation == _sessionGeneration && _currentUserId == userId;
  }

  Timer? _debounce;
  int _resolveGeneration = 0;
  String? _inFlightNormalizedVin;
  int _defaultsGeneration = 0;

  @override
  Future<void> close() {
    _sessionGeneration += 1;
    unawaited(_authSubscription?.cancel());
    _debounce?.cancel();
    _resolveGeneration += 1;
    _defaultsGeneration += 1;
    return super.close();
  }

  Future<void> loadListingDefaults({required String userId}) async {
    if (isClosed) return;
    syncWithAuth(_readCurrentUserId());
    final trimmed = userId.trim();
    if (trimmed.isEmpty || trimmed != _currentUserId) return;
    final sessionGeneration = _sessionGeneration;

    final previousUserId = state.listingDefaults.requestedUserId;
    final switchedUser = previousUserId != null && previousUserId != trimmed;
    final generation = ++_defaultsGeneration;

    final next = switchedUser
        ? const CreateListingListingDefaults()
        : state.listingDefaults;

    emit(
      state.copyWith(
        listingDefaults: next.copyWith(
          status: CreateListingDefaultsStatus.loading,
          requestedUserId: trimmed,
        ),
      ),
    );

    if (_getMyListingDefaults == null) {
      if (isClosed || generation != _defaultsGeneration) return;
      emit(
        state.copyWith(
          listingDefaults: state.listingDefaults.copyWith(
            status: CreateListingDefaultsStatus.ready,
            values: const SellerListingDefaults.empty(),
            prefill: const SellerListingDefaultsPrefill(),
            applyRevision: state.listingDefaults.applyRevision + 1,
          ),
        ),
      );
      return;
    }

    final result = await _getMyListingDefaults();
    if (!_isCurrentSession(trimmed, sessionGeneration)) return;
    if (generation != _defaultsGeneration ||
        state.listingDefaults.requestedUserId != trimmed) {
      return;
    }

    final values = switch (result) {
      Success(:final value) => value,
      FailureResult() => const SellerListingDefaults.empty(),
    };
    final snapshot = state.listingDefaults;
    emit(
      state.copyWith(
        listingDefaults: snapshot.copyWith(
          status: CreateListingDefaultsStatus.ready,
          values: values,
          prefill: snapshot.buildPrefill(values),
          applyRevision: snapshot.applyRevision + 1,
        ),
      ),
    );
  }

  void markPhoneEdited() => _markFieldEdited(phone: true);

  void markTelegramEdited() => _markFieldEdited(telegram: true);

  void markWhatsappEdited() => _markFieldEdited(whatsapp: true);

  void markRegionEdited() => _markFieldEdited(region: true, city: true);

  void markCityEdited() => _markFieldEdited(region: true, city: true);

  void _markFieldEdited({
    bool phone = false,
    bool telegram = false,
    bool whatsapp = false,
    bool region = false,
    bool city = false,
  }) {
    final current = state.listingDefaults;
    if ((!phone || current.phoneEdited) &&
        (!telegram || current.telegramEdited) &&
        (!whatsapp || current.whatsappEdited) &&
        (!region || current.regionEdited) &&
        (!city || current.cityEdited)) {
      return;
    }
    emit(
      state.copyWith(
        listingDefaults: current.copyWith(
          phoneEdited: phone ? true : null,
          telegramEdited: telegram ? true : null,
          whatsappEdited: whatsapp ? true : null,
          regionEdited: region ? true : null,
          cityEdited: city ? true : null,
        ),
      ),
    );
  }

  void onVinChanged(String raw) {
    final normalized = ListingVin.normalizeOptional(raw);
    final previous = state.vehicleResolve;
    final current = normalized != previous.normalizedVin
        ? previous.copyWith(clearConfirmedIdentity: true)
        : previous;

    if (normalized == null) {
      _debounce?.cancel();
      _inFlightNormalizedVin = null;
      _resolveGeneration += 1;
      emit(
        state.copyWith(
          vehicleResolve: current.copyWith(
            status: CreateListingVinResolveStatus.idle,
            confirmed: false,
            clearNormalizedVin: true,
            clearSuggestion: true,
            clearFailure: true,
          ),
        ),
      );
      return;
    }

    if (!ListingVin.isValidNormalized(normalized)) {
      _debounce?.cancel();
      _inFlightNormalizedVin = null;
      _resolveGeneration += 1;
      emit(
        state.copyWith(
          vehicleResolve: current.copyWith(
            status: CreateListingVinResolveStatus.idle,
            normalizedVin: normalized,
            confirmed: false,
            clearSuggestion: true,
            clearFailure: true,
          ),
        ),
      );
      return;
    }

    if (!ListingVin.canAttemptResolve(normalized)) {
      _debounce?.cancel();
      _inFlightNormalizedVin = null;
      _resolveGeneration += 1;
      emit(
        state.copyWith(
          vehicleResolve: current.copyWith(
            status: CreateListingVinResolveStatus.likelyInputError,
            normalizedVin: normalized,
            confirmed: false,
            clearSuggestion: true,
            clearFailure: true,
          ),
        ),
      );
      return;
    }

    if (normalized == current.normalizedVin &&
        (current.status == CreateListingVinResolveStatus.resolving ||
            current.lastFetchedNormalizedVin == normalized ||
            _inFlightNormalizedVin == normalized)) {
      return;
    }

    _debounce?.cancel();
    _inFlightNormalizedVin = null;
    _resolveGeneration += 1;
    emit(
      state.copyWith(
        vehicleResolve: current.copyWith(
          status: CreateListingVinResolveStatus.idle,
          normalizedVin: normalized,
          confirmed: false,
          clearSuggestion: true,
          clearFailure: true,
        ),
      ),
    );

    _debounce = Timer(resolveDebounce, () {
      unawaited(_resolveCurrentVin(normalized));
    });
  }

  Future<void> retryResolve() async {
    final vin = state.vehicleResolve.normalizedVin;
    if (vin == null || !ListingVin.canAttemptResolve(vin)) return;
    _debounce?.cancel();
    await _resolveCurrentVin(vin, force: true);
  }

  void enterManualMode() {
    _debounce?.cancel();
    _inFlightNormalizedVin = null;
    _resolveGeneration += 1;
    emit(
      state.copyWith(
        vehicleResolve: state.vehicleResolve.copyWith(
          status: CreateListingVinResolveStatus.manual,
          confirmed: false,
          clearSuggestion: true,
          clearFailure: true,
        ),
      ),
    );
  }

  void confirmSuggestion() {
    final resolve = state.vehicleResolve;
    final suggestion = resolve.suggestion;
    if (suggestion == null) return;
    if (suggestion.resolution != VehicleResolveResolution.resolved) return;
    if (!suggestion.vehicle.hasCoreIdentity) return;

    final identity = ConfirmedVehicleIdentity(
      make: suggestion.vehicle.make!.trim(),
      model: suggestion.vehicle.model!.trim(),
      year: suggestion.vehicle.year!,
      variant: suggestion.vehicle.variantHint,
    );

    emit(
      state.copyWith(
        vehicleResolve: resolve.copyWith(
          confirmed: true,
          applyRevision: resolve.applyRevision + 1,
          confirmedIdentity: identity,
          failureKind: null,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _resolveCurrentVin(
    String normalized, {
    bool force = false,
  }) async {
    if (!ListingVin.canAttemptResolve(normalized)) return;
    final latest = state.vehicleResolve.normalizedVin;
    if (latest != normalized) return;
    if (!force &&
        state.vehicleResolve.lastFetchedNormalizedVin == normalized &&
        state.vehicleResolve.suggestion != null) {
      return;
    }
    if (!force && _inFlightNormalizedVin == normalized) return;

    final generation = ++_resolveGeneration;
    _inFlightNormalizedVin = normalized;
    emit(
      state.copyWith(
        vehicleResolve: state.vehicleResolve.copyWith(
          status: CreateListingVinResolveStatus.resolving,
          normalizedVin: normalized,
          confirmed: false,
          clearFailure: true,
        ),
      ),
    );

    final result = await _resolveVehicle(vin: normalized);
    if (isClosed) return;
    if (generation != _resolveGeneration ||
        state.vehicleResolve.normalizedVin != normalized) {
      if (_inFlightNormalizedVin == normalized) {
        _inFlightNormalizedVin = null;
      }
      return;
    }
    _inFlightNormalizedVin = null;

    switch (result) {
      case FailureResult(:final failure):
        final kind = failure is VehicleResolveFailure
            ? failure.kind
            : VehicleResolveFailureKind.internalError;
        emit(
          state.copyWith(
            vehicleResolve: state.vehicleResolve.copyWith(
              status: CreateListingVinResolveStatus.failure,
              failureKind: kind,
              lastFetchedNormalizedVin: normalized,
              confirmed: false,
              clearSuggestion: true,
            ),
          ),
        );
      case Success(:final value):
        final status = switch (value.resolution) {
          VehicleResolveResolution.resolved =>
            CreateListingVinResolveStatus.resolved,
          VehicleResolveResolution.partial =>
            CreateListingVinResolveStatus.partial,
          VehicleResolveResolution.noData =>
            CreateListingVinResolveStatus.noData,
        };
        emit(
          state.copyWith(
            vehicleResolve: state.vehicleResolve.copyWith(
              status: status,
              suggestion: value,
              lastFetchedNormalizedVin: normalized,
              confirmed: false,
              clearFailure: true,
            ),
          ),
        );
    }
  }

  /// [orderedPhotos]: index 0 = cover; max 9 enforced in the UI layer.
  /// [listingInput] must not include staging URLs — gallery is attached here after upload.
  Future<void> submit({
    required NewListingInput listingInput,
    required List<CoverImageUpload> orderedPhotos,
  }) async {
    if (isClosed) return;
    syncWithAuth(_readCurrentUserId());
    if (state.status == CreateListingStatus.submitting) return;
    final userId = listingInput.sellerId;
    final generation = _sessionGeneration;
    bool isCurrent() => _isCurrentSession(userId, generation);
    if (!isCurrent() || orderedPhotos.any((p) => p.sellerId != userId)) return;
    emit(
      state.copyWith(status: CreateListingStatus.submitting, failureKind: null),
    );

    List<UploadedListingImage>? stagedGallery;
    if (orderedPhotos.isNotEmpty) {
      final uploads = await _uploadForSession(orderedPhotos, isCurrent);
      if (!isCurrent()) return;
      switch (uploads) {
        case FailureResult(:final failure):
          emit(
            state.copyWith(
              status: CreateListingStatus.failure,
              failureKind: _failureKindDuringGalleryUpload(failure),
            ),
          );
          return;
        case Success(:final value):
          stagedGallery = value;
          break;
      }
    }

    final inputForRpc = stagingGalleryAttached(listingInput, stagedGallery);

    if (!isCurrent()) return;
    final result = await _createListingV2(inputForRpc);
    if (!isCurrent()) return;
    switch (result) {
      case FailureResult(:final failure):
        // Transport/parse failures do not prove rollback. Preserve images when
        // the server may already have committed the listing.
        if (_isDefiniteCreateRejection(failure) &&
            stagedGallery != null &&
            stagedGallery.isNotEmpty) {
          await _deleteForSession(stagedGallery, userId, isCurrent);
        }
        if (!isCurrent()) return;
        if (kDebugMode) {
          debugPrint(
            '[CreateListing][cubit:submit] RPC stage failure '
            'kind=${createListingFailureKindFor(failure)} '
            'failureType=${failure.runtimeType}',
          );
        }
        emit(
          state.copyWith(
            status: CreateListingStatus.failure,
            failureKind: createListingFailureKindFor(failure),
          ),
        );
      case Success(:final value):
        await _saveSubmittedDefaultsBestEffort(listingInput, isCurrent);
        if (!isCurrent()) return;
        emit(
          state.copyWith(status: CreateListingStatus.success, created: value),
        );
    }
  }

  Future<Result<List<UploadedListingImage>>> _uploadForSession(
    List<CoverImageUpload> uploads,
    bool Function() isCurrent,
  ) async {
    if (uploads.length > kMaxListingPhotos) {
      return const FailureResult(UnknownFailure('Too many images.'));
    }
    final completed = <UploadedListingImage>[];
    for (final upload in uploads) {
      if (!isCurrent()) {
        return const FailureResult(AuthFailure('Stale listing session.'));
      }
      // Singleton batches keep the repository from advancing uploads or
      // cleanup past an account change; this Cubit owns the guarded sequence.
      final result = await _uploadSequential([upload]);
      if (!isCurrent()) {
        return const FailureResult(AuthFailure('Stale listing session.'));
      }
      switch (result) {
        case Success(:final value):
          completed.addAll(value);
        case FailureResult(:final failure):
          await _deleteForSession(completed, upload.sellerId, isCurrent);
          return FailureResult(failure);
      }
    }
    return Success(completed);
  }

  Future<void> _deleteForSession(
    List<UploadedListingImage> images,
    String userId,
    bool Function() isCurrent,
  ) async {
    for (final image in images) {
      if (!isCurrent()) return;
      await _deleteStaging(images: [image], sellerId: userId);
    }
  }

  static bool _isDefiniteCreateRejection(Failure failure) {
    if (failure is! ServerFailure) return false;
    final code = failure.postgrestCode;
    return code != null &&
        (code.startsWith('22') ||
            code.startsWith('23') ||
            code == '42501' ||
            code == '28000' ||
            code == 'P0001');
  }

  Future<void> _saveSubmittedDefaultsBestEffort(
    NewListingInput input,
    bool Function() isCurrent,
  ) async {
    final save = _saveMyListingDefaults;
    if (save == null || !isCurrent()) return;
    try {
      final result = await save(
        sellerListingDefaultsFromSubmitted(
          contactPhone: input.contactPhone,
          telegramUsername: input.telegramUsername,
          whatsappEnabled: input.whatsappEnabled,
          marketRegion: input.marketRegion,
          city: input.city,
        ),
      );
      if (result is FailureResult<SellerListingDefaults> && kDebugMode) {
        debugPrint('[CreateListing][cubit:submit] defaults save failed');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[CreateListing][cubit:submit] defaults save failed');
      }
    }
  }

  static CreateListingFailureKind _failureKindDuringGalleryUpload(
    Failure failure,
  ) {
    if (failure is AuthFailure) {
      return CreateListingFailureKind.sessionExpired;
    }
    if (failure is NetworkFailure) {
      return CreateListingFailureKind.serviceUnavailable;
    }
    return CreateListingFailureKind.upload;
  }

  static NewListingInput stagingGalleryAttached(
    NewListingInput base,
    List<UploadedListingImage>? gallery,
  ) {
    if (gallery == null || gallery.isEmpty) {
      return base.copyWith(uploadedGallery: null, coverImageUrl: null);
    }
    return base.copyWith(uploadedGallery: gallery, coverImageUrl: null);
  }
}
