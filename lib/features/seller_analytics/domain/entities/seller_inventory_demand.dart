import 'package:equatable/equatable.dart';

/// Point-in-time unique matching accounts for the seller's active inventory.
///
/// Counts unique CARZON accounts, not saved-search rows. Suppression is
/// explicit: never encode 1–4 as a fake number.
class SellerInventoryDemand extends Equatable {
  const SellerInventoryDemand({
    required this.matchingUsers,
    required this.isSuppressed,
  });

  final int? matchingUsers;
  final bool isSuppressed;

  bool get isZero => !isSuppressed && matchingUsers == 0;

  bool get isPrivacySuppressed => isSuppressed && matchingUsers == null;

  bool get isVisibleCount =>
      !isSuppressed && matchingUsers != null && matchingUsers! >= 5;

  @override
  List<Object?> get props => [matchingUsers, isSuppressed];
}
