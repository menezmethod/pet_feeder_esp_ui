class LastFed {
  // Null when the firmware fed before its clock had synced (fedAt: 0) --
  // a real 1970 epoch is not a plausible feed time, so this is "unknown
  // time", not "January 1970".
  final DateTime? fedAt;
  final int servingSize;
  final String trigger;

  const LastFed({
    required this.fedAt,
    required this.servingSize,
    required this.trigger,
  });

  factory LastFed.fromJson(Map<String, dynamic> json) {
    // Defensive at this trust boundary (MQTT payload): a missing/null field
    // here used to throw uncaught inside the repository's message handler,
    // silently dropping the whole lastFed update rather than degrading it.
    final epochSeconds = json['fedAt'] as int? ?? 0;
    return LastFed(
      fedAt: epochSeconds > 0 ? DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000) : null,
      servingSize: json['servingSize'] as int? ?? 0,
      trigger: json['trigger'] as String? ?? 'manual',
    );
  }
}
