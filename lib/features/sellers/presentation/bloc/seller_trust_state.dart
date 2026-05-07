import 'package:equatable/equatable.dart';

import '../../domain/entities/seller_public_profile.dart';

enum SellerTrustUiStatus { loading, hidden, ready }

class SellerTrustState extends Equatable {
  const SellerTrustState._({required this.status, this.profile});

  const SellerTrustState.loading()
    : this._(status: SellerTrustUiStatus.loading);

  const SellerTrustState.hidden() : this._(status: SellerTrustUiStatus.hidden);

  SellerTrustState.ready(SellerPublicProfile profile)
    : this._(status: SellerTrustUiStatus.ready, profile: profile);

  final SellerTrustUiStatus status;
  final SellerPublicProfile? profile;

  @override
  List<Object?> get props => [status, profile];
}
