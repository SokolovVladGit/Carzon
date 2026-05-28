import 'package:equatable/equatable.dart';

import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_resolved_slot.dart';

/// Screen-specific state for resolving listings on the compare page.
class ComparePageState extends Equatable {
  const ComparePageState({this.slots = const [], this.isResolving = false});

  const ComparePageState.idle() : slots = const [], isResolving = false;

  final List<CompareResolvedSlot> slots;
  final bool isResolving;

  bool get hasSlots => slots.isNotEmpty;

  ComparePageState copyWith({
    List<CompareResolvedSlot>? slots,
    bool? isResolving,
  }) {
    return ComparePageState(
      slots: slots ?? this.slots,
      isResolving: isResolving ?? this.isResolving,
    );
  }

  /// Builds loading slots from compare items (snapshot headers only).
  static ComparePageState resolving(List<CompareItem> items) {
    return ComparePageState(
      isResolving: true,
      slots: items
          .map(
            (item) => CompareResolvedSlot(
              item: item,
              phase: CompareSlotPhase.loading,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [slots, isResolving];
}
