import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/data/repositories/habit_repository_impl.dart';
import 'package:upgrade/data/datasources/local/local_storage.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/habit_entry.dart';

class MockLocalStorage implements LocalStorage {
  Map<String, dynamic> storage = {};

  @override
  Future<List<Map<String, dynamic>>> readList(String key) async {
    return (storage[key] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    storage[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> readObject(String key) async {
    return storage[key] as Map<String, dynamic>?;
  }

  @override
  Future<void> writeObject(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      storage.remove(key);
    } else {
      storage[key] = value;
    }
  }

  @override
  Future<void> deleteFile(String key) async {
    storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    storage.clear();
  }

  @override
  Future<Map<String, dynamic>> exportForBackup() async {
    return Map<String, dynamic>.from(storage);
  }

  @override
  Future<void> importFromBackup(Map<String, dynamic> map) async {
    storage = Map<String, dynamic>.from(map);
  }
}

void main() {
  late HabitRepositoryImpl repository;
  late MockLocalStorage mockStorage;

  setUp(() {
    mockStorage = MockLocalStorage();
    repository = HabitRepositoryImpl(mockStorage);
  });

  group('HabitRepositoryImpl', () {
    test('getAllHabits returns empty list when storage is empty', () async {
      final results = await repository.getAllHabits();
      expect(results, isEmpty);
    });

    test('saveHabit saves a habit and getAllHabits retrieves it', () async {
      final habit = Habit(
        id: 'h1',
        name: 'Test Habit',
        upgradeId: 'u1',
      );

      await repository.saveHabit(habit);
      final results = await repository.getAllHabits();

      expect(results.length, 1);
      expect(results.first.id, 'h1');
      expect(results.first.name, 'Test Habit');
    });

    test('deleteHabit removes a habit', () async {
      final habit = Habit(
        id: 'h1',
        name: 'Test Habit',
        upgradeId: 'u1',
      );

      await repository.saveHabit(habit);
      await repository.deleteHabit('h1');
      final results = await repository.getAllHabits();

      expect(results, isEmpty);
    });

    test('saveEntry and getEntriesForHabit', () async {
      final entry = HabitEntry(
        id: 'e1',
        habitId: 'h1',
        date: DateTime.now(),
        completed: true,
      );

      await repository.saveEntry(entry);
      final entries = await repository.getEntriesForHabit('h1');

      expect(entries.length, 1);
      expect(entries.first.id, 'e1');
      expect(entries.first.habitId, 'h1');
    });
  });
}
