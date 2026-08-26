import 'package:foundation/src/app_failure.dart';

sealed class Result<T> {
  const Result();

  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;

  AppFailure? get failureOrNull =>
      this is FailureResult<T> ? (this as FailureResult<T>).failure : null;
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final AppFailure failure;
}
