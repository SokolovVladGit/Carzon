import 'package:equatable/equatable.dart';

import '../../domain/entities/my_seller_context.dart';
import '../../domain/entities/seller_type.dart';

enum SellerModeStatus { initial, loading, ready, saving, error }

class SellerModeState extends Equatable {
  const SellerModeState({
    this.status = SellerModeStatus.initial,
    this.context,
    this.draftType = SellerType.private,
    this.saveFailed = false,
  });

  final SellerModeStatus status;
  final MySellerContext? context;
  final SellerType draftType;
  final bool saveFailed;

  SellerType get authoritativeType => context?.sellerType ?? SellerType.private;

  bool get isDirty => context != null && draftType != context!.sellerType;

  bool get showVerified => context?.verifiedDealer == true;

  SellerModeState copyWith({
    SellerModeStatus? status,
    MySellerContext? context,
    SellerType? draftType,
    bool? saveFailed,
  }) {
    return SellerModeState(
      status: status ?? this.status,
      context: context ?? this.context,
      draftType: draftType ?? this.draftType,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }

  @override
  List<Object?> get props => [status, context, draftType, saveFailed];
}
