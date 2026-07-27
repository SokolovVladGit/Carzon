import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/get_my_seller_profile.dart';

/// Loads authenticated `seller_profiles` avatar/display name for private
/// account visuals (menu identity, listings header). [ProfilePage] reads
/// avatar from [PublicSellerIdentityCubit] directly to stay in sync with edits.
class SelfSellerVisualState extends Equatable {
  const SelfSellerVisualState({
    this.loading = false,
    this.sellerAvatarUrl,
    this.sellerDisplayName,
    this.loadFailed = false,
  });

  final bool loading;
  final String? sellerAvatarUrl;
  final String? sellerDisplayName;

  /// Set when [prime] receives [FailureResult] while still authenticated.
  /// Previous avatar/name are intentionally preserved when present.
  final bool loadFailed;

  SelfSellerVisualState copyWith({
    bool? loading,
    String? sellerAvatarUrl,
    String? sellerDisplayName,
    bool clearSellerAvatarUrl = false,
    bool clearSellerDisplayName = false,
    bool? loadFailed,
    bool clearLoadFailed = false,
  }) {
    return SelfSellerVisualState(
      loading: loading ?? this.loading,
      sellerAvatarUrl: clearSellerAvatarUrl
          ? null
          : (sellerAvatarUrl ?? this.sellerAvatarUrl),
      sellerDisplayName: clearSellerDisplayName
          ? null
          : (sellerDisplayName ?? this.sellerDisplayName),
      loadFailed: clearLoadFailed ? false : (loadFailed ?? this.loadFailed),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    sellerAvatarUrl,
    sellerDisplayName,
    loadFailed,
  ];
}

class SelfSellerVisualCubit extends Cubit<SelfSellerVisualState> {
  SelfSellerVisualCubit(this._getMySellerProfile)
    : super(const SelfSellerVisualState());

  final GetMySellerProfile _getMySellerProfile;

  String? _currentUserId;
  bool _hasSynchronizedAuth = false;
  int _sessionGeneration = 0;
  int _primeGeneration = 0;

  Future<void> prime(AuthState auth) async {
    if (isClosed) return;
    final userId = auth.status == AuthStatus.authenticated
        ? auth.user?.id
        : null;
    final firstSynchronization = !_hasSynchronizedAuth;
    final userChanged = !firstSynchronization && userId != _currentUserId;
    final sessionChanged = firstSynchronization || userChanged;
    if (sessionChanged) {
      _hasSynchronizedAuth = true;
      _currentUserId = userId;
      _sessionGeneration += 1;
      _primeGeneration += 1;
      if (isClosed) return;
      if (userId == null || userChanged) {
        emit(const SelfSellerVisualState());
      }
    }

    if (userId == null) {
      return;
    }

    final sessionGeneration = _sessionGeneration;
    final primeGeneration = ++_primeGeneration;
    emit(state.copyWith(loading: true, clearLoadFailed: true));
    final result = await _getMySellerProfile();
    if (!_isCurrentPrime(userId, sessionGeneration, primeGeneration)) return;

    switch (result) {
      case FailureResult():
        emit(state.copyWith(loading: false, loadFailed: true));
      case Success(:final value):
        final trimmedUrl = value.avatarUrl?.trim();
        final trimmedName = value.displayName?.trim();
        emit(
          SelfSellerVisualState(
            loading: false,
            loadFailed: false,
            sellerAvatarUrl: trimmedUrl != null && trimmedUrl.isNotEmpty
                ? trimmedUrl
                : null,
            sellerDisplayName: trimmedName != null && trimmedName.isNotEmpty
                ? trimmedName
                : null,
          ),
        );
    }
  }

  bool _isCurrentPrime(
    String userId,
    int sessionGeneration,
    int primeGeneration,
  ) {
    return !isClosed &&
        _currentUserId == userId &&
        _sessionGeneration == sessionGeneration &&
        _primeGeneration == primeGeneration;
  }
}
