import '../models/schedule.dart';
import '../models/last_fed.dart';

abstract class PetFeederRepository {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> feedNow();
  Future<void> updateSchedule(List<Schedule> schedules);
  Future<void> updateServingSize(int servingSize);
  Future<void> updateSchedulingEnabled(bool enabled);
  Future<void> requestInitialData();
  Stream<List<Schedule>> get scheduleStream;
  Stream<int> get servingSizeStream;
  Stream<bool> get schedulingEnabledStream;
  Stream<bool> get connectionStatusStream;
  Stream<LastFed> get lastFedStream;

  /// Cancels internal subscriptions and closes internal stream controllers.
  /// The repository owns those resources, so it owns their teardown too.
  void dispose();
}