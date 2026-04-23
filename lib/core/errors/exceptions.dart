/// Low-level exceptions thrown by data layer (datasources).
/// They should be caught in repositories and converted into [Failure]s.
class AppException implements Exception {
  AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  ServerException(super.message, {super.cause, super.stackTrace});
}

class AuthException extends AppException {
  AuthException(super.message, {super.cause, super.stackTrace});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.cause, super.stackTrace});
}

class CacheException extends AppException {
  CacheException(super.message, {super.cause, super.stackTrace});
}
