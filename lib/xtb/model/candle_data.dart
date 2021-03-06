class CandleData {
  final double open;
  final double close;
  final double low;
  final double high;
  final int ctm;
  final double vol;

  const CandleData({
    required this.open,
    required this.close,
    required this.low,
    required this.high,
    required this.ctm,
    required this.vol,
  });

  factory CandleData.fromRelativeMap(
    Map<String, dynamic> map, [
    num factor = 1,
  ]) {
    var openPrice = map['open'] as double;
    return CandleData(
      open: openPrice / factor,
      close: (openPrice + map['close']) / factor,
      high: (openPrice + map['high']) / factor,
      low: (openPrice + map['low']) / factor,
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

  Map<String, dynamic> toMap() {
    return {
      'close': close,
      'ctm': ctm,
      'high': high,
      'low': low,
      'open': open,
      'vol': vol,
    };
  }

  @override
  String toString() => toMap().toString();
}
