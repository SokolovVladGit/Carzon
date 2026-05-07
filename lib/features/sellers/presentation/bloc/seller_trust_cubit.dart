import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_seller_public_profile.dart';
import 'seller_trust_state.dart';

class SellerTrustCubit extends Cubit<SellerTrustState> {
  SellerTrustCubit(this._getSellerPublicProfile)
    : super(const SellerTrustState.loading());

  final GetSellerPublicProfile _getSellerPublicProfile;

  Future<void> load(String sellerId) async {
    emit(const SellerTrustState.loading());
    final result = await _getSellerPublicProfile(sellerId);
    result.fold((_) => emit(const SellerTrustState.hidden()), (profile) {
      if (profile == null) {
        emit(const SellerTrustState.hidden());
      } else {
        emit(SellerTrustState.ready(profile));
      }
    });
  }
}
