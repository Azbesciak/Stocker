import 'package:stocker/xtb/model/candle_data.dart';

import '../json_helper.dart';

class ChartData {
  final int digits;
  final List<CandleData> rateInfos;

  const ChartData({
    required this.digits,
    required this.rateInfos,
  });

  @override
  String toString() => toMap().toString();

  Map<String, dynamic> toMap() {
    return {
      'digits': digits,
      'rateInfos': rateInfos,
    };
  }

  factory ChartData.fromMap(Map<String, dynamic> map) {
    return ChartData(
      digits: map['digits'] as int,
      rateInfos: extractJsonList(map['rateInfos'], CandleData.fromRelativeMap),
    );
  }
}
