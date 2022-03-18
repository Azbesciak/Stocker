import 'package:stocker/xtb/json_helper.dart';

class TradingHoursData {
  final List<TimePeriod> quotes;
  final String symbol;
  final List<TimePeriod> trading;

  const TradingHoursData({
    required this.quotes,
    required this.symbol,
    required this.trading,
  });

  factory TradingHoursData.fromMap(Map<String, dynamic> map) {
    return TradingHoursData(
      quotes: extractJsonList(map['quotes'], TimePeriod.fromMap),
      symbol: map['symbol'] as String,
      trading: extractJsonList(map['trading'], TimePeriod.fromMap),
    );
  }
}

class TimePeriod {
  final int day;
  final int fromT;
  final int toT;

  const TimePeriod({
    required this.day,
    required this.fromT,
    required this.toT,
  });

  factory TimePeriod.fromMap(Map<String, dynamic> map) {
    return TimePeriod(
      day: map['day'] as int,
      fromT: map['fromT'] as int,
      toT: map['toT'] as int,
    );
  }
}
