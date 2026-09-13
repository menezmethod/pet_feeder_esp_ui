import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/last_fed.dart';
import '../../domain/repositories/pet_feeder_repository.dart';
import '../../../../core/utils/log.dart';

enum FeedRequestState { idle, sending, awaitingConfirmation, confirmed, timedOut }

class PetFeederProvider with ChangeNotifier {
  late PetFeederRepository _repository;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _feedTimeoutTimer;
  Timer? _feedResetTimer;

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

  LastFed? _lastFed;
  LastFed? get lastFed => _lastFed;

  FeedRequestState _feedRequestState = FeedRequestState.idle;
  FeedRequestState get feedRequestState => _feedRequestState;

  Stream<List<Schedule>> get scheduleStream => _repository.scheduleStream;
  Stream<int> get servingSizeStream => _repository.servingSizeStream;
  Stream<bool> get schedulingEnabledStream => _repository.schedulingEnabledStream;
  Stream<bool> get connectionStatusStream => _repository.connectionStatusStream;

  void updateRepository(PetFeederRepository repository) {
    logDebug('Updating repository...');
    _cancelSubscriptions();
    _repository = repository;
    connect();
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> connect() async {
    logDebug('Connecting to repository...');
    await _repository.connect();
    _subscriptions.add(_repository.connectionStatusStream.listen((status) {
      _isConnected = status;
      if (status) {
        Timer(const Duration(milliseconds: 200), () {
          requestInitialData();
        });
      }
      notifyListeners();
    }));
    _subscriptions.add(_repository.scheduleStream.listen((schedules) {
      _schedules = schedules;
      logDebug('Schedules updated: $schedules');
      notifyListeners();
    }));
    _subscriptions.add(_repository.schedulingEnabledStream.listen((enabled) {
      _isSchedulingEnabled = enabled;
      logDebug('Scheduling enabled status updated: $enabled');
      notifyListeners();
    }));
    _subscriptions.add(_repository.servingSizeStream.listen((size) {
      _portionSize = size;
      logDebug('Serving size updated: $size');
      notifyListeners();
    }));
    _subscriptions.add(_repository.lastFedStream.listen(_onLastFed));
  }

  void _onLastFed(LastFed fed) {
    _lastFed = fed;
    if (_feedRequestState == FeedRequestState.awaitingConfirmation) {
      _feedTimeoutTimer?.cancel();
      _feedRequestState = FeedRequestState.confirmed;
      _scheduleFeedStateReset();
    }
    notifyListeners();
  }

  void _scheduleFeedStateReset() {
    _feedResetTimer?.cancel();
    _feedResetTimer = Timer(const Duration(seconds: 2), () {
      _feedRequestState = FeedRequestState.idle;
      notifyListeners();
    });
  }

  Future<void> disconnect() async {
    logDebug('Disconnecting from repository...');
    await _repository.disconnect();
  }

  /// Sends a feed command and tracks it through to confirmation. This is the
  /// double-feed guard: a tap while a request is genuinely in flight
  /// (sending or awaiting the device's status/last_fed confirmation) is
  /// ignored outright, rather than just visually debounced -- a debounce
  /// would hide a real double-send, this refuses to send it at all. A tap
  /// after confirmed/timedOut is a new, legitimate request.
  Future<void> feedNow() async {
    if (_feedRequestState == FeedRequestState.sending ||
        _feedRequestState == FeedRequestState.awaitingConfirmation) {
      return;
    }
    logDebug('Feeding now...');
    _feedRequestState = FeedRequestState.sending;
    notifyListeners();

    try {
      await _repository.feedNow();
    } catch (e) {
      // Without this, a throw here (MQTT disconnected mid-publish, etc.)
      // leaves _feedRequestState stuck at "sending" forever -- the guard at
      // the top of this method would then refuse every future tap, and the
      // feed button would be permanently disabled until the app restarts.
      logDebug('Feed command failed to send: $e');
      _feedRequestState = FeedRequestState.timedOut;
      notifyListeners();
      _scheduleFeedStateReset();
      return;
    }

    _feedRequestState = FeedRequestState.awaitingConfirmation;
    notifyListeners();

    _feedTimeoutTimer?.cancel();
    _feedTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (_feedRequestState == FeedRequestState.awaitingConfirmation) {
        _feedRequestState = FeedRequestState.timedOut;
        notifyListeners();
        _scheduleFeedStateReset();
      }
    });
  }

  Future<void> updateSchedule(List<Schedule> schedules) async {
    logDebug('Updating schedule...');
    await _repository.updateSchedule(schedules);
  }

  Future<void> updateServingSize(int servingSize) async {
    logDebug('Updating serving size...');
    await _repository.updateServingSize(servingSize);
  }

  Future<void> updateSchedulingEnabled(bool enabled) async {
    logDebug('Updating scheduling enabled...');
    await _repository.updateSchedulingEnabled(enabled);
  }

  Future<void> requestInitialData() async {
    await _repository.requestInitialData();
  }

  static const int maxSchedules = 6;

  Future<void> toggleSchedule(int index, bool enabled) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    final s = updatedSchedules[index];
    updatedSchedules[index] = Schedule(hour: s.hour, minute: s.minute, enabled: enabled, days: s.days);
    await updateSchedule(updatedSchedules);
  }

  Future<void> updateScheduleTime(int index, int hour, int minute) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    final s = updatedSchedules[index];
    updatedSchedules[index] = Schedule(hour: hour, minute: minute, enabled: s.enabled, days: s.days);
    await updateSchedule(updatedSchedules);
  }

  Future<void> updateScheduleDays(int index, int days) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    final s = updatedSchedules[index];
    updatedSchedules[index] = Schedule(hour: s.hour, minute: s.minute, enabled: s.enabled, days: days);
    await updateSchedule(updatedSchedules);
  }

  /// Combined time+days update in one publish. Calling updateScheduleTime()
  /// and updateScheduleDays() back to back would race: _schedules only
  /// reflects the device's echo back over MQTT, which the second call would
  /// not have seen yet, silently discarding whichever change went first.
  Future<void> updateScheduleTimeAndDays(int index, int hour, int minute, int days) async {
    List<Schedule> updatedSchedules = List.from(_schedules);
    final s = updatedSchedules[index];
    updatedSchedules[index] = Schedule(hour: hour, minute: minute, enabled: s.enabled, days: days);
    await updateSchedule(updatedSchedules);
  }

  /// Appends a new slot (default: an hour after the last one, every day,
  /// enabled) as long as there's room under the firmware's MAX_SCHEDULES cap.
  Future<void> addSchedule() async {
    if (_schedules.length >= maxSchedules) return;
    final last = _schedules.isNotEmpty ? _schedules.last : null;
    final hour = last != null ? (last.hour + 1) % 24 : 8;
    final updated = [
      ..._schedules,
      Schedule(hour: hour, minute: last?.minute ?? 0, enabled: true, days: allDays),
    ];
    await updateSchedule(updated);
  }

  Future<void> removeSchedule(int index) async {
    final updated = List<Schedule>.from(_schedules)..removeAt(index);
    await updateSchedule(updated);
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _feedTimeoutTimer?.cancel();
    _feedResetTimer?.cancel();
    super.dispose();
  }
}
