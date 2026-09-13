/// Day-of-week bitmask, matching the firmware exactly: bit 0 = Sunday
/// ... bit 6 = Saturday (struct tm's tm_wday numbering). allDays = every day.
const int allDays = 0x7F;

const List<String> weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

String describeDays(int days) {
  if (days == allDays) return 'Every day';
  if (days == 0) return 'Never';
  const weekdays = 0x3E; // Mon-Fri
  const weekend = 0x41; // Sun+Sat
  if (days == weekdays) return 'Weekdays';
  if (days == weekend) return 'Weekends';
  final active = [
    for (var i = 0; i < 7; i++)
      if (days & (1 << i) != 0) weekdayLabels[i],
  ];
  return active.join(', ');
}

class Schedule {
  int hour;
  int minute;
  bool enabled;
  int days;

  Schedule({
    required this.hour,
    required this.minute,
    required this.enabled,
    this.days = allDays,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      hour: json['hour'],
      minute: json['minute'],
      enabled: json['enabled'],
      days: json['days'] as int? ?? allDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'days': days,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          enabled == other.enabled &&
          days == other.days;

  @override
  int get hashCode => Object.hash(hour, minute, enabled, days);
}
