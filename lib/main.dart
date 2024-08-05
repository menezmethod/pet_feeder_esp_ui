import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Feeder Control',
      theme: ThemeData(
        primaryColor: Color(0xFF40798C),
        scaffoldBackgroundColor: Color(0xFFCFD7C7),
        colorScheme: ColorScheme(
          primary: Color(0xFF40798C),
          primaryContainer: Color(0xFF70A9A1),
          secondary: Color(0xFF0B2027),
          secondaryContainer: Color(0xFF40798C),
          surface: Color(0xFFF6F1D1),
          background: Color(0xFFCFD7C7),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0B2027)),
          bodyMedium: TextStyle(color: Color(0xFF0B2027)),
        ),
      ),
      home: PetFeederPage(),
    );
  }
}

class PetFeederPage extends StatefulWidget {
  @override
  _PetFeederPageState createState() => _PetFeederPageState();
}

class _PetFeederPageState extends State<PetFeederPage> {
  late MqttService mqttService;
  bool isConnected = false;
  List<Schedule> schedules = [
    Schedule(hour: 8, minute: 0, enabled: true),
    Schedule(hour: 18, minute: 0, enabled: true),
  ];

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(
      broker: '192.168.0.221',
      port: 9001,
      clientIdentifier: 'flutter_pet_feeder_${DateTime.now().millisecondsSinceEpoch}',
      onConnected: _onConnected,
      onDisconnected: _onDisconnected,
      onMessageReceived: _onMessageReceived,
    );
    mqttService.connect();
  }

  void _onConnected() {
    setState(() {
      isConnected = true;
    });
    mqttService.subscribe('feeder/#');
    _getScheduleStatus();
  }

  void _onDisconnected() {
    setState(() {
      isConnected = false;
    });
  }

  void _onMessageReceived(String topic, String payload) {
    if (topic == 'feeder/schedule_status') {
      _updateScheduleStatus(payload);
    }
  }

  void _publishMessage(String topic, String message) {
    mqttService.publish(topic, message);
  }

  void _getScheduleStatus() {
    _publishMessage('feeder/get_schedule', '');
  }

  void _updateScheduleStatus(String payload) {
    Map<String, dynamic> status = json.decode(payload);
    setState(() {
      schedules = (status['schedules'] as List).map((s) => Schedule.fromJson(s)).toList();
    });
  }

  void _sendUpdatedSchedule() {
    String scheduleJson = json.encode({
      'schedules': schedules.map((s) => s.toJson()).toList(),
    });
    _publishMessage('feeder/schedule', scheduleJson);
  }

  Future<void> _showCustomTimePicker(BuildContext context, int index) async {
    final TimeOfDay? result = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePicker(
          initialTime: TimeOfDay(hour: schedules[index].hour, minute: schedules[index].minute),
        );
      },
    );

    if (result != null) {
      setState(() {
        schedules[index].hour = result.hour;
        schedules[index].minute = result.minute;
      });
      _sendUpdatedSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text('Crawler Pet Feeder', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(mqttService: mqttService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.pets, size: 80, color: Theme.of(context).colorScheme.primaryContainer),
                        onPressed: () {
                          _publishMessage('feeder/feed', '');
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Feed Now',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                ...schedules.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Schedule schedule = entry.value;
                  return ListTile(
                    title: Text(formatTime(schedule.hour, schedule.minute)),
                    trailing: Switch(
                      value: schedule.enabled,
                      onChanged: (value) {
                        setState(() {
                          schedules[idx].enabled = value;
                        });
                        _sendUpdatedSchedule();
                      },
                    ),
                    onTap: () => _showCustomTimePicker(context, idx),
                  );
                }).toList(),
                SizedBox(height: 20),
                Text('Connection Status: ${isConnected ? 'Connected' : 'Disconnected'}'),
                if (!isConnected)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      SvgPicture.asset(
                        'assets/noun-reconnect-3547862.svg',
                        height: 50,
                        width: 50,
                        color: Colors.red,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: mqttService.connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text('Reconnect'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  String formatTime(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourIn12HourFormat = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${hourIn12HourFormat.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class MqttService {
  final String broker;
  final int port;
  final String clientIdentifier;
  final VoidCallback onConnected;
  final VoidCallback onDisconnected;
  final Function(String topic, String payload) onMessageReceived;

  MqttBrowserClient? _client;

  MqttService({
    required this.broker,
    required this.port,
    required this.clientIdentifier,
    required this.onConnected,
    required this.onDisconnected,
    required this.onMessageReceived,
  });

  Future<void> connect() async {
    _client = MqttBrowserClient.withPort('ws://$broker', clientIdentifier, port);
    _client!.logging(on: true);
    _client!.onConnected = onConnected;
    _client!.onDisconnected = onDisconnected;
    _client!.onSubscribed = (String topic) {
      print('Subscribed to topic: $topic');
    };
    _client!.pongCallback = () {
      print('Ping response received');
    };

    final connMessage = MqttConnectMessage().withClientIdentifier(clientIdentifier).startClean();
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('Exception: $e');
      onDisconnected();
    }
  }

  void disconnect() {
    _client?.disconnect();
  }

  void subscribe(String topic) {
    _client?.subscribe(topic, MqttQos.atLeastOnce);
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      onMessageReceived(c[0].topic, payload);
    });
  }

  void publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      print('Not connected to MQTT broker');
    }
  }
}

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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('PM'),
                      onPressed: () {
                        setState(() {
                          _isAM = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    final selectedHour = (_isAM && _hour == 12) ? 0 : (_isAM ? _hour : _hour + 12);
                    Navigator.of(context).pop(TimeOfDay(hour: selectedHour % 24, minute: _minute));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
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

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  final MqttService mqttService;

  SettingsPage({required this.mqttService});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isBluetoothConnected = false;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;
  String ssid = '';
  String password = '';
  bool isSchedulingEnabled = true;
  int portionSize = 100;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _connectToBluetoothDevice() async {
    setState(() {
      isBluetoothConnected = false;
    });

    try {
      await flutterBlue.startScan(timeout: Duration(seconds: 5));
      var subscription = flutterBlue.scanResults.listen((scanResult) async {
        for (ScanResult result in scanResult) {
          if (result.device.name == 'ESP_FEEDER') {
            flutterBlue.stopScan();
            connectedDevice = result.device;
            await connectedDevice!.connect();
            var services = await connectedDevice!.discoverServices();
            var service = services.firstWhere((s) => s.uuid.toString() == '00FF');
            wifiCharacteristic = service.characteristics.firstWhere((c) => c.uuid.toString() == 'FF01');

            setState(() {
              isBluetoothConnected = true;
            });
            break;
          }
        }
      });
      await subscription.cancel();
    } catch (e) {
      print("Error starting scan: $e");
    }
  }

  Future<void> _showWifiSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wi-Fi Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'SSID'),
                onChanged: (value) {
                  ssid = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                onChanged: (value) {
                  password = value;
                },
                obscureText: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: isBluetoothConnected ? () {
                _sendWifiCredentials();
                Navigator.of(context).pop();
              } : null,
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _sendWifiCredentials() async {
    if (connectedDevice != null && wifiCharacteristic != null) {
      String credentials = 'ssid:$ssid,pass:$password';
      await wifiCharacteristic!.write(utf8.encode(credentials));
      await wifiCharacteristic!.write(utf8.encode("reboot")); // This command reboots the Wi-Fi on the ESP32
    }
  }

  void _sendPortionSize() {
    // MQTT message to set the portion size
    print('Sending portion size: $portionSize');
    widget.mqttService.publish('feeder/serving_size', portionSize.toString());
  }

  void _sendGlobalSchedulingStatus() {
    print('Sending global scheduling status: ${isSchedulingEnabled ? 'enabled' : 'disabled'}');
    widget.mqttService.publish('feeder/scheduling_enable', isSchedulingEnabled ? '1' : '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Set up Bluetooth'),
            trailing: Icon(Icons.bluetooth),
            onTap: _connectToBluetoothDevice,
          ),
          ListTile(
            title: Text('Wi-Fi Settings'),
            trailing: Icon(Icons.wifi),
            onTap: isBluetoothConnected ? _showWifiSettingsDialog : null,
          ),
          ListTile(
            title: Text('Set Portion Size'),
            trailing: Icon(Icons.food_bank),
            onTap: () async {
              int? result = await showDialog<int>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Set Portion Size'),
                    content: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        portionSize = int.tryParse(value) ?? portionSize;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter portion size',
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(portionSize);
                        },
                        child: Text('Save'),
                      ),
                    ],
                  );
                },
              );
              if (result != null) {
                setState(() {
                  portionSize = result;
                });
                _sendPortionSize();
              }
            },
          ),
          SwitchListTile(
            title: Text('Enable Global Scheduling'),
            value: isSchedulingEnabled,
            onChanged: (value) {
              setState(() {
                isSchedulingEnabled = value;
              });
              _sendGlobalSchedulingStatus();
            },
          ),
        ],
      ),
    );
  }
}
