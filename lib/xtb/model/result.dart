import 'error_data.dart';

class Result<T> {
  final T? value;
  final ErrorData? error;

  Result.success({required this.value}) : error = null;

  Result.failure({required this.error}) : value = null;

  bool isSuccess() => error == null;

  @override
  String toString() {
    if (isSuccess()) {
      return "Result(success: $value)";
    } else {
      return "Result(failure: $error)";
    }
  }
}
