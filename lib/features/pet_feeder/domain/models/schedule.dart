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
}