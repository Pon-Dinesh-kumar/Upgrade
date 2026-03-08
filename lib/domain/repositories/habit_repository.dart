import '../entities/habit.dart';
import '../entities/habit_entry.dart';

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<Habit?> getHabit(String id);
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
  Future<List<Habit>> getHabitsByUpgrade(String upgradeId);
  Future<List<Habit>> getActiveHabits();

  Future<List<HabitEntry>> getEntriesForHabit(String habitId);
  Future<List<HabitEntry>> getEntriesForDate(DateTime date);
  Future<HabitEntry?> getEntry(String habitId, DateTime date);
  Future<void> saveEntry(HabitEntry entry);
  Future<void> deleteEntry(String id);
  Future<List<HabitEntry>> getAllEntries();
}
