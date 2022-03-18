class SymbolData {
  final double ask;
  final double bid;
  final String categoryName;
  final int contractSize;
  final String currency;
  final bool currencyPair;
  final String currencyProfit;
  final String description;
  final int? expiration;
  final String groupName;
  final double high;
  final int initialMargin;
  final int instantMaxVolume;
  final double leverage;
  final bool longOnly;
  final double lotMax;
  final double lotMin;
  final double lotStep;
  final double low;
  final int marginHedged;
  final bool marginHedgedStrong;
  final int? marginMaintenance;
  final int marginMode;
  final double percentage;
  final int precision;
  final int profitMode;
  final int quoteId;
  final bool shortSelling;
  final double spreadRaw;
  final double spreadTable;
  final int? starting;
  final int stepRuleId;
  final int stopsLevel;
  final int swap_rollover3days;
  final bool swapEnable;
  final double swapLong;
  final double swapShort;
  final int swapType;
  final String symbol;
  final double? tickSize;
  final double? tickValue;
  final int time;
  final bool trailingEnabled;
  final int type;

  const SymbolData({
    required this.ask,
    required this.bid,
    required this.categoryName,
    required this.contractSize,
    required this.currency,
    required this.currencyPair,
    required this.currencyProfit,
    required this.description,
    this.expiration,
    required this.groupName,
    required this.high,
    required this.initialMargin,
    required this.instantMaxVolume,
    required this.leverage,
    required this.longOnly,
    required this.lotMax,
    required this.lotMin,
    required this.lotStep,
    required this.low,
    required this.marginHedged,
    required this.marginHedgedStrong,
    this.marginMaintenance,
    required this.marginMode,
    required this.percentage,
    required this.precision,
    required this.profitMode,
    required this.quoteId,
    required this.shortSelling,
    required this.spreadRaw,
    required this.spreadTable,
    this.starting,
    required this.stepRuleId,
    required this.stopsLevel,
    required this.swap_rollover3days,
    required this.swapEnable,
    required this.swapLong,
    required this.swapShort,
    required this.swapType,
    required this.symbol,
    this.tickSize,
    this.tickValue,
    required this.time,
    required this.trailingEnabled,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'ask': ask,
      'bid': bid,
      'categoryName': categoryName,
      'contractSize': contractSize,
      'currency': currency,
      'currencyPair': currencyPair,
      'currencyProfit': currencyProfit,
      'description': description,
      'expiration': expiration,
      'groupName': groupName,
      'high': high,
      'initialMargin': initialMargin,
      'instantMaxVolume': instantMaxVolume,
      'leverage': leverage,
      'longOnly': longOnly,
      'lotMax': lotMax,
      'lotMin': lotMin,
      'lotStep': lotStep,
      'low': low,
      'marginHedged': marginHedged,
      'marginHedgedStrong': marginHedgedStrong,
      'marginMaintenance': marginMaintenance,
      'marginMode': marginMode,
      'percentage': percentage,
      'precision': precision,
      'profitMode': profitMode,
      'quoteId': quoteId,
      'shortSelling': shortSelling,
      'spreadRaw': spreadRaw,
      'spreadTable': spreadTable,
      'starting': starting,
      'stepRuleId': stepRuleId,
      'stopsLevel': stopsLevel,
      'swap_rollover3days': swap_rollover3days,
      'swapEnable': swapEnable,
      'swapLong': swapLong,
      'swapShort': swapShort,
      'swapType': swapType,
      'symbol': symbol,
      'tickSize': tickSize,
      'tickValue': tickValue,
      'time': time,
      'trailingEnabled': trailingEnabled,
      'type': type,
    };
  }

  factory SymbolData.fromMap(Map<String, dynamic> map) {
    return SymbolData(
      ask: map['ask'] as double,
      bid: map['bid'] as double,
      categoryName: map['categoryName'] as String,
      contractSize: map['contractSize'] as int,
      currency: map['currency'] as String,
      currencyPair: map['currencyPair'] as bool,
      currencyProfit: map['currencyProfit'] as String,
      description: map['description'] as String,
      expiration: map['expiration'] as int?,
      groupName: map['groupName'] as String,
      high: map['high'] as double,
      initialMargin: map['initialMargin'] as int,
      instantMaxVolume: map['instantMaxVolume'] as int,
      leverage: map['leverage'] as double,
      longOnly: map['longOnly'] as bool,
      lotMax: map['lotMax'] as double,
      lotMin: map['lotMin'] as double,
      lotStep: map['lotStep'] as double,
      low: map['low'] as double,
      marginHedged: map['marginHedged'] as int,
      marginHedgedStrong: map['marginHedgedStrong'] as bool,
      marginMaintenance: map['marginMaintenance'] as int?,
      marginMode: map['marginMode'] as int,
      percentage: map['percentage'] as double,
      precision: map['precision'] as int,
      profitMode: map['profitMode'] as int,
      quoteId: map['quoteId'] as int,
      shortSelling: map['shortSelling'] as bool,
      spreadRaw: map['spreadRaw'] as double,
      spreadTable: map['spreadTable'] as double,
      starting: map['starting'] as int?,
      stepRuleId: map['stepRuleId'] as int,
      stopsLevel: map['stopsLevel'] as int,
      swap_rollover3days: map['swap_rollover3days'] as int,
      swapEnable: map['swapEnable'] as bool,
      swapLong: map['swapLong'] as double,
      swapShort: map['swapShort'] as double,
      swapType: map['swapType'] as int,
      symbol: map['symbol'] as String,
      tickSize: map['tickSize'] as double?,
      tickValue: map['tickValue'] as double?,
      time: map['time'] as int,
      trailingEnabled: map['trailingEnabled'] as bool,
      type: map['type'] as int,
    );
  }
}
