import '../errors/failures.dart';
import '../../l10n/app_localizations.dart';

/// Presentation surface hints for wording that should match the surrounding
/// feature (feed vs listing details vs generic dialogs).
enum LocalizedFailureSurface { generic, listingsFeed, listingDetails }

/// Maps a domain [Failure] to a concise, Russian, non-technical UI string.
///
/// Raw [Failure.message] contents must never be shown to users — they may
/// contain PostgREST/Supabase/English diagnostics. Preserve them only in logs
/// outside this API.
String localizedUserFailureMessage(
  AppLocalizations l10n,
  Failure failure, {
  LocalizedFailureSurface surface = LocalizedFailureSurface.generic,
}) {
  if (failure is SellerAvatarUnsupportedFormat) {
    return l10n.profilePublicSellerAvatarUnsupportedType;
  }
  if (failure is NetworkFailure) {
    return l10n.userErrorNetworkCheckConnection;
  }
  if (failure is AuthFailure) {
    return switch (surface) {
      LocalizedFailureSurface.listingsFeed => l10n.listingsLoadFailed,
      LocalizedFailureSurface.listingDetails => l10n.listingDetailsLoadFailed,
      LocalizedFailureSurface.generic => l10n.userErrorGenericTryAgain,
    };
  }
  if (failure is ServerFailure) {
    return _serverFailureUserMessage(l10n, failure, surface);
  }
  if (failure is CacheFailure || failure is UnknownFailure) {
    return l10n.userErrorGenericTryAgain;
  }
  return l10n.userErrorGenericTryAgain;
}

String _serverFailureUserMessage(
  AppLocalizations l10n,
  ServerFailure failure,
  LocalizedFailureSurface surface,
) {
  final m = failure.message.toLowerCase();
  final code = failure.postgrestCode?.toLowerCase();

  if (_looksLikePermission(m, code)) {
    return l10n.userErrorInsufficientPermission;
  }
  if (_looksLikeUpload(m)) {
    return l10n.userErrorUploadPhotoTryAgain;
  }
  if (_looksLikeNotFound(m, code)) {
    if (surface == LocalizedFailureSurface.listingDetails) {
      return l10n.listingUnavailableOrDeleted;
    }
    return surface == LocalizedFailureSurface.listingsFeed
        ? l10n.listingsLoadFailed
        : l10n.userErrorGenericTryAgain;
  }

  return switch (surface) {
    LocalizedFailureSurface.listingsFeed => l10n.listingsLoadFailed,
    LocalizedFailureSurface.listingDetails => l10n.listingDetailsLoadFailed,
    LocalizedFailureSurface.generic => l10n.userErrorGenericTryAgain,
  };
}

bool _looksLikeUpload(String messageLower) =>
    messageLower.contains('bucket') ||
    messageLower.contains('storage') ||
    messageLower.contains('object ') ||
    messageLower.contains('mime') ||
    messageLower.contains('image/');

bool _looksLikePermission(String messageLower, String? postgrestCode) {
  if (messageLower.contains('permission denied')) return true;
  if (messageLower.contains('row-level security') ||
      messageLower.contains(' rls ') ||
      messageLower.contains('violates row-level')) {
    return true;
  }
  if (messageLower.contains('jwt')) return true;
  if (messageLower.contains('invalid claim')) return true;
  if (messageLower.contains('42501')) return true;
  if (messageLower.contains('42503')) return true;
  if (postgrestCode != null &&
      postgrestCode.startsWith('pgrst') &&
      (messageLower.contains('permission') ||
          messageLower.contains('policy'))) {
    return true;
  }
  return false;
}

bool _looksLikeNotFound(String messageLower, String? postgrestCode) {
  if (postgrestCode == 'pgrst116') return true;
  if (messageLower.contains('json object requested, multiple')) {
    return true;
  }
  if (messageLower.contains('0 rows')) return true;
  if (messageLower.contains('no rows returned')) return true;
  if (messageLower.contains('no rows')) return true;
  if (messageLower.contains('not found')) return true;
  return false;
}
