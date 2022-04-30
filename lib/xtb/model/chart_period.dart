class ChartPeriod {
  final int value;
  final int valueInMs;
  final String tag;

  const ChartPeriod._({
    required this.value,
    required this.tag,
  }) : valueInMs = value * 1000 * 60;

  static const ChartPeriod M1 = ChartPeriod._(value: 1, tag: 'M1');
  static const ChartPeriod M5 = ChartPeriod._(value: 5, tag: 'M5');
  static const ChartPeriod M15 = ChartPeriod._(value: 15, tag: 'M15');
  static const ChartPeriod M30 = ChartPeriod._(value: 30, tag: 'M30');
  static const ChartPeriod H1 = ChartPeriod._(value: 60, tag: 'H1');
  static const ChartPeriod H4 = ChartPeriod._(value: 240, tag: 'H4');
  static const ChartPeriod D1 = ChartPeriod._(value: 1440, tag: 'D1');
  static const ChartPeriod W1 = ChartPeriod._(value: 10080, tag: 'W1');
  static const ChartPeriod MN1 = ChartPeriod._(value: 43200, tag: 'MN1');

  @override
  String toString() => tag;
}
