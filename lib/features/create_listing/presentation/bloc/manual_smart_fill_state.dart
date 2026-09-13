import 'package:equatable/equatable.dart';

import '../../domain/entities/manual_smart_fill_refinement.dart';
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
    this.answers = const [],
    this.skippedKinds = const [],
    this.answered = false,
    this.clarificationDismissed = false,
    this.cancelledByManualOverride = false,
  });

  final ManualSmartFillStatus status;
  final ManualSmartFillQuery? query;
  final ManualSmartFillResult? result;
  final int applyRevision;
  final List<ManualSmartFillRefinementAnswer> answers;
  final List<ManualSmartFillRefinementKind> skippedKinds;
  final bool answered;
  final bool clarificationDismissed;
  final bool cancelledByManualOverride;

  const ManualSmartFillState.idle() : this();

  int get decisionsUsed => answers.length + skippedKinds.length;

  bool get canRestart =>
      !cancelledByManualOverride &&
      query != null &&
      decisionsUsed > 0 &&
      (status == ManualSmartFillStatus.filled ||
          status == ManualSmartFillStatus.needsClarification);

  bool get showClarification {
    if (cancelledByManualOverride) return false;
    if (status != ManualSmartFillStatus.needsClarification) return false;
    return result?.hasSupportedClarification ?? false;
  }

  ManualSmartFillNextRefinement? get visibleRefinement =>
      showClarification ? result?.nextRefinement : null;

  ManualSmartFillState copyWith({
    ManualSmartFillStatus? status,
    ManualSmartFillQuery? query,
    ManualSmartFillResult? result,
    int? applyRevision,
    List<ManualSmartFillRefinementAnswer>? answers,
    List<ManualSmartFillRefinementKind>? skippedKinds,
    bool? answered,
    bool? clarificationDismissed,
    bool? cancelledByManualOverride,
    bool clearQuery = false,
    bool clearResult = false,
  }) {
    return ManualSmartFillState(
      status: status ?? this.status,
      query: clearQuery ? null : (query ?? this.query),
      result: clearResult ? null : (result ?? this.result),
      applyRevision: applyRevision ?? this.applyRevision,
      answers: answers ?? this.answers,
      skippedKinds: skippedKinds ?? this.skippedKinds,
      answered: answered ?? this.answered,
      clarificationDismissed:
          clarificationDismissed ?? this.clarificationDismissed,
      cancelledByManualOverride:
          cancelledByManualOverride ?? this.cancelledByManualOverride,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    result,
    applyRevision,
    answers,
    skippedKinds,
    answered,
    clarificationDismissed,
    cancelledByManualOverride,
  ];
}
