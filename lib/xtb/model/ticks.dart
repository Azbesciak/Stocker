class TicksData {
  final double ask;
  final int? askVolume;
  final double bid;
  final int? bidVolume;
  final double high;
  final int level;
  final double low;
  final int quoteId;
  final double spreadRaw;
  final double spreadTable;
  final String symbol;
  final int timestamp;

  const TicksData({
    required this.ask,
    required this.askVolume,
    required this.bid,
    required this.bidVolume,
    required this.high,
    required this.level,
    required this.low,
    required this.quoteId,
    required this.spreadRaw,
    required this.spreadTable,
    required this.symbol,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'ask': ask,
      'askVolume': askVolume,
      'bid': bid,
      'bidVolume': bidVolume,
      'high': high,
      'level': level,
      'low': low,
      'quoteId': quoteId,
      'spreadRaw': spreadRaw,
      'spreadTable': spreadTable,
      'symbol': symbol,
      'timestamp': timestamp,
    };
  }

  factory TicksData.fromMap(Map<String, dynamic> map) {
    return TicksData(
      ask: map['ask'] as double,
      askVolume: map['askVolume'] as int?,
      bid: map['bid'] as double,
      bidVolume: map['bidVolume'] as int?,
      high: map['high'] as double,
      level: map['level'] as int,
      low: map['low'] as double,
      quoteId: map['quoteId'] as int,
      spreadRaw: map['spreadRaw'] as double,
      spreadTable: map['spreadTable'] as double,
      symbol: map['symbol'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  @override
  String toString() => toMap().toString();
}
