import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/locale_keys.g.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePicker({super.key, required this.initialTime});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _hour;
  late int _minute;
  late bool _isAM;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hourOfPeriod;
    _minute = widget.initialTime.minute;
    _isAM = widget.initialTime.period == DayPeriod.am;
    if (_hour == 0) _hour = 12;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Dialog(
      backgroundColor: surfaceColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAM ? LocaleKeys.CustomTimePicker_am : LocaleKeys.CustomTimePicker_pm}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: onSurfaceColor),
            ).tr(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNumberPicker(
                  value: _hour,
                  minValue: 1,
                  maxValue: 12,
                  onChanged: (value) {
                    setState(() {
                      _hour = value;
                    });
                  },
                ),
                _buildNumberPicker(
                  value: _minute,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) {
                    setState(() {
                      _minute = value;
                    });
                  },
                ),
                Column(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          _isAM ? primaryColor : theme.colorScheme.secondary,
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          _isAM ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isAM = true;
                        });
                      },
                      child: const Text(LocaleKeys.CustomTimePicker_am).tr(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          !_isAM ? primaryColor : theme.colorScheme.secondary,
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          !_isAM ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isAM = false;
                        });
                      },
                      child: const Text(LocaleKeys.CustomTimePicker_pm).tr(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(theme.colorScheme.secondary),
                    foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondary),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(LocaleKeys.ButtonCommonTitles_cancel).tr(),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(primaryColor),
                    foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
                  ),
                  onPressed: () {
                    int selectedHour;
                    if (_isAM) {
                      selectedHour = _hour == 12 ? 0 : _hour;
                    } else {
                      selectedHour = _hour == 12 ? 12 : _hour + 12;
                    }
                    Navigator.of(context).pop(TimeOfDay(hour: selectedHour, minute: _minute));
                  },
                  child: const Text(LocaleKeys.ButtonCommonTitles_ok).tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_upward, color: onSurfaceColor),
          onPressed: () {
            onChanged((value + 1 > maxValue) ? minValue : value + 1);
          },
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(fontSize: 24, color: onSurfaceColor),
        ),
        IconButton(
          icon: Icon(Icons.arrow_downward, color: onSurfaceColor),
          onPressed: () {
            onChanged((value - 1 < minValue) ? maxValue : value - 1);
          },
        ),
      ],
    );
  }
}
