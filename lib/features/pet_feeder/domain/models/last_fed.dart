class LastFed {
  final DateTime fedAt;
  final int servingSize;
  final String trigger;

  const LastFed({
    required this.fedAt,
    required this.servingSize,
    required this.trigger,
  });

  factory LastFed.fromJson(Map<String, dynamic> json) {
    return LastFed(
      fedAt: DateTime.fromMillisecondsSinceEpoch((json['fedAt'] as int) * 1000),
      servingSize: json['servingSize'] as int,
      trigger: json['trigger'] as String? ?? 'manual',
    );
  }
}
