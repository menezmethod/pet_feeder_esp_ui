class Schedule {
  int hour;
  int minute;
  bool enabled;

  Schedule({required this.hour, required this.minute, required this.enabled});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      hour: json['hour'],
      minute: json['minute'],
      enabled: json['enabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(hour, minute, enabled);
}