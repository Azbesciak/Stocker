class CandleData {
  final double close;
  final int ctm;
  final double high;
  final double low;
  final double open;
  final double vol;

  const CandleData({
    required this.close,
    required this.ctm,
    required this.high,
    required this.low,
    required this.open,
    required this.vol,
  });

  factory CandleData.fromRelativeMap(Map<String, dynamic> map) {
    var openPrice = map['open'] as double;
    return CandleData(
      open: openPrice,
      close: openPrice + map['close'],
      high: openPrice + map['high'],
      low: openPrice + map['low'],
      ctm: map['ctm'] as int,
      vol: map['vol'] as double,
    );
  }

  factory CandleData.fromMap(Map<String, dynamic> map) {
    return CandleData(
      close: map['close'] as double,
      ctm: map['ctm'] as int,
      high: map['high'] as double,
      low: map['low'] as double,
      open: map['open'] as double,
      vol: map['vol'] as double,
    );
  }
}
