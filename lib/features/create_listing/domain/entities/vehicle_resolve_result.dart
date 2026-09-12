import 'package:equatable/equatable.dart';

enum VehicleResolveResolution { resolved, partial, noData }

class VehicleResolveSuggestion extends Equatable {
  const VehicleResolveSuggestion({
    this.make,
    this.model,
    this.year,
    this.trim,
    this.series,
    this.bodyType,
    this.fuelType,
    this.engine,
    this.transmission,
    this.driveType,
    this.displacement,
    this.cylinders,
  });

  final String? make;
  final String? model;
  final int? year;
  final String? trim;
  final String? series;
  final String? bodyType;
  final String? fuelType;
  final String? engine;
  final String? transmission;
  final String? driveType;
  final String? displacement;
  final String? cylinders;

  bool get hasCoreIdentity =>
      (make?.trim().isNotEmpty ?? false) &&
      (model?.trim().isNotEmpty ?? false) &&
      year != null;

  String? get variantHint {
    final t = trim?.trim();
    if (t != null && t.isNotEmpty) return t;
    final s = series?.trim();
    if (s != null && s.isNotEmpty) return s;
    return null;
  }

  String get identityHeadline {
    final parts = [
      if (make?.trim().isNotEmpty ?? false) make!.trim(),
      if (model?.trim().isNotEmpty ?? false) model!.trim(),
    ];
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
    make,
    model,
    year,
    trim,
    series,
    bodyType,
    fuelType,
    engine,
    transmission,
    driveType,
    displacement,
    cylinders,
  ];
}

class VehicleResolveResult extends Equatable {
  const VehicleResolveResult({
    required this.resolution,
    required this.vehicle,
    required this.completeness,
    required this.warnings,
  });

  final VehicleResolveResolution resolution;
  final VehicleResolveSuggestion vehicle;
  final double completeness;
  final List<String> warnings;

  @override
  List<Object?> get props => [resolution, vehicle, completeness, warnings];
}

class ConfirmedVehicleIdentity extends Equatable {
  const ConfirmedVehicleIdentity({
    required this.make,
    required this.model,
    required this.year,
    this.variant,
  });

  final String make;
  final String model;
  final int year;
  final String? variant;

  @override
  List<Object?> get props => [make, model, year, variant];
}

String? variantSuggestionFrom({String? trim, String? series}) {
  return VehicleResolveSuggestion(trim: trim, series: series).variantHint;
}
