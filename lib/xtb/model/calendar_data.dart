class CalendarData {
  final String country;
  final String current;
  final String forecast;
  final String impact;
  final String period;
  final String previous;
  final int time;
  final String title;

  const CalendarData({
    required this.country,
    required this.current,
    required this.forecast,
    required this.impact,
    required this.period,
    required this.previous,
    required this.time,
    required this.title,
  });

  factory CalendarData.fromMap(Map<String, dynamic> map) {
    return CalendarData(
      country: map['country'] as String,
      current: map['current'] as String,
      forecast: map['forecast'] as String,
      impact: map['impact'] as String,
      period: map['period'] as String,
      previous: map['previous'] as String,
      time: map['time'] as int,
      title: map['title'] as String,
    );
  }
}
