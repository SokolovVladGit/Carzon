import 'package:equatable/equatable.dart';

enum ManualSmartFillRefinementKind { body, fuel, engine, transmission }

ManualSmartFillRefinementKind? parseManualSmartFillRefinementKind(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'body' => ManualSmartFillRefinementKind.body,
    'fuel' => ManualSmartFillRefinementKind.fuel,
    'engine' => ManualSmartFillRefinementKind.engine,
    'transmission' => ManualSmartFillRefinementKind.transmission,
    _ => null,
  };
}

extension ManualSmartFillRefinementKindX on ManualSmartFillRefinementKind {
  String get wireValue => switch (this) {
    ManualSmartFillRefinementKind.body => 'body',
    ManualSmartFillRefinementKind.fuel => 'fuel',
    ManualSmartFillRefinementKind.engine => 'engine',
    ManualSmartFillRefinementKind.transmission => 'transmission',
  };
}

class ManualSmartFillRefinementAnswer extends Equatable {
  const ManualSmartFillRefinementAnswer({
    required this.kind,
    required this.optionId,
  });

  final ManualSmartFillRefinementKind kind;
  final String optionId;

  Map<String, String> toRpcJson() => {
    'kind': kind.wireValue,
    'optionId': optionId,
  };

  @override
  List<Object?> get props => [kind, optionId];
}

class ManualSmartFillRefinementOption extends Equatable {
  const ManualSmartFillRefinementOption({
    required this.id,
    required this.kind,
    required this.candidateCount,
    this.bodyType,
    this.fuelType,
    this.engineDisplacementLiters,
    this.enginePowerHp,
    this.transmissionType,
  });

  final String id;
  final ManualSmartFillRefinementKind kind;
  final int candidateCount;
  final String? bodyType;
  final String? fuelType;
  final double? engineDisplacementLiters;
  final int? enginePowerHp;
  final String? transmissionType;

  String? get canonicalValue => switch (kind) {
    ManualSmartFillRefinementKind.body => bodyType,
    ManualSmartFillRefinementKind.fuel => fuelType,
    ManualSmartFillRefinementKind.transmission => transmissionType,
    ManualSmartFillRefinementKind.engine => null,
  };

  @override
  List<Object?> get props => [
    id,
    kind,
    candidateCount,
    bodyType,
    fuelType,
    engineDisplacementLiters,
    enginePowerHp,
    transmissionType,
  ];
}

class ManualSmartFillNextRefinement extends Equatable {
  const ManualSmartFillNextRefinement({
    required this.kind,
    required this.options,
    this.allowUnknown = true,
  });

  final ManualSmartFillRefinementKind kind;
  final List<ManualSmartFillRefinementOption> options;
  final bool allowUnknown;

  bool get isUsable => options.isNotEmpty;

  @override
  List<Object?> get props => [kind, options, allowUnknown];
}

class ManualSmartFillRefinementState extends Equatable {
  const ManualSmartFillRefinementState({
    this.answers = const [],
    this.skippedKinds = const [],
    this.decisionsUsed = 0,
    this.maxDecisions = 3,
  });

  final List<ManualSmartFillRefinementAnswer> answers;
  final List<ManualSmartFillRefinementKind> skippedKinds;
  final int decisionsUsed;
  final int maxDecisions;

  @override
  List<Object?> get props => [
    answers,
    skippedKinds,
    decisionsUsed,
    maxDecisions,
  ];
}

Map<String, Object> manualSmartFillRefinementRpcJson({
  List<ManualSmartFillRefinementAnswer> answers = const [],
  List<ManualSmartFillRefinementKind> skippedKinds = const [],
}) {
  return {
    'answers': [for (final answer in answers) answer.toRpcJson()],
    'skippedKinds': [for (final kind in skippedKinds) kind.wireValue],
  };
}
