import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/data/models/listing_model.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/entities/owner_listing_vin_lookup_result.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';

ListingModel _parseListingMutationRpcResponse(
  dynamic data,
  String rpcNameForError,
) {
  Map<String, dynamic>? row;
  if (data is Map<String, dynamic>) {
    row = data;
  } else if (data is List && data.isNotEmpty && data.first is Map) {
    row = Map<String, dynamic>.from(data.first as Map);
  }
  if (row == null) {
    throw ServerException('Unexpected response from $rpcNameForError RPC.');
  }
  return ListingModel.fromJson(row);
}

String? _nullableTrimListingField(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Only this class talks to Supabase for edit-listing.
abstract interface class EditListingRemoteDataSource {
  /// Calls `public.update_listing_details`.
  Future<ListingModel> updateDetails(EditListingInput input);

  /// Calls `public.update_listing_details_v2` (includes currency).
  Future<ListingModel> updateDetailsV2(EditListingInput input);

  /// Calls `public.replace_listing_images`.
  ///
  /// [storagePaths]: when non-null must match [imagePublicUrls] length
  /// (mirrors Create v2 compaction; blanks become null on the server via RPC).
  Future<ListingModel> replaceListingImages({
    required String listingId,
    required List<String> imagePublicUrls,
    List<String?>? storagePaths,
  });

  Future<ListingModel> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  });

  /// Calls `get_my_listing_vehicle_identity` (owner-only).
  Future<OwnerListingVinLookupResult> fetchOwnerListingVin(String listingId);

  /// Calls `get_my_listing_vin_report_status` (owner-only).
  Future<OwnerListingVinReportLookupResult> fetchOwnerListingVinReportStatus(
    String listingId,
  );

  /// Calls `get_my_listing_vin_source_results` (owner-only).
  Future<OwnerListingVinSourceResultsLookupResult>
  fetchOwnerListingVinSourceResults(String listingId);
}

