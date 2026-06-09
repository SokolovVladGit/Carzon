import '../../../../l10n/app_localizations.dart';
import '../../../../core/errors/failures.dart';

/// Maps support-conversation open failures to localized snackbar copy.
String supportConversationOpenFailureMessage(
  AppLocalizations l10n,
  Failure failure,
) {
  final message = failure.message.toLowerCase();
  if (message.contains('support account is not configured')) {
    return l10n.contactSupportOpenFailure;
  }
  if (message.contains('cannot open a support conversation as the support account')) {
    return l10n.contactSupportSelfFailure;
  }
  if (message.contains('not authenticated')) {
    return l10n.messagingSignInRequired;
  }
  return l10n.contactSupportOpenFailure;
}
