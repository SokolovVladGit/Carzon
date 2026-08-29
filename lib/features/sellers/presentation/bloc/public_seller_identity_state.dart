import 'package:equatable/equatable.dart';

import '../../domain/entities/my_seller_profile.dart';

/// Snackbar signal for avatar flows (cleared via [PublicSellerIdentityCubit.consumeAvatarSnack]).
enum PublicSellerAvatarSnack {
  none,
  uploaded,
  removed,
  uploadFailed,
  removeFailed,
  unsupportedFormat,
}

class PublicSellerIdentityState extends Equatable {
  const PublicSellerIdentityState({
    this.initialLoading = false,
    this.saving = false,
    this.profile,
    this.loadFailed = false,
    this.saveFailed = false,
    this.saveContentRejected = false,
    this.avatarBusy = false,
    this.avatarSnack = PublicSellerAvatarSnack.none,
  });

  final bool initialLoading;
  final bool saving;
  final MySellerProfile? profile;
  final bool loadFailed;
  final bool saveFailed;
  final bool saveContentRejected;

  final bool avatarBusy;
  final PublicSellerAvatarSnack avatarSnack;

  PublicSellerIdentityState copyWith({
    bool? initialLoading,
    bool? saving,
    MySellerProfile? profile,
    bool? loadFailed,
    bool? saveFailed,
    bool? saveContentRejected,
    bool? avatarBusy,
    PublicSellerAvatarSnack? avatarSnack,
  }) {
    return PublicSellerIdentityState(
      initialLoading: initialLoading ?? this.initialLoading,
      saving: saving ?? this.saving,
      profile: profile ?? this.profile,
      loadFailed: loadFailed ?? this.loadFailed,
      saveFailed: saveFailed ?? this.saveFailed,
      saveContentRejected: saveContentRejected ?? this.saveContentRejected,
      avatarBusy: avatarBusy ?? this.avatarBusy,
      avatarSnack: avatarSnack ?? this.avatarSnack,
    );
  }

  @override
  List<Object?> get props => [
    initialLoading,
    saving,
    profile,
    loadFailed,
    saveFailed,
    saveContentRejected,
    avatarBusy,
    avatarSnack,
  ];
}
