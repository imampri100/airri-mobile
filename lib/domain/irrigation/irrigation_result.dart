// Wrapper sederhana untuk hasil repository, tidak memakai freezed/dartz
// supaya tidak perlu code generation.
class IrrigationResult<T> {
  final T? data;
  final String? errorMessage;

  const IrrigationResult._(this.data, this.errorMessage);

  factory IrrigationResult.success(T data) => IrrigationResult._(data, null);

  factory IrrigationResult.failure(String message) =>
      IrrigationResult._(null, message);

  bool get isSuccess => errorMessage == null;
}
