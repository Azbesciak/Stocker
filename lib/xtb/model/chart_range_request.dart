import 'package:stocker/xtb/model/chart_request.dart';

class ChartRangeRequest extends ChartRequest {
  final int end;
  final int ticks;

  const ChartRangeRequest({
    period,
    start,
    symbol,
    required this.end,
    required this.ticks,
  }) : super(period: period, start: start, symbol: symbol);

  @override
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
