class ErrorData {
  final String errorCode;
  final String errorDescr;

  const ErrorData({
    required this.errorCode,
    required this.errorDescr,
  });

  Map<String, dynamic> toMap() {
    return {
      'errorCode': errorCode,
      'errorDescr': errorDescr,
    };
  }

  factory ErrorData.fromMap(Map<String, dynamic> map) {
    return ErrorData(
      errorCode: map['errorCode'] as String,
      errorDescr: map['errorDescr'] as String,
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
