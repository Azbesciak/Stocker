typedef JsonObj = Map<String, dynamic>;
typedef JsonArr = List<JsonObj>;

T identityMapper<T>(T v) => v;

typedef Mapper<IN, OUT> = OUT Function(IN input);

Mapper<dynamic, OUT> returnDataMapper<IN, OUT>(Mapper<IN, OUT> mapper) =>
    (input) => mapper(input["returnData"] as IN);

Mapper<Iterable<dynamic>, List<OUT>> arrayDataMapper<OUT>(
  Mapper<JsonObj, OUT> mapper,
) =>
    (input) => List.from(input.map((v) => mapper(v as JsonObj)));

List<T> extractJsonList<T>(
  Iterable<dynamic> source,
  Mapper<JsonObj, T> mapper,
) {
  return List.from(source.map((v) => mapper(v as JsonObj)));
}

String trimIfTooLong(String value, [int limit = 100]) {
  if (value.length > limit) {
    var visibleLength = (limit / 2).round();
    return value.substring(0, visibleLength) +
        "..." +
        value.substring(value.length - visibleLength);
  }
  return value;
}
