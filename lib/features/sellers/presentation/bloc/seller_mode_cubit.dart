import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/seller_type.dart';
import '../../domain/usecases/get_my_seller_context.dart';
import '../../domain/usecases/set_my_seller_type.dart';
import 'seller_mode_state.dart';

class SellerModeCubit extends Cubit<SellerModeState> {
  SellerModeCubit({
    required GetMySellerContext getMySellerContext,
    required SetMySellerType setMySellerType,
  }) : _getMySellerContext = getMySellerContext,
       _setMySellerType = setMySellerType,
       super(const SellerModeState());

  final GetMySellerContext _getMySellerContext;
  final SetMySellerType _setMySellerType;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    emit(const SellerModeState(status: SellerModeStatus.loading));
    final result = await _getMySellerContext();
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final value):
        emit(
          SellerModeState(
            status: SellerModeStatus.ready,
            context: value,
            draftType: value.sellerType,
          ),
        );
      case FailureResult():
        emit(const SellerModeState(status: SellerModeStatus.error));
    }
  }

  void select(SellerType type) {
    if (state.status != SellerModeStatus.ready &&
        state.status != SellerModeStatus.saving) {
      return;
    }
    if (state.status == SellerModeStatus.saving) return;
    emit(state.copyWith(draftType: type, saveFailed: false));
  }

  Future<void> save() async {
    final current = state.context;
    if (current == null || state.status != SellerModeStatus.ready) return;
    if (!state.isDirty) return;

    final generation = ++_generation;
    final requested = state.draftType;
    emit(state.copyWith(status: SellerModeStatus.saving, saveFailed: false));

    final result = await _setMySellerType(requested);
    if (isClosed || generation != _generation) return;

    switch (result) {
      case Success(:final value):
        emit(
          SellerModeState(
            status: SellerModeStatus.ready,
            context: value,
            draftType: value.sellerType,
          ),
        );
      case FailureResult():
        emit(
          SellerModeState(
            status: SellerModeStatus.ready,
            context: current,
            draftType: requested,
            saveFailed: true,
          ),
        );
    }
  }
}
