import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/habit_entry.dart';
import 'package:upgrade/domain/entities/user_profile.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';

void main() {
  group('Entity Serialization Tests', () {
    test('Habit serialization/deserialization', () {
      final habit = Habit(
        id: 'h1',
        name: 'Exercise',
        description: 'Daily workout',
        upgradeId: 'u1',
        difficulty: 'hard',
        currentStreak: 5,
        longestStreak: 10,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = habit.toJson();
      final fromJson = Habit.fromJson(json);

      expect(fromJson.id, habit.id);
      expect(fromJson.name, habit.name);
      expect(fromJson.description, habit.description);
      expect(fromJson.upgradeId, habit.upgradeId);
      expect(fromJson.difficulty, habit.difficulty);
      expect(fromJson.currentStreak, habit.currentStreak);
      expect(fromJson.longestStreak, habit.longestStreak);
      expect(fromJson.createdAt, habit.createdAt);
    });

    test('HabitEntry serialization/deserialization', () {
      final entry = HabitEntry(
        id: 'e1',
        habitId: 'h1',
        date: DateTime(2024, 1, 2),
        value: 1.5,
        completed: true,
        note: 'Feeling good',
        mood: 5,
        timestamp: DateTime(2024, 1, 2, 10, 0),
      );

      final json = entry.toJson();
      final fromJson = HabitEntry.fromJson(json);

      expect(fromJson.id, entry.id);
      expect(fromJson.habitId, entry.habitId);
      expect(fromJson.date, entry.date);
      expect(fromJson.value, entry.value);
      expect(fromJson.completed, entry.completed);
      expect(fromJson.note, entry.note);
      expect(fromJson.mood, entry.mood);
      expect(fromJson.timestamp, entry.timestamp);
    });

    test('UserProfile serialization/deserialization', () {
      final profile = UserProfile(
        id: 'p1',
        username: 'coder',
        avatarType: 'minimalist',
        level: 10,
        totalXp: 5000,
        currentStreak: 7,
        longestStreak: 30,
        rank: 'Master',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.id, profile.id);
      expect(fromJson.username, profile.username);
      expect(fromJson.avatarType, profile.avatarType);
      expect(fromJson.level, profile.level);
      expect(fromJson.totalXp, profile.totalXp);
      expect(fromJson.currentStreak, profile.currentStreak);
      expect(fromJson.longestStreak, profile.longestStreak);
      expect(fromJson.rank, profile.rank);
      expect(fromJson.createdAt, profile.createdAt);
    });

    test('UpgradeGroup serialization/deserialization', () {
      final upgrade = UpgradeGroup(
        id: 'u1',
        name: 'Fitness',
        description: 'Get fit',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
        difficulty: 'hard',
        cutoffPercentage: 0.8,
        status: 'active',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = upgrade.toJson();
      final fromJson = UpgradeGroup.fromJson(json);

      expect(fromJson.id, upgrade.id);
      expect(fromJson.name, upgrade.name);
      expect(fromJson.description, upgrade.description);
      expect(fromJson.startDate, upgrade.startDate);
      expect(fromJson.endDate, upgrade.endDate);
      expect(fromJson.difficulty, upgrade.difficulty);
      expect(fromJson.cutoffPercentage, upgrade.cutoffPercentage);
      expect(fromJson.status, upgrade.status);
      expect(fromJson.createdAt, upgrade.createdAt);
    });
   group('Habit default values', () {
      test('Habit.fromJson with minimal data', () {
        final json = {
          'id': 'h2',
          'name': 'Minimal',
          'createdAt': DateTime.now().toIso8601String(),
        };
        final habit = Habit.fromJson(json);
        expect(habit.description, '');
        expect(habit.difficulty, 'medium');
        expect(habit.archived, false);
      });
    });
  });
}
