import '../entities/upgrade_habit.dart';

abstract class UpgradeHabitRepository {
  Future<List<UpgradeHabit>> getAll();
  Future<List<UpgradeHabit>> getForUpgrade(String upgradeId);
  Future<List<UpgradeHabit>> getActiveForUpgrade(String upgradeId);
  Future<UpgradeHabit?> getActiveForHabit(String habitId);
  Future<void> save(UpgradeHabit membership);
  Future<void> delete(String id);
  Future<void> removeHabitFromUpgrade(String habitId, String upgradeId);
}
