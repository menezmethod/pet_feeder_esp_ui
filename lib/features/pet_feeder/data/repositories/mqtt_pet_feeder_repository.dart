import 'dart:async';
import 'dart:convert';
import '../../domain/models/schedule.dart';
import '../../domain/repositories/pet_feeder_repository.dart';
import '../../../../services/mqtt_service.dart';

class MqttPetFeederRepository implements PetFeederRepository {
  final MqttService _mqttService;

  final _scheduleStreamController = StreamController<List<Schedule>>.broadcast();
  final _servingSizeStreamController = StreamController<int>.broadcast();
  final _schedulingEnabledStreamController = StreamController<bool>.broadcast();

  List<Schedule> _currentSchedules = [];
  int _currentServingSize = 0;
  bool _currentSchedulingEnabled = false;

  MqttPetFeederRepository(this._mqttService) {
    _mqttService.connectionStatus.listen((status) {
      if (status == MqttConnectionState.connected) {
        _subscribeToTopics();
      }
    });
    _mqttService.messageStream.listen(_handleMessage);
  }

  @override
  Future<void> connect() async {
    await _mqttService.connect();
  }

  @override
  Future<void> disconnect() async {
    _mqttService.disconnect();
  }

  @override
  Future<void> feedNow() async {
    _mqttService.publish('feeder/feed', '');
  }

  @override
  Future<void> updateSchedule(List<Schedule> schedules) async {
    if (!_areSchedulesEqual(_currentSchedules, schedules)) {
      _currentSchedules = List.from(schedules);
      final scheduleJson = json.encode({
        'schedules': schedules.map((s) => s.toJson()).toList(),
      });
      _mqttService.publish('feeder/schedule', scheduleJson);
    }
  }

  @override
  Future<void> updateServingSize(int servingSize) async {
    if (_currentServingSize != servingSize) {
      _currentServingSize = servingSize;
      _mqttService.publish('feeder/serving_size', servingSize.toString());
    }
  }

  @override
  Future<void> updateSchedulingEnabled(bool enabled) async {
    if (_currentSchedulingEnabled != enabled) {
      _currentSchedulingEnabled = enabled;
      _mqttService.publish('feeder/scheduling_enable', enabled.toString());
    }
  }

  @override
  Future<void> requestInitialData() async {
    _mqttService.publish('feeder/get_status', '');
  }

  @override
  Stream<List<Schedule>> get scheduleStream => _scheduleStreamController.stream;

  @override
  Stream<int> get servingSizeStream => _servingSizeStreamController.stream;

  @override
  Stream<bool> get schedulingEnabledStream => _schedulingEnabledStreamController.stream;

  @override
  Stream<bool> get connectionStatusStream =>
      _mqttService.connectionStatus.map((status) => status == MqttConnectionState.connected);

  void _subscribeToTopics() {
    _mqttService.subscribe('feeder/#');
  }

  void _handleMessage(ReceivedMessage message) {
    switch (message.topic) {
      case 'feeder/schedule_status':
        _handleScheduleStatus(message.payload);
        break;
      case 'feeder/serving_size':
        _handleServingSize(message.payload);
        break;
      case 'feeder/scheduling_enable':
        _handleSchedulingEnabled(message.payload);
        break;
      case 'feeder/status':
        _handleStatus(message.payload);
        break;
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
    final schedules = (status['schedules'] as List)
        .map((s) => Schedule.fromJson(s))
        .toList();
    if (status.containsKey('servingSize')) {
      _currentServingSize = status['servingSize'];
      _servingSizeStreamController.add(status['servingSize']);
      _currentSchedules = schedules;
      _scheduleStreamController.add(schedules);
    }
  }

  bool _areSchedulesEqual(List<Schedule> a, List<Schedule> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].toJson() != b[i].toJson()) return false;
    }
    return true;
  }
}