import '../../../../l10n/app_localizations.dart';
import '../../domain/seller_display_name_constraints.dart';

final RegExp _emailLikeDisplayName = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Client-side validation mirroring backend rules (trim / max length / no email-shaped names).
String? validatePublicSellerDisplayName(String raw, AppLocalizations l10n) {
  final t = raw.trim();
  if (t.length > SellerDisplayNameConstraints.maxLength) {
    return l10n.profilePublicSellerNameTooLong;
  }
  if (t.isNotEmpty && _emailLikeDisplayName.hasMatch(t)) {
    return l10n.profilePublicSellerNameLooksLikeEmail;
  }
  return null;
}
