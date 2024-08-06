import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  CustomTimePicker({required this.initialTime});

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
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
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: onSurfaceColor),
            ),
            SizedBox(height: 20),
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
                      child: Text('AM'),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          _isAM ? primaryColor : theme.colorScheme.secondary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          _isAM ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isAM = true;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('PM'),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          !_isAM ? primaryColor : theme.colorScheme.secondary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          !_isAM ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isAM = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('Cancel'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(theme.colorScheme.secondary),
                    foregroundColor: MaterialStateProperty.all(theme.colorScheme.onSecondary),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('OK'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(primaryColor),
                    foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary),
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