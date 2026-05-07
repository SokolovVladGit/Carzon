import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/my_seller_profile.dart';
import '../../domain/usecases/clear_seller_avatar.dart';
import '../../domain/usecases/get_my_seller_profile.dart';
import '../../domain/usecases/update_my_seller_display_name.dart';
import '../../domain/usecases/upload_seller_avatar.dart';
import 'public_seller_identity_state.dart';

class PublicSellerIdentityCubit extends Cubit<PublicSellerIdentityState> {
  PublicSellerIdentityCubit({
    required GetMySellerProfile getMySellerProfile,
    required UpdateMySellerDisplayName updateMySellerDisplayName,
    required UploadSellerAvatar uploadSellerAvatar,
    required ClearSellerAvatar clearSellerAvatar,
  }) : _getMySellerProfile = getMySellerProfile,
       _updateMySellerDisplayName = updateMySellerDisplayName,
       _uploadSellerAvatar = uploadSellerAvatar,
       _clearSellerAvatar = clearSellerAvatar,
       super(const PublicSellerIdentityState());

  final GetMySellerProfile _getMySellerProfile;
  final UpdateMySellerDisplayName _updateMySellerDisplayName;
  final UploadSellerAvatar _uploadSellerAvatar;
  final ClearSellerAvatar _clearSellerAvatar;

  void consumeAvatarSnack() {
    emit(state.copyWith(avatarSnack: PublicSellerAvatarSnack.none));
  }

  Future<void> load() async {
    emit(
      state.copyWith(
        initialLoading: true,
        loadFailed: false,
        saveFailed: false,
      ),
    );
    final result = await _getMySellerProfile();
    result.fold(
      (_) => emit(state.copyWith(initialLoading: false, loadFailed: true)),
      (profile) => emit(
        state.copyWith(
          initialLoading: false,
          profile: profile,
          loadFailed: false,
        ),
      ),
    );
  }

  /// Trims input; empty/cleared string persists as null `display_name` server-side.
  Future<void> save(String rawInput) async {
    final trimmed = rawInput.trim();
    final toPersist = trimmed.isEmpty ? null : trimmed;

    emit(state.copyWith(saving: true, saveFailed: false));
    final result = await _updateMySellerDisplayName(toPersist);
    result.fold(
      (_) => emit(state.copyWith(saving: false, saveFailed: true)),
      (profile) => emit(
        state.copyWith(saving: false, profile: profile, saveFailed: false),
      ),
    );
  }

  /// Upload immediately after gallery pick (bytes + MIME).
  Future<void> uploadAvatarFromPicker({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final prevPath = _previousStoragePath(state.profile);
    emit(
      state.copyWith(
        avatarBusy: true,
        avatarSnack: PublicSellerAvatarSnack.none,
      ),
    );
    final result = await _uploadSellerAvatar(
      bytes: bytes,
      contentType: contentType,
      previousAvatarStoragePath: prevPath,
    );
    result.fold(
      (f) {
        final snack = f is SellerAvatarUnsupportedFormat
            ? PublicSellerAvatarSnack.unsupportedFormat
            : PublicSellerAvatarSnack.uploadFailed;
        emit(state.copyWith(avatarBusy: false, avatarSnack: snack));
      },
      (profile) => emit(
        state.copyWith(
          avatarBusy: false,
          profile: profile,
          avatarSnack: PublicSellerAvatarSnack.uploaded,
        ),
      ),
    );
  }

  Future<void> removeAvatar() async {
    if (!_hasAvatarVisual(state.profile)) return;
    final prevPath = _previousStoragePath(state.profile);
    emit(
      state.copyWith(
        avatarBusy: true,
        avatarSnack: PublicSellerAvatarSnack.none,
      ),
    );
    final result = await _clearSellerAvatar(
      previousAvatarStoragePath: prevPath,
    );
    result.fold(
      (_) => emit(
        state.copyWith(
          avatarBusy: false,
          avatarSnack: PublicSellerAvatarSnack.removeFailed,
        ),
      ),
      (profile) => emit(
        state.copyWith(
          avatarBusy: false,
          profile: profile,
          avatarSnack: PublicSellerAvatarSnack.removed,
        ),
      ),
    );
  }

  static String? _previousStoragePath(MySellerProfile? profile) {
    final p = profile?.avatarPath?.trim();
    if (p == null || p.isEmpty) return null;
    return p;
  }

  static bool _hasAvatarVisual(MySellerProfile? profile) {
    if (profile == null) return false;
    final u = profile.avatarUrl?.trim();
    if (u != null && u.isNotEmpty) return true;
    final p = profile.avatarPath?.trim();
    return p != null && p.isNotEmpty;
  }
}
