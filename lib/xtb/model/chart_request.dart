import 'package:stocker/xtb/model/chart_period.dart';

class ChartRequest {
  final ChartPeriod period;
  final int start;
  final String symbol;

  const ChartRequest({
    required this.period,
    required this.start,
    required this.symbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period.value,
      'start': start,
      'symbol': symbol,
    };
  }
}
