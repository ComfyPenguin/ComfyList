import '../failures/failure.dart';

/// Resultado tipado simple. Evita lanzar excepciones hacia presentation.
sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) =>
      switch (this) {
        Ok<T>(value: final v) => onOk(v),
        Err<T>(failure: final f) => onErr(f),
      };

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
