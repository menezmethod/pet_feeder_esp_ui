import 'package:flutter/material.dart';

String formatTime(int hour, int minute) {
  final time = TimeOfDay(hour: hour, minute: minute);
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  final hourIn12HourFormat = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return '${hourIn12HourFormat.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
}