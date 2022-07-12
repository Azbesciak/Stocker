import 'package:intl/intl.dart';

Map<T, List<S>> groupBy<S, T>(Iterable<S> values, T Function(S v) key) {
  var map = <T, List<S>>{};
  for (var element in values) {
    (map[key(element)] ??= []).add(element);
  }
  return map;
}

NumberFormat getPriceFormat(int decimalPlaces) =>
    NumberFormat(decimalPlaces == 0 ? '#,###' : '#,##0.' + '0' * decimalPlaces);
