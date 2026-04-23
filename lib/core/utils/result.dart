import '../errors/failures.dart';

/// Lightweight Either-style result used between domain and presentation.
///
/// Avoids pulling in a functional library for a simple use case.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess);
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) =>
      onSuccess(value);
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) =>
      onFailure(failure);
}
