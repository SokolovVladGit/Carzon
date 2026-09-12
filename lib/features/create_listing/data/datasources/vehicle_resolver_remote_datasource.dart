import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

class VehicleResolveServerException extends ServerException {
  VehicleResolveServerException(
    super.message, {
    required this.kind,
    super.cause,
    super.stackTrace,
  });

  final VehicleResolveFailureKind kind;
}

abstract interface class VehicleResolverRemoteDataSource {
  Future<VehicleResolveResult> resolveVehicle({required String vin});
}

class SupabaseVehicleResolverRemoteDataSource
    implements VehicleResolverRemoteDataSource {
  SupabaseVehicleResolverRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const _functionName = 'resolve-vehicle';

  @override
  Future<VehicleResolveResult> resolveVehicle({required String vin}) async {
    try {
      final response = await _supabase.client.functions.invoke(
        _functionName,
        body: {'vin': vin},
      );
      return parseVehicleResolveResponse(
        status: response.status,
        data: response.data,
      );
    } on sb.FunctionException catch (e, st) {
      throw VehicleResolveServerException(
        'Vehicle resolve failed.',
        kind: vehicleResolveFailureKindForStatus(
          e.status,
          errorCode: _errorCodeFromDetails(e.details),
        ),
        cause: e,
        stackTrace: st,
      );
    } on sb.AuthException catch (e, st) {
      throw VehicleResolveServerException(
        'Vehicle resolve unauthorized.',
        kind: VehicleResolveFailureKind.unauthorized,
        cause: e,
        stackTrace: st,
      );
    } on VehicleResolveServerException {
      rethrow;
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw VehicleResolveServerException(
        'Vehicle resolve failed.',
        kind: VehicleResolveFailureKind.internalError,
        cause: e,
        stackTrace: st,
      );
    }
  }
}

String? _errorCodeFromDetails(Object? details) {
  if (details is Map) {
    final error = details['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();
  }
  return null;
}

VehicleResolveFailureKind vehicleResolveFailureKindForStatus(
  int? status, {
  String? errorCode,
}) {
  switch (errorCode) {
    case 'invalid_vin':
      return VehicleResolveFailureKind.invalidVin;
    case 'unauthorized':
      return VehicleResolveFailureKind.unauthorized;
    case 'upstream_timeout':
      return VehicleResolveFailureKind.upstreamTimeout;
    case 'upstream_unavailable':
      return VehicleResolveFailureKind.upstreamUnavailable;
    case 'invalid_request':
    case 'method_not_allowed':
      return VehicleResolveFailureKind.invalidRequest;
    case 'internal_error':
      return VehicleResolveFailureKind.internalError;
  }
  if (status == 401) return VehicleResolveFailureKind.unauthorized;
  if (status == 504) return VehicleResolveFailureKind.upstreamTimeout;
  if (status == 502) return VehicleResolveFailureKind.upstreamUnavailable;
  if (status == 400) return VehicleResolveFailureKind.invalidRequest;
  return VehicleResolveFailureKind.internalError;
}

VehicleResolveResult parseVehicleResolveResponse({
  required int status,
  required Object? data,
}) {
  if (status < 200 || status >= 300) {
    throw VehicleResolveServerException(
      'Vehicle resolve failed.',
      kind: vehicleResolveFailureKindForStatus(
        status,
        errorCode: _errorCodeFromDetails(data),
      ),
    );
  }
  if (data is! Map) {
    throw VehicleResolveServerException(
      'Vehicle resolve payload malformed.',
      kind: VehicleResolveFailureKind.internalError,
    );
  }
  final map = Map<String, dynamic>.from(data);
  if (map['ok'] != true) {
    throw VehicleResolveServerException(
      'Vehicle resolve failed.',
      kind: vehicleResolveFailureKindForStatus(
        status,
        errorCode: _errorCodeFromDetails(map),
      ),
    );
  }

  final resolution = _parseResolution(map['resolution']);
  if (resolution == null) {
    throw VehicleResolveServerException(
      'Vehicle resolve payload malformed.',
      kind: VehicleResolveFailureKind.internalError,
    );
  }

  final vehicleRaw = map['vehicle'];
  if (vehicleRaw is! Map) {
    throw VehicleResolveServerException(
      'Vehicle resolve payload malformed.',
      kind: VehicleResolveFailureKind.internalError,
    );
  }
  final vehicleMap = Map<String, dynamic>.from(vehicleRaw);

  return VehicleResolveResult(
    resolution: resolution,
    vehicle: VehicleResolveSuggestion(
      make: _optionalString(vehicleMap['make']),
      model: _optionalString(vehicleMap['model']),
      year: _optionalYear(vehicleMap['year']),
      trim: _optionalString(vehicleMap['trim']),
      series: _optionalString(vehicleMap['series']),
      bodyType: _optionalString(vehicleMap['bodyType']),
      fuelType: _optionalString(vehicleMap['fuelType']),
      engine: _optionalString(vehicleMap['engine']),
      transmission: _optionalString(vehicleMap['transmission']),
      driveType: _optionalString(vehicleMap['driveType']),
      displacement: _optionalString(vehicleMap['displacement']),
      cylinders: _optionalString(vehicleMap['cylinders']),
    ),
    completeness: _optionalCompleteness(map['completeness']),
    warnings: _optionalWarnings(map['warnings']),
  );
}

VehicleResolveResolution? _parseResolution(Object? raw) {
  return switch (raw) {
    'resolved' => VehicleResolveResolution.resolved,
    'partial' => VehicleResolveResolution.partial,
    'no_data' => VehicleResolveResolution.noData,
    _ => null,
  };
}

String? _optionalString(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t.isEmpty ? null : t;
}

int? _optionalYear(Object? raw) {
  if (raw is int && raw >= 1900 && raw <= 2100) return raw;
  if (raw is num) {
    final n = raw.toInt();
    if (n >= 1900 && n <= 2100) return n;
  }
  return null;
}

double _optionalCompleteness(Object? raw) {
  if (raw is num && raw.isFinite) {
    final n = raw.toDouble();
    if (n < 0) return 0;
    if (n > 1) return 1;
    return n;
  }
  return 0;
}

List<String> _optionalWarnings(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
