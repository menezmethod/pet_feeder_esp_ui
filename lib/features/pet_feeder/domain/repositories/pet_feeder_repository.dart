import '../models/schedule.dart';

abstract class PetFeederRepository {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> feedNow();
  Future<void> updateSchedule(List<Schedule> schedules);
  Future<void> updateServingSize(int servingSize);
  Future<void> updateSchedulingEnabled(bool enabled);
  Stream<List<Schedule>> get scheduleStream;
  Stream<int> get servingSizeStream;
  Stream<bool> get schedulingEnabledStream;
  Stream<bool> get connectionStatusStream;
}