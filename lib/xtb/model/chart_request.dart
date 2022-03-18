import 'package:stocker/xtb/model/chart_period.dart';

class ChartRequest {
  final int end;
  final ChartPeriod period;
  final int start;
  final String symbol;
  final int ticks;

  const ChartRequest({
    required this.end,
    required this.period,
    required this.start,
    required this.symbol,
    required this.ticks,
  });

  Map<String, dynamic> toMap() {
    return {
      'end': end,
      'period': period.value,
      'start': start,
      'symbol': symbol,
      'ticks': ticks,
    };
  }
}