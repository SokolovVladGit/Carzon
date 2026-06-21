import '../../../../l10n/app_localizations.dart';
import '../../domain/messaging_failure_kind.dart';

/// Maps [MessagingFailureKind] to localized snackbar / inline copy.
///
/// [isSendAction]: `true` when the failure is tied to sending a message or
/// starting a thread (retry copy should read as a send failure). `false`
/// for background refreshes / polls.
String messagingFailureMessage(
  AppLocalizations l10n,
  MessagingFailureKind kind, {
  bool isSendAction = false,
}) {
  if (isSendAction) {
    return switch (kind) {
      MessagingFailureKind.notAuthenticated => l10n.messagingSignInRequired,
      MessagingFailureKind.network => l10n.userErrorNetworkCheckConnection,
      MessagingFailureKind.messageValidation => l10n.messagingInvalidMessage,
      MessagingFailureKind.conversationNotFound =>
        l10n.messagingConversationNotFound,
      MessagingFailureKind.messagingBlocked =>
        l10n.messagingSafetySendUnavailable,
      MessagingFailureKind.serverRejected ||
      MessagingFailureKind.unknown => l10n.messagingSendFailed,
    };
  }
  return switch (kind) {
    MessagingFailureKind.notAuthenticated => l10n.messagingSignInRequired,
    MessagingFailureKind.network => l10n.userErrorNetworkCheckConnection,
    MessagingFailureKind.serverRejected => l10n.messagingServerError,
    MessagingFailureKind.conversationNotFound =>
      l10n.messagingConversationNotFound,
    MessagingFailureKind.messageValidation => l10n.messagingInvalidMessage,
    MessagingFailureKind.messagingBlocked =>
      l10n.messagingSafetySendUnavailable,
    MessagingFailureKind.unknown => l10n.messagingServerError,
  };
}