class SupabaseEditListingRemoteDataSource
    implements EditListingRemoteDataSource {
  SupabaseEditListingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _rpcLegacy = 'update_listing_details';
  static const String _rpcV2 = 'update_listing_details_v2';
  static const String _rpcCover = 'update_listing_cover_image';
  static const String _rpcReplaceImages = 'replace_listing_images';

  Future<ListingModel> _rpcListingRow(
    Future<dynamic> call,
    String rpcName,
  ) async {
    try {
      final dynamic data = await call;
      return _parseListingMutationRpcResponse(data, rpcName);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException('Failed $rpcName', cause: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _detailsParams(
    EditListingInput input, {
    required bool currency,
  }) {
    final telegram = input.telegramUsername?.trim();
    final normalizedTelegram = (telegram == null || telegram.isEmpty)
        ? null
        : (telegram.startsWith('@') ? telegram.substring(1) : telegram);

    final base = <String, dynamic>{
      'p_listing_id': input.listingId,
      'p_title': input.title.trim(),
      'p_make': input.make.trim(),
      'p_model': input.model.trim(),
      'p_year': input.year,
      'p_price_eur': input.priceEur,
      'p_mileage_km': input.mileageKm,
      'p_type': input.type.name,
      'p_city': input.city.trim(),
      'p_market_region': input.marketRegion.name,
      'p_contact_phone': input.contactPhone.trim(),
      'p_telegram_username': normalizedTelegram,
      'p_whatsapp_enabled': input.whatsappEnabled,
    };

    if (currency) {
      base['p_price_currency'] = listingCurrencyToDbString(input.priceCurrency);
    }
    return base;
  }

  @override
  Future<ListingModel> updateDetails(EditListingInput input) {
    return _rpcListingRow(
      _supabase.client.rpc(
        _rpcLegacy,
        params: _detailsParams(input, currency: false),
      ),
      _rpcLegacy,
    );
  }

  @override
  Future<ListingModel> updateDetailsV2(EditListingInput input) {
    final params = _detailsParams(input, currency: true)
      ..['p_body_type'] = input.bodyType?.name
      ..['p_fuel_type'] = input.fuelType?.name
      ..['p_engine_displacement_liters'] = input.engineDisplacementLiters
      ..['p_engine_power_hp'] = input.enginePowerHp
      ..['p_drivetrain'] = input.drivetrain == null
          ? null
          : listingDrivetrainToDbValue(input.drivetrain!)
      ..['p_registration'] = _nullableTrimListingField(input.registration)
      ..['p_description'] = _nullableTrimListingField(input.description);
    if (input.submitVinParameterToRpc) {
      params['p_vin'] = input.vinParameter;
    }
    return _rpcListingRow(_supabase.client.rpc(_rpcV2, params: params), _rpcV2);
  }

  static const String _rpcVinIdentity = 'get_my_listing_vehicle_identity';
  static const String _rpcVinReportStatus = 'get_my_listing_vin_report_status';
  static const String _rpcVinSourceResults =
      'get_my_listing_vin_source_results';

  @override
  Future<OwnerListingVinLookupResult> fetchOwnerListingVin(
    String listingId,
  ) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcVinIdentity,
        params: <String, dynamic>{'p_listing_id': listingId},
      );

      Map<String, dynamic>? row;
      if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      } else if (data is Map<String, dynamic>) {
        row = data;
      }
      if (row == null) {
        return const OwnerListingVinLookupResult(fetchFailed: true);
      }

      final rawVin = row['vin_normalized'];
      String? normalized;
      if (rawVin is String && rawVin.trim().isNotEmpty) {
        normalized = rawVin.trim();
      }
      return OwnerListingVinLookupResult(normalizedVin: normalized);
    } on sb.PostgrestException {
      return const OwnerListingVinLookupResult(fetchFailed: true);
    } catch (_) {
      return const OwnerListingVinLookupResult(fetchFailed: true);
    }
  }

  @override
  Future<OwnerListingVinReportLookupResult> fetchOwnerListingVinReportStatus(
    String listingId,
  ) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcVinReportStatus,
        params: <String, dynamic>{'p_listing_id': listingId},
      );

      Map<String, dynamic>? row;
      if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      } else if (data is Map<String, dynamic>) {
        row = data;
      }
      if (row == null) {
        return const OwnerListingVinReportLookupResult(fetchFailed: true);
      }

      final parsed = OwnerListingVinReportStatus.tryParse(row);
      if (parsed == null) {
        return const OwnerListingVinReportLookupResult(fetchFailed: true);
      }
      return OwnerListingVinReportLookupResult(status: parsed);
    } on sb.PostgrestException {
      return const OwnerListingVinReportLookupResult(fetchFailed: true);
    } catch (_) {
      return const OwnerListingVinReportLookupResult(fetchFailed: true);
    }
  }

  @override
  Future<OwnerListingVinSourceResultsLookupResult>
  fetchOwnerListingVinSourceResults(String listingId) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcVinSourceResults,
        params: <String, dynamic>{'p_listing_id': listingId},
      );

      final rows = <OwnerListingVinSourceResult>[];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final row = Map<String, dynamic>.from(item);
          final parsed = OwnerListingVinSourceResult.tryParse(row);
          if (parsed != null) rows.add(parsed);
        }
      }
      return OwnerListingVinSourceResultsLookupResult(results: rows);
    } on sb.PostgrestException {
      return const OwnerListingVinSourceResultsLookupResult(fetchFailed: true);
    } catch (_) {
      return const OwnerListingVinSourceResultsLookupResult(fetchFailed: true);
    }
  }

  @override
  Future<ListingModel> replaceListingImages({
    required String listingId,
    required List<String> imagePublicUrls,
    List<String?>? storagePaths,
  }) {
    if (storagePaths != null && storagePaths.length != imagePublicUrls.length) {
      throw ServerException(
        'storagePaths length (${storagePaths.length}) must equal '
        'imagePublicUrls (${imagePublicUrls.length}).',
      );
    }

    final params = <String, dynamic>{
      'p_listing_id': listingId,
      'p_image_urls': List<String>.from(imagePublicUrls),
      'p_storage_paths': storagePaths == null
          ? null
          : List<String?>.from(storagePaths),
    };

    return _rpcListingRow(
      _supabase.client.rpc(_rpcReplaceImages, params: params),
      _rpcReplaceImages,
    );
  }

  @override
  Future<ListingModel> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcCover,
        params: <String, dynamic>{
          'p_listing_id': listingId,
          'p_cover_image_url': coverImageUrl,
        },
      );
      return _parseListingMutationRpcResponse(data, _rpcCover);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to update cover image for listing $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
