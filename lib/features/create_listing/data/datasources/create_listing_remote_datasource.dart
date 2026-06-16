import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../utils/create_listing_rpc_debug_log.dart';
import '../utils/create_listing_v2_vin_params.dart';
import '../../../listings/data/models/listing_model.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/new_listing_input.dart';

/// Only this class talks to Supabase for create-listing.
abstract interface class CreateListingRemoteDataSource {
  Future<ListingModel> insert(NewListingInput input);
  Future<ListingModel> insertV2(NewListingInput input);
}

String? _nullableTrim(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _clipPostgresDiagnosticDetail(Object? details, String? hint) {
  final parts = <String>[];
  final d = details?.toString().trim();
  if (d != null && d.isNotEmpty) parts.add(d);
  final h = hint?.trim();
  if (h != null && h.isNotEmpty) parts.add(h);
  if (parts.isEmpty) return null;
  var joined = parts.join(' — ');
  if (joined.length > 420) joined = '${joined.substring(0, 420)}…';
  return joined;
}

class SupabaseCreateListingRemoteDataSource
    implements CreateListingRemoteDataSource {
  SupabaseCreateListingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _rpc = 'create_listing';
  static const String _rpcV2 = 'create_listing_v2';

  @override
  Future<ListingModel> insert(NewListingInput input) async {
    try {
      final telegram = input.telegramUsername?.trim();
      final normalizedTelegram = (telegram == null || telegram.isEmpty)
          ? null
          : (telegram.startsWith('@') ? telegram.substring(1) : telegram);

      final cover = input.coverImageUrl?.trim();
      final coverParam = (cover == null || cover.isEmpty) ? null : cover;

      final dynamic data = await _supabase.client.rpc(
        _rpc,
        params: <String, dynamic>{
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
          'p_cover_image_url': coverParam,
        },
      );

      Map<String, dynamic>? row;
      if (data is Map<String, dynamic>) {
        row = data;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      }
      if (row == null) {
        throw ServerException('Unexpected response from create_listing RPC.');
      }

      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(
        e.message,
        cause: e,
        stackTrace: st,
        postgrestCode: e.code,
        diagnosticsDetails: _clipPostgresDiagnosticDetail(e.details, e.hint),
      );
    } catch (e, st) {
      throw ServerException(
        'Failed to create listing',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<ListingModel> insertV2(NewListingInput input) async {
    Map<String, dynamic>? rpcParamsSent;
    try {
      final telegram = input.telegramUsername?.trim();
      final normalizedTelegram = (telegram == null || telegram.isEmpty)
          ? null
          : (telegram.startsWith('@') ? telegram.substring(1) : telegram);

      final gallery = input.uploadedGallery;
      if (gallery != null && gallery.length > kMaxListingPhotos) {
        throw ServerException(
          'Too many images for listing_gallery (${gallery.length}).',
        );
      }

      final urls = <String>[];
      final paths = <String>[];
      if (gallery != null) {
        for (final img in gallery) {
          final u = img.publicUrl.trim();
          if (u.isEmpty) continue;
          urls.add(u);
          final rawPath = img.storagePath?.trim();
          paths.add((rawPath == null || rawPath.isEmpty) ? '' : rawPath);
        }
        if (urls.length != paths.length) {
          throw ServerException(
            'Internal gallery compaction mismatch (urls vs storage paths).',
          );
        }
      }

      final useGalleryDriveCover = urls.isNotEmpty;

      final cover = input.coverImageUrl?.trim();
      final legacyCover =
          (!useGalleryDriveCover && cover != null && cover.isNotEmpty)
          ? cover
          : null;

      final params = <String, dynamic>{
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
        'p_cover_image_url': legacyCover,
        'p_price_currency': listingCurrencyToDbString(input.priceCurrency),
      };

      if (useGalleryDriveCover) {
        params['p_image_urls'] = urls;
        params['p_storage_paths'] = paths;
      } else {
        params['p_image_urls'] = null;
        params['p_storage_paths'] = null;
      }

      params['p_body_type'] = input.bodyType?.name;
      params['p_fuel_type'] = input.fuelType?.name;
      params['p_engine_displacement_liters'] = input.engineDisplacementLiters;
      params['p_engine_power_hp'] = input.enginePowerHp;
      params['p_drivetrain'] = input.drivetrain == null
          ? null
          : listingDrivetrainToDbValue(input.drivetrain!);
      params['p_transmission_type'] = input.transmissionType == null
          ? null
          : listingTransmissionTypeToDbValue(input.transmissionType!);
      params['p_registration'] = _nullableTrim(input.registration);
      params['p_description'] = _nullableTrim(input.description);
      applyOptionalVinToCreateListingV2Params(params, input.vin);

      rpcParamsSent = params;
      final dynamic data = await _supabase.client.rpc(_rpcV2, params: params);

      Map<String, dynamic>? row;
      if (data is Map<String, dynamic>) {
        row = data;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      }
      if (row == null) {
        throw ServerException(
          'Unexpected response from create_listing_v2 RPC.',
        );
      }

      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      final sortedKeys =
          (rpcParamsSent?.keys ?? const Iterable<String>.empty())
              .map((k) => k.toString())
              .toList()
            ..sort();
      CreateListingRpcDebugLog.logCreateListingV2RpcFailure(
        exception: e,
        sortedParamKeys: sortedKeys,
        vinProvided: input.vin != null && input.vin!.trim().isNotEmpty,
        vinLength: input.vin?.length,
      );
      throw ServerException(
        e.message,
        cause: e,
        stackTrace: st,
        postgrestCode: e.code,
        diagnosticsDetails: _clipPostgresDiagnosticDetail(e.details, e.hint),
      );
    } catch (e, st) {
      throw ServerException(
        'Failed to create listing',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
