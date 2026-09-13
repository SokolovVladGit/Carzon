import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
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
    List<ManualSmartFillRefinementAnswer> answers = const [],
    List<ManualSmartFillRefinementKind> skippedKinds = const [],
  });
}

class SupabaseManualSmartFillRemoteDataSource
    implements ManualSmartFillRemoteDataSource {
  SupabaseManualSmartFillRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const rpcName = 'resolve_vehicle_by_identity_v2';

  @override
  Future<ManualSmartFillResult> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    List<ManualSmartFillRefinementAnswer> answers = const [],
    List<ManualSmartFillRefinementKind> skippedKinds = const [],
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        rpcName,
        params: <String, dynamic>{
          'p_make': make,
          'p_model': model,
          'p_year': year,
          'p_refinement': manualSmartFillRefinementRpcJson(
            answers: answers,
            skippedKinds: skippedKinds,
          ),
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
  final identityMap = identityRaw is Map
      ? Map<String, dynamic>.from(identityRaw)
      : <String, dynamic>{};
  final makeKey = _optionalString(identityMap['makeKey']);
  final modelKey = _optionalString(identityMap['modelKey']);
  final year = _optionalYear(identityMap['year']);
  final allowMissingIdentity =
      resolution == ManualSmartFillResolution.noData ||
      resolution == ManualSmartFillResolution.invalidRefinement;
  if (!allowMissingIdentity &&
      (makeKey == null || modelKey == null || year == null)) {
    throw ManualSmartFillServerException(
      'Manual smart fill payload malformed.',
    );
  }

  final nextRefinement = _parseNextRefinement(map['nextRefinement']);
  return ManualSmartFillResult(
    resolution: resolution,
    identity: ManualSmartFillIdentity(
      makeKey: makeKey ?? '',
      modelKey: modelKey ?? '',
      year: year ?? 1900,
      yearTolerance: _optionalInt(identityMap['yearTolerance']),
      yearEvidence: _optionalString(identityMap['yearEvidence']),
    ),
    consensus: _parseConsensus(map['consensusSpecs']),
    clarification:
        _parseClarification(map['clarification']) ??
        _clarificationFromNext(nextRefinement),
    nextRefinement: nextRefinement,
    refinementState: _parseRefinementState(map['refinementState']),
    candidateCount: _optionalInt(map['candidateCount']) ?? 0,
    confidence: _optionalString(map['confidence']),
    mappingVersion: _optionalString(map['mappingVersion']),
  );
}

ManualSmartFillResolution? _parseResolution(Object? raw) {
  return switch (raw) {
    'ok' => ManualSmartFillResolution.ok,
    'noData' => ManualSmartFillResolution.noData,
    'invalidRefinement' => ManualSmartFillResolution.invalidRefinement,
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

ManualSmartFillClarification? _clarificationFromNext(
  ManualSmartFillNextRefinement? next,
) {
  if (next == null || !next.isUsable) return null;
  if (next.kind == ManualSmartFillRefinementKind.engine) return null;
  final options = [
    for (final option in next.options)
      if (option.canonicalValue != null)
        ManualSmartFillClarificationOption(
          value: option.canonicalValue!,
          candidateCount: option.candidateCount,
        ),
  ];
  if (options.isEmpty) return null;
  return ManualSmartFillClarification(
    attribute: next.kind.wireValue,
    options: options,
  );
}

ManualSmartFillNextRefinement? _parseNextRefinement(Object? raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final kind = parseManualSmartFillRefinementKind(_optionalString(map['kind']));
  if (kind == null) return null;
  final optionsRaw = map['options'];
  if (optionsRaw is! List) return null;
  final options = <ManualSmartFillRefinementOption>[
    for (final item in optionsRaw)
      if (item is Map)
        if (_parseOption(kind, Map<String, dynamic>.from(item)) != null)
          _parseOption(kind, Map<String, dynamic>.from(item))!,
  ];
  if (options.isEmpty) return null;
  return ManualSmartFillNextRefinement(
    kind: kind,
    allowUnknown: map['allowUnknown'] != false,
    options: options,
  );
}

ManualSmartFillRefinementOption? _parseOption(
  ManualSmartFillRefinementKind kind,
  Map<String, dynamic> map,
) {
  final id = _optionalString(map['id']);
  if (id == null) return null;
  final count = _optionalInt(map['candidateCount']) ?? 0;
  switch (kind) {
    case ManualSmartFillRefinementKind.body:
      final bodyType = _optionalString(map['bodyType']);
      if (bodyType == null) return null;
      return ManualSmartFillRefinementOption(
        id: id,
        kind: kind,
        candidateCount: count,
        bodyType: bodyType,
      );
    case ManualSmartFillRefinementKind.fuel:
      final fuelType = _optionalString(map['fuelType']);
      if (fuelType == null) return null;
      return ManualSmartFillRefinementOption(
        id: id,
        kind: kind,
        candidateCount: count,
        fuelType: fuelType,
      );
    case ManualSmartFillRefinementKind.engine:
      final fuelType = _optionalString(map['fuelType']);
      final liters = _optionalDouble(map['engineDisplacementLiters']);
      final hp = _optionalInt(map['enginePowerHp']);
      if (fuelType == null || liters == null || hp == null) return null;
      return ManualSmartFillRefinementOption(
        id: id,
        kind: kind,
        candidateCount: count,
        fuelType: fuelType,
        engineDisplacementLiters: liters,
        enginePowerHp: hp,
      );
    case ManualSmartFillRefinementKind.transmission:
      final transmissionType = _optionalString(map['transmissionType']);
      if (transmissionType == null) return null;
      return ManualSmartFillRefinementOption(
        id: id,
        kind: kind,
        candidateCount: count,
        transmissionType: transmissionType,
      );
  }
}

ManualSmartFillRefinementState? _parseRefinementState(Object? raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final answersRaw = map['answers'];
  final skippedRaw = map['skippedKinds'];
  final answers = <ManualSmartFillRefinementAnswer>[
    if (answersRaw is List)
      for (final item in answersRaw)
        if (item is Map)
          if (_parseAnswer(Map<String, dynamic>.from(item)) != null)
            _parseAnswer(Map<String, dynamic>.from(item))!,
  ];
  final skipped = <ManualSmartFillRefinementKind>[
    if (skippedRaw is List)
      for (final item in skippedRaw)
        if (parseManualSmartFillRefinementKind(item is String ? item : null) !=
            null)
          parseManualSmartFillRefinementKind(item as String)!,
  ];
  return ManualSmartFillRefinementState(
    answers: answers,
    skippedKinds: skipped,
    decisionsUsed:
        _optionalInt(map['decisionsUsed']) ?? answers.length + skipped.length,
    maxDecisions: _optionalInt(map['maxDecisions']) ?? 3,
  );
}

ManualSmartFillRefinementAnswer? _parseAnswer(Map<String, dynamic> map) {
  final kind = parseManualSmartFillRefinementKind(_optionalString(map['kind']));
  final optionId = _optionalString(map['optionId']);
  if (kind == null || optionId == null) return null;
  return ManualSmartFillRefinementAnswer(kind: kind, optionId: optionId);
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
