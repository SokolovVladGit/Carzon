import 'package:equatable/equatable.dart';

import '../../domain/entities/manual_smart_fill_result.dart';

enum ManualSmartFillStatus {
  idle,
  loading,
  filled,
  needsClarification,
  noData,
  failure,
}

class ManualSmartFillState extends Equatable {
  const ManualSmartFillState({
    this.status = ManualSmartFillStatus.idle,
    this.query,
    this.result,
    this.applyRevision = 0,
    this.answered = false,
    this.clarificationDismissed = false,
  });

  final ManualSmartFillStatus status;
  final ManualSmartFillQuery? query;
  final ManualSmartFillResult? result;
  final int applyRevision;
  final bool answered;
  final bool clarificationDismissed;

  const ManualSmartFillState.idle() : this();

  bool get showClarification =>
      status == ManualSmartFillStatus.needsClarification &&
      !answered &&
      !clarificationDismissed &&
      (result?.hasSupportedClarification ?? false);

  ManualSmartFillState copyWith({
    ManualSmartFillStatus? status,
    ManualSmartFillQuery? query,
    ManualSmartFillResult? result,
    int? applyRevision,
    bool? answered,
    bool? clarificationDismissed,
    bool clearQuery = false,
    bool clearResult = false,
  }) {
    return ManualSmartFillState(
      status: status ?? this.status,
      query: clearQuery ? null : (query ?? this.query),
      result: clearResult ? null : (result ?? this.result),
      applyRevision: applyRevision ?? this.applyRevision,
      answered: answered ?? this.answered,
      clarificationDismissed:
          clarificationDismissed ?? this.clarificationDismissed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    result,
    applyRevision,
    answered,
    clarificationDismissed,
  ];
}
