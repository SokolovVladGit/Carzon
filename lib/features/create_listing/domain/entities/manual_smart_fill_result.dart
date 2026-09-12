import 'package:equatable/equatable.dart';

enum ManualSmartFillResolution { ok, noData }

class ManualSmartFillIdentity extends Equatable {
  const ManualSmartFillIdentity({
    required this.makeKey,
    required this.modelKey,
    required this.year,
    this.yearTolerance,
    this.yearEvidence,
  });

  final String makeKey;
  final String modelKey;
  final int year;
  final int? yearTolerance;
  final String? yearEvidence;

  @override
  List<Object?> get props => [
    makeKey,
    modelKey,
    year,
    yearTolerance,
    yearEvidence,
  ];
}

class ManualSmartFillConsensusSpecs extends Equatable {
  const ManualSmartFillConsensusSpecs({
    this.bodyType,
    this.fuelType,
    this.engineDisplacementLiters,
    this.enginePowerHp,
    this.transmissionType,
    this.drivetrain,
  });

  final String? bodyType;
  final String? fuelType;
  final double? engineDisplacementLiters;
  final int? enginePowerHp;
  final String? transmissionType;
  final String? drivetrain;

  bool get hasAnyFillable =>
      (bodyType?.trim().isNotEmpty ?? false) ||
      (fuelType?.trim().isNotEmpty ?? false) ||
      engineDisplacementLiters != null ||
      enginePowerHp != null ||
      (transmissionType?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
    bodyType,
    fuelType,
    engineDisplacementLiters,
    enginePowerHp,
    transmissionType,
    drivetrain,
  ];
}

class ManualSmartFillClarificationOption extends Equatable {
  const ManualSmartFillClarificationOption({
    required this.value,
    this.candidateCount,
  });

  final String value;
  final int? candidateCount;

  @override
  List<Object?> get props => [value, candidateCount];
}

class ManualSmartFillClarification extends Equatable {
  const ManualSmartFillClarification({
    required this.attribute,
    required this.options,
  });

  final String attribute;
  final List<ManualSmartFillClarificationOption> options;

  bool get isSupported =>
      attribute == 'body' ||
      attribute == 'fuel' ||
      attribute == 'transmission';

  @override
  List<Object?> get props => [attribute, options];
}

class ManualSmartFillQuery extends Equatable {
  const ManualSmartFillQuery({
    required this.make,
    required this.model,
    required this.year,
  });

  final String make;
  final String model;
  final int year;

  @override
  List<Object?> get props => [make, model, year];
}

class ManualSmartFillResult extends Equatable {
  const ManualSmartFillResult({
    required this.resolution,
    required this.identity,
    required this.consensus,
    this.clarification,
    this.candidateCount = 0,
    this.confidence,
    this.mappingVersion,
  });

  final ManualSmartFillResolution resolution;
  final ManualSmartFillIdentity identity;
  final ManualSmartFillConsensusSpecs consensus;
  final ManualSmartFillClarification? clarification;
  final int candidateCount;
  final String? confidence;
  final String? mappingVersion;

  bool get hasSupportedClarification =>
      clarification != null &&
      clarification!.isSupported &&
      clarification!.options.isNotEmpty;

  @override
  List<Object?> get props => [
    resolution,
    identity,
    consensus,
    clarification,
    candidateCount,
    confidence,
    mappingVersion,
  ];
}

class ManualSmartFillAnswer extends Equatable {
  const ManualSmartFillAnswer({required this.attribute, required this.value});

  final String attribute;
  final String value;

  Map<String, String> toRpcJson() => {'attribute': attribute, 'value': value};

  @override
  List<Object?> get props => [attribute, value];
}
