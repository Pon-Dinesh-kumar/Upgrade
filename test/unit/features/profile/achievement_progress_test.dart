import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/domain/entities/achievement.dart';
import 'package:upgrade/domain/entities/user_profile.dart';
import 'package:upgrade/features/profile/logic/achievement_progress.dart';

void main() {
  group('AchievementProgressCalculator', () {
    test('computes 7-day streak progress', () {
      final profile = UserProfile(username: 'Test', currentStreak: 5);
      final list = AchievementProgressCalculator.compute(
        profile: profile,
        habits: const [],
        entries: const [],
        upgrades: const [],
        goals: const [],
        unlockedKeys: {},
        unlocked: const [],
      );

      final seven = list.firstWhere((p) => p.definition.key == '7_day_streak');
      expect(seven.progress, closeTo(5 / 7, 0.01));
      expect(seven.progressLabel, '5 / 7 days');
      expect(seven.isUnlocked, false);
    });

    test('marks unlocked achievements at 100%', () {
      final profile = UserProfile(username: 'Test');
      final unlocked = [
        Achievement(
          key: 'first_completion',
          name: 'Getting Started',
          description: 'Done',
          unlockedAt: DateTime(2026, 1, 1),
        ),
      ];
      final list = AchievementProgressCalculator.compute(
        profile: profile,
        habits: const [],
        entries: const [],
        upgrades: const [],
        goals: const [],
        unlockedKeys: {'first_completion'},
        unlocked: unlocked,
      );

      final item = list.firstWhere((p) => p.definition.key == 'first_completion');
      expect(item.isUnlocked, true);
      expect(item.progress, 1.0);
      expect(item.unlockedAt, isNotNull);
    });

    test('nextUnlock picks highest progress locked item', () {
      final profile = UserProfile(username: 'Test', currentStreak: 5, level: 1);
      final list = AchievementProgressCalculator.compute(
        profile: profile,
        habits: const [],
        entries: const [],
        upgrades: const [],
        goals: const [],
        unlockedKeys: {},
        unlocked: const [],
      );

      final next = AchievementProgressCalculator.nextUnlock(list);
      expect(next, isNotNull);
      expect(next!.definition.key, '7_day_streak');
    });
  });
}
