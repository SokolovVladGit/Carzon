import '../../../../core/errors/failures.dart';
import '../../domain/messaging_failure_kind.dart';

/// Maps repository [Failure] values to [MessagingFailureKind] for UI.
MessagingFailureKind messagingFailureKindFrom(Failure failure) {
  if (failure is! ServerFailure) {
    return switch (failure) {
      AuthFailure _ => MessagingFailureKind.notAuthenticated,
      NetworkFailure _ => MessagingFailureKind.network,
      _ => MessagingFailureKind.unknown,
    };
  }
  final m = failure.message.toLowerCase();
  if (m.contains('not authenticated')) {
    return MessagingFailureKind.notAuthenticated;
  }
  if (m.contains('conversation not found') || m.contains('not a participant')) {
    return MessagingFailureKind.conversationNotFound;
  }
  if (m.contains('message body is required') ||
      m.contains('message body is too long')) {
    return MessagingFailureKind.messageValidation;
  }
  if (m.contains('messaging blocked')) {
    return MessagingFailureKind.messagingBlocked;
  }
  if (m.contains('jwt') || m.contains('permission')) {
    return MessagingFailureKind.serverRejected;
  }
  return MessagingFailureKind.serverRejected;
}
