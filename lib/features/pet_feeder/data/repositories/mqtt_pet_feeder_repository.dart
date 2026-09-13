import 'dart:async';
import 'dart:convert';
import '../../domain/models/schedule.dart';
import '../../domain/models/last_fed.dart';
import '../../../../services/mqtt_service.dart';
import '../../../../core/utils/log.dart';

class _Topics {
  static const prefix = 'pet_feeder_esp32/v1';
  static const feed = '$prefix/commands/feed';
  static const servingSize = '$prefix/settings/serving_size';
  static const schedule = '$prefix/settings/schedule';
  static const schedulingEnable = '$prefix/settings/scheduling_enable';
  static const getStatus = '$prefix/requests/get_status';
  static const getSchedule = '$prefix/requests/get_schedule';
  static const status = '$prefix/status/general';
  static const scheduleStatus = '$prefix/status/schedule';
  static const lastFed = '$prefix/status/last_fed';
  static const all = '$prefix/#';
}

class MqttPetFeederRepository {
  final MqttService _mqttService;

  final _scheduleStreamController = StreamController<List<Schedule>>.broadcast();
  final _servingSizeStreamController = StreamController<int>.broadcast();
  final _schedulingEnabledStreamController = StreamController<bool>.broadcast();
  final _lastFedStreamController = StreamController<LastFed>.broadcast();

  final List<StreamSubscription> _subscriptions = [];

  List<Schedule> _currentSchedules = [];
  int _currentServingSize = 1000;
  bool _currentSchedulingEnabled = false;

  MqttPetFeederRepository(this._mqttService) {
    _subscriptions.add(_mqttService.connectionStatus.listen((status) {
      if (status == MqttConnectionState.connected) {
        _subscribeToTopics();
      }
    }));
    _subscriptions.add(_mqttService.messageStream.listen(_handleMessage));
  }

  Future<void> connect() async {
    await _mqttService.connect();
  }

  Future<void> disconnect() async {
    _mqttService.disconnect();
  }

  Future<void> feedNow() async {
    _mqttService.publish(_Topics.feed, '');
  }

  Future<void> updateSchedule(List<Schedule> schedules) async {
    if (!_areSchedulesEqual(_currentSchedules, schedules)) {
      _currentSchedules = List.from(schedules);
      final scheduleJson = json.encode({
        'schedules': schedules.map((s) => s.toJson()).toList(),
      });
      _mqttService.publish(_Topics.schedule, scheduleJson);
    }
  }

  Future<void> updateServingSize(int servingSize) async {
    if (_currentServingSize != servingSize) {
      _currentServingSize = servingSize;
      _mqttService.publish(_Topics.servingSize, servingSize.toString());
    }
  }

  Future<void> updateSchedulingEnabled(bool enabled) async {
    if (_currentSchedulingEnabled != enabled) {
      _currentSchedulingEnabled = enabled;
      _mqttService.publish(_Topics.schedulingEnable, enabled.toString());
    }
  }

  Future<void> requestInitialData() async {
    _mqttService.publish(_Topics.getStatus, '');
    _mqttService.publish(_Topics.getSchedule, '');
  }

  Stream<List<Schedule>> get scheduleStream => _scheduleStreamController.stream;

  Stream<int> get servingSizeStream => _servingSizeStreamController.stream;

  Stream<bool> get schedulingEnabledStream => _schedulingEnabledStreamController.stream;

  Stream<bool> get connectionStatusStream =>
      _mqttService.connectionStatus.map((status) => status == MqttConnectionState.connected);

  Stream<LastFed> get lastFedStream => _lastFedStreamController.stream;

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _scheduleStreamController.close();
    _servingSizeStreamController.close();
    _schedulingEnabledStreamController.close();
    _lastFedStreamController.close();
  }

  void _subscribeToTopics() {
    _mqttService.subscribe(_Topics.all);
  }

  void _handleMessage(ReceivedMessage message) {
    // Each handler is independently guarded: one malformed payload on one
    // topic must not take down the listener for every other topic.
    try {
      switch (message.topic) {
        case _Topics.scheduleStatus:
          _handleScheduleStatus(message.payload);
          break;
        case _Topics.servingSize:
          _handleServingSize(message.payload);
          break;
        case _Topics.schedulingEnable:
          _handleSchedulingEnabled(message.payload);
          break;
        case _Topics.status:
          _handleStatus(message.payload);
          break;
        case _Topics.lastFed:
          _handleLastFed(message.payload);
          break;
      }
    } catch (e, stack) {
      logDebug('MQTT: failed to handle message on ${message.topic}: $e\n$stack');
    }
  }

  void _handleScheduleStatus(String payload) {
    final status = json.decode(payload);
    final schedules = (status['schedules'] as List)
        .map((s) => Schedule.fromJson(s))
        .toList();
    _currentSchedules = schedules;
    _scheduleStreamController.add(schedules);
    _currentSchedulingEnabled = status['enabled'];
    _schedulingEnabledStreamController.add(status['enabled']);
  }

  void _handleServingSize(String payload) {
    final servingSize = int.parse(payload);
    _currentServingSize = servingSize;
    _servingSizeStreamController.add(servingSize);
  }

  void _handleSchedulingEnabled(String payload) {
    final enabled = payload == '1' || payload.toLowerCase() == 'true';
    _currentSchedulingEnabled = enabled;
    _schedulingEnabledStreamController.add(enabled);
  }

  void _handleStatus(String payload) {
    final status = json.decode(payload);
    if (status.containsKey('servingSize')) {
      _currentServingSize = status['servingSize'];
      _servingSizeStreamController.add(status['servingSize']);
    }
  }

  void _handleLastFed(String payload) {
    final data = json.decode(payload) as Map<String, dynamic>;
    _lastFedStreamController.add(LastFed.fromJson(data));
  }

  bool _areSchedulesEqual(List<Schedule> a, List<Schedule> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
