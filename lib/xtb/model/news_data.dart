class NewsData {
  final String body;
  final String key;
  final int time;
  final String title;

  const NewsData({
    required this.body,
    required this.key,
    required this.time,
    required this.title,
  });

  factory NewsData.fromMap(Map<String, dynamic> map) {
    return NewsData(
      body: map['body'] as String,
      key: map['key'] as String,
      time: map['time'] as int,
      title: map['title'] as String,
    );
  }
}
