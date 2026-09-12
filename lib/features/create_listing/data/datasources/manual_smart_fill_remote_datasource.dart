import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/manual_smart_fill_result.dart';

class ManualSmartFillServerException extends ServerException {
  ManualSmartFillServerException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

abstract interface class ManualSmartFillRemoteDataSource {
  Future<ManualSmartFillResult> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    ManualSmartFillAnswer? answer,
  });
}

class SupabaseManualSmartFillRemoteDataSource
    implements ManualSmartFillRemoteDataSource {
  SupabaseManualSmartFillRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const rpcName = 'resolve_vehicle_by_identity';

  @override
  Future<ManualSmartFillResult> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    ManualSmartFillAnswer? answer,
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        rpcName,
        params: <String, dynamic>{
          'p_make': make,
          'p_model': model,
          'p_year': year,
          'p_answer': answer?.toRpcJson(),
        },
      );
      return parseManualSmartFillResponse(data);
    } on sb.PostgrestException catch (e, st) {
      throw ManualSmartFillServerException(e.message, cause: e, stackTrace: st);
    } on sb.AuthException catch (e, st) {
      throw ManualSmartFillServerException(
        'Manual smart fill unauthorized.',
        cause: e,
        stackTrace: st,
      );
    } on ManualSmartFillServerException {
      rethrow;
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ManualSmartFillServerException(
        'Manual smart fill failed.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

ManualSmartFillResult parseManualSmartFillResponse(Object? data) {
  if (data is! Map) {
    throw ManualSmartFillServerException(
      'Manual smart fill payload malformed.',
    );
  }
  final map = Map<String, dynamic>.from(data);
  final resolution = _parseResolution(map['status']);
  if (resolution == null) {
    throw ManualSmartFillServerException(
      'Manual smart fill payload malformed.',
    );
  }

  final identityRaw = map['identity'];
  if (identityRaw is! Map) {
    throw ManualSmartFillServerException(
      'Manual smart fill payload malformed.',
    );
  }
  final identityMap = Map<String, dynamic>.from(identityRaw);
  final makeKey = _optionalString(identityMap['makeKey']);
  final modelKey = _optionalString(identityMap['modelKey']);
  final year = _optionalYear(identityMap['year']);
  if (makeKey == null || modelKey == null || year == null) {
    throw ManualSmartFillServerException(
      'Manual smart fill payload malformed.',
    );
  }

  return ManualSmartFillResult(
    resolution: resolution,
    identity: ManualSmartFillIdentity(
      makeKey: makeKey,
      modelKey: modelKey,
      year: year,
      yearTolerance: _optionalInt(identityMap['yearTolerance']),
      yearEvidence: _optionalString(identityMap['yearEvidence']),
    ),
    consensus: _parseConsensus(map['consensusSpecs']),
    clarification: _parseClarification(map['clarification']),
    candidateCount: _optionalInt(map['candidateCount']) ?? 0,
    confidence: _optionalString(map['confidence']),
    mappingVersion: _optionalString(map['mappingVersion']),
  );
}

ManualSmartFillResolution? _parseResolution(Object? raw) {
  return switch (raw) {
    'ok' => ManualSmartFillResolution.ok,
    'noData' => ManualSmartFillResolution.noData,
    _ => null,
  };
}

ManualSmartFillConsensusSpecs _parseConsensus(Object? raw) {
  if (raw is! Map) return const ManualSmartFillConsensusSpecs();
  final map = Map<String, dynamic>.from(raw);
  return ManualSmartFillConsensusSpecs(
    bodyType: _optionalString(map['bodyType']),
    fuelType: _optionalString(map['fuelType']),
    engineDisplacementLiters: _optionalDouble(map['engineDisplacementLiters']),
    enginePowerHp: _optionalInt(map['enginePowerHp']),
    transmissionType: _optionalString(map['transmissionType']),
    drivetrain: _optionalString(map['drivetrain']),
  );
}

ManualSmartFillClarification? _parseClarification(Object? raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final attribute = _optionalString(map['attribute']);
  if (attribute == null) return null;
  final optionsRaw = map['options'];
  if (optionsRaw is! List) return null;
  final options = <ManualSmartFillClarificationOption>[
    for (final item in optionsRaw)
      if (item is Map)
        if (_optionalString(Map<String, dynamic>.from(item)['value']) != null)
          ManualSmartFillClarificationOption(
            value: _optionalString(Map<String, dynamic>.from(item)['value'])!,
            candidateCount: _optionalInt(
              Map<String, dynamic>.from(item)['candidateCount'],
            ),
          ),
  ];
  if (options.isEmpty) return null;
  return ManualSmartFillClarification(attribute: attribute, options: options);
}

String? _optionalString(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

int? _optionalYear(Object? raw) {
  final n = _optionalInt(raw);
  if (n == null || n < 1900 || n > 2100) return null;
  return n;
}

int? _optionalInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw.isFinite) return raw.toInt();
  return null;
}

double? _optionalDouble(Object? raw) {
  if (raw is num && raw.isFinite) return raw.toDouble();
  return null;
}
