class ErrorData {
  final String errorCode;
  final String errorDescr;

  const ErrorData({
    required this.errorCode,
    required this.errorDescr,
  });

  factory ErrorData.fromMap(Map<String, dynamic> map) {
    return ErrorData(
      errorCode: map['errorCode'] as String,
      errorDescr: map['errorDescr'] as String,
    );
  }
}
