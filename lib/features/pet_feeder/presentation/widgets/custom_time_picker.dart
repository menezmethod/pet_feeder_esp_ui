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
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
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
                      onPressed: () {
                        setState(() {
                          _isAM = true;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('PM'),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    final selectedHour = (_isAM && _hour == 12) ? 0 : (_isAM ? _hour : _hour + 12);
                    Navigator.of(context).pop(TimeOfDay(hour: selectedHour % 24, minute: _minute));
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
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_upward),
          onPressed: () {
            onChanged((value + 1 > maxValue) ? minValue : value + 1);
          },
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(fontSize: 24),
        ),
        IconButton(
          icon: Icon(Icons.arrow_downward),
          onPressed: () {
            onChanged((value - 1 < minValue) ? maxValue : value - 1);
          },
        ),
      ],
    );
  }
}