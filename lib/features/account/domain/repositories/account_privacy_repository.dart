import '../../../../core/utils/result.dart';

/// Account privacy operations (self-service deletion).
abstract interface class AccountPrivacyRepository {
  /// Permanently deletes the authenticated user's account and app data.
  Future<Result<void>> deleteOwnAccount();
}
