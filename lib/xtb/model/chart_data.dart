import 'dart:math';

import 'package:stocker/xtb/json_helper.dart';
import 'package:stocker/xtb/model/candle_data.dart';

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
    final digits = map['digits'] as int;
    final factor = pow(10, digits);
    return ChartData(
      digits: digits,
      rateInfos: extractJsonList(
        map['rateInfos'],
        (d) => CandleData.fromRelativeMap(d, factor),
      ),
    );
  }
}
