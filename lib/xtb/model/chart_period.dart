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

  static ChartPeriod? of(String tag) {
    // switch case requires constant value, whereas field does not have it...
    if (tag == M1.tag) return M1;
    if (tag == M5.tag) return M5;
    if (tag == M15.tag) return M15;
    if (tag == M30.tag) return M30;
    if (tag == H1.tag) return H1;
    if (tag == H4.tag) return H4;
    if (tag == D1.tag) return D1;
    if (tag == W1.tag) return W1;
    if (tag == MN1.tag) return MN1;
    return null;
  }
}
