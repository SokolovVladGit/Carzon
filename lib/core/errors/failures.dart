import 'package:equatable/equatable.dart';

/// Domain-level failures returned from repositories/usecases to presentation.
///
/// Presentation layer must only know about [Failure], never raw exceptions.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message, runtimeType];
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    this.postgrestCode,
    this.diagnosticsDetails,
  });

  final String? postgrestCode;
  final String? diagnosticsDetails;

  @override
  List<Object?> get props => [
        message,
        postgrestCode,
        diagnosticsDetails,
        runtimeType,
      ];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
