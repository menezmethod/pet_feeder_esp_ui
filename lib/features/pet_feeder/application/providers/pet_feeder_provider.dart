import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/models/schedule.dart';
import '../../domain/repositories/pet_feeder_repository.dart';

class PetFeederProvider with ChangeNotifier {
  late PetFeederRepository _repository;

  PetFeederProvider(this._repository) {
    connect();
  }

  List<Schedule> _schedules = [];
  List<Schedule> get schedules => _schedules;

  bool _isSchedulingEnabled = true;
  bool get isSchedulingEnabled => _isSchedulingEnabled;

  int _portionSize = 1000;
  int get portionSize => _portionSize;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Stream<List<Schedule>> get scheduleStream => _repository.scheduleStream;
  Stream<int> get servingSizeStream => _repository.servingSizeStream;
  Stream<bool> get schedulingEnabledStream => _repository.schedulingEnabledStream;
  Stream<bool> get connectionStatusStream => _repository.connectionStatusStream;

  void updateRepository(PetFeederRepository repository) {
    debugPrint('Updating repository...');
    _repository = repository;
    connect();
  }

  Future<void> connect() async {
    debugPrint('Connecting to repository...');
    await _repository.connect();
    _repository.connectionStatusStream.listen((status) {
      _isConnected = status;
      if (status) {
        Timer(const Duration(milliseconds: 200), () {
          requestInitialData();
        });
      }
      notifyListeners();
    });
    _repository.scheduleStream.listen((schedules) {
      _schedules = schedules;
      debugPrint('Schedules updated: $schedules');
      notifyListeners();
    });
    _repository.schedulingEnabledStream.listen((enabled) {
      _isSchedulingEnabled = enabled;
      debugPrint('Scheduling enabled status updated: $enabled');
      notifyListeners();
    });
    _repository.servingSizeStream.listen((size) {
      _portionSize = size;
      debugPrint('Serving size updated: $size');
      notifyListeners();
    });
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting from repository...');
    await _repository.disconnect();
  }

  Future<void> feedNow() async {
    debugPrint('Feeding now...');
    await _repository.feedNow();
  }

  Future<void> updateSchedule(List<Schedule> schedules) async {
    debugPrint('Updating schedule...');
    await _repository.updateSchedule(schedules);
  }

  Future<void> updateServingSize(int servingSize) async {
    debugPrint('Updating serving size...');
    await _repository.updateServingSize(servingSize);
  }

  Future<void> updateSchedulingEnabled(bool enabled) async {
    debugPrint('Updating scheduling enabled...');
    await _repository.updateSchedulingEnabled(enabled);
  }

  Future<void> requestInitialData() async {
    await _repository.requestInitialData();
  }

  Future<void> toggleSchedule(int index, bool enabled) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    updatedSchedules[index] = Schedule(
      hour: updatedSchedules[index].hour,
      minute: updatedSchedules[index].minute,
      enabled: enabled,
    );
    await updateSchedule(updatedSchedules);
  }

  Future<void> updateScheduleTime(int index, int hour, int minute) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    updatedSchedules[index] = Schedule(
      hour: hour,
      minute: minute,
      enabled: updatedSchedules[index].enabled,
    );
    await updateSchedule(updatedSchedules);
  }
}
