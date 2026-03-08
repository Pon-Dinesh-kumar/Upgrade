import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/local/local_storage.dart';

class HabitRepositoryImpl implements HabitRepository {
  final LocalStorage _storage;
  static const _habitsKey = 'habits';
  static const _entriesKey = 'habit_entries';

  HabitRepositoryImpl(this._storage);

  @override
  Future<List<Habit>> getAllHabits() async {
    final data = await _storage.readList(_habitsKey);
    return data.map((e) => Habit.fromJson(e)).toList();
  }

  @override
  Future<Habit?> getHabit(String id) async {
    final habits = await getAllHabits();
    try {
      return habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final habits = await getAllHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }
    await _storage.writeList(_habitsKey, habits.map((h) => h.toJson()).toList());
  }

  @override
  Future<void> deleteHabit(String id) async {
    final habits = await getAllHabits();
    habits.removeWhere((h) => h.id == id);
    await _storage.writeList(_habitsKey, habits.map((h) => h.toJson()).toList());
  }

  @override
  Future<List<Habit>> getHabitsByUpgrade(String upgradeId) async {
    final habits = await getAllHabits();
    return habits.where((h) => h.upgradeId == upgradeId).toList();
  }

  @override
  Future<List<Habit>> getActiveHabits() async {
    final habits = await getAllHabits();
    return habits.where((h) => !h.archived).toList();
  }

  @override
  Future<List<HabitEntry>> getEntriesForHabit(String habitId) async {
    final entries = await getAllEntries();
    return entries.where((e) => e.habitId == habitId).toList();
  }

  @override
  Future<List<HabitEntry>> getEntriesForDate(DateTime date) async {
    final entries = await getAllEntries();
    return entries.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  @override
  Future<HabitEntry?> getEntry(String habitId, DateTime date) async {
    final entries = await getEntriesForHabit(habitId);
    try {
      return entries.firstWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEntry(HabitEntry entry) async {
    final entries = await getAllEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    await _storage.writeList(_entriesKey, entries.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> deleteEntry(String id) async {
    final entries = await getAllEntries();
    entries.removeWhere((e) => e.id == id);
    await _storage.writeList(_entriesKey, entries.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<HabitEntry>> getAllEntries() async {
    final data = await _storage.readList(_entriesKey);
    return data.map((e) => HabitEntry.fromJson(e)).toList();
  }
}
