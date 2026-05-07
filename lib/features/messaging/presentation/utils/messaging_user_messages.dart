import '../../../../l10n/app_localizations.dart';
import '../../domain/messaging_failure_kind.dart';

/// Maps [MessagingFailureKind] to localized snackbar / inline copy.
String messagingFailureMessage(
  AppLocalizations l10n,
  MessagingFailureKind kind,
) {
  return switch (kind) {
    MessagingFailureKind.notAuthenticated => l10n.messagingSignInRequired,
    MessagingFailureKind.network => l10n.messagingNetworkError,
    MessagingFailureKind.serverRejected => l10n.messagingServerError,
    MessagingFailureKind.conversationNotFound =>
      l10n.messagingConversationNotFound,
    MessagingFailureKind.messageValidation => l10n.messagingInvalidMessage,
    MessagingFailureKind.unknown => l10n.messagingServerError,
  };
}
