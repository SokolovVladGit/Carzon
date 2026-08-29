/// Typed failure reasons for messaging flows (presentation maps to l10n).
enum MessagingFailureKind {
  notAuthenticated,
  network,
  serverRejected,
  conversationNotFound,
  messageValidation,
  contentRejected,
  messagingBlocked,
  unknown,
}
