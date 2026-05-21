import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/entities/upgrade_group.dart';
import '../../../domain/entities/user_profile.dart';

class AchievementProgress {
  final Achievement definition;
  final double progress;
  final String progressLabel;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.definition,
    required this.progress,
    required this.progressLabel,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

class AchievementProgressCalculator {
  AchievementProgressCalculator._();

  static List<AchievementProgress> compute({
    required UserProfile? profile,
    required List<Habit> habits,
    required List<HabitEntry> entries,
    required List<UpgradeGroup> upgrades,
    required List<Goal> goals,
    required Set<String> unlockedKeys,
    required List<Achievement> unlocked,
  }) {
    final completedDays = entries.where((e) => e.completed).length;
    final streak = profile?.currentStreak ?? 0;
    final level = profile?.level ?? 1;
    final habitCount = habits.where((h) => !h.archived).length;
    final hasCompletion = entries.any((e) => e.completed);
    final hasUpgrade = upgrades.isNotEmpty;
    final hasGoal = goals.isNotEmpty;
    final hasCompletedGoal = goals.any((g) => g.status == 'completed');

    final unlockedByKey = {for (final a in unlocked) a.key: a};

    return Achievement.definitions.map((def) {
      final merged = unlockedByKey[def.key] ?? def;
      final isUnlocked = unlockedKeys.contains(def.key);
      final (progress, label) = _progressForKey(
        def.key,
        streak: streak,
        level: level,
        habitCount: habitCount,
        completedDays: completedDays,
        hasCompletion: hasCompletion,
        hasUpgrade: hasUpgrade,
        hasGoal: hasGoal,
        hasCompletedGoal: hasCompletedGoal,
        isUnlocked: isUnlocked,
      );
      return AchievementProgress(
        definition: merged,
        progress: isUnlocked ? 1.0 : progress,
        progressLabel: isUnlocked ? 'Unlocked' : label,
        isUnlocked: isUnlocked,
        unlockedAt: merged.unlockedAt,
      );
    }).toList();
  }

  static AchievementProgress? nextUnlock(List<AchievementProgress> list) {
    final locked = list.where((p) => !p.isUnlocked && p.progress > 0).toList();
    if (locked.isEmpty) {
      final anyLocked = list.where((p) => !p.isUnlocked).toList();
      if (anyLocked.isEmpty) return null;
      return anyLocked.first;
    }
    locked.sort((a, b) => b.progress.compareTo(a.progress));
    return locked.first;
  }

  static (double, String) _progressForKey(
    String key, {
    required int streak,
    required int level,
    required int habitCount,
    required int completedDays,
    required bool hasCompletion,
    required bool hasUpgrade,
    required bool hasGoal,
    required bool hasCompletedGoal,
    required bool isUnlocked,
  }) {
    if (isUnlocked) return (1.0, 'Unlocked');

    switch (key) {
      case '7_day_streak':
        return _ratio(streak, 7, 'days');
      case '30_day_streak':
        return _ratio(streak, 30, 'days');
      case '100_day_streak':
        return _ratio(streak, 100, 'days');
      case '365_day_streak':
        return _ratio(streak, 365, 'days');
      case '10_habits':
        return _ratio(habitCount, 10, 'habits');
      case 'reach_level_10':
        return _ratio(level, 10, 'level');
      case 'first_habit':
        return (habitCount > 0 ? 1.0 : 0.0, habitCount > 0 ? '1 / 1' : '0 / 1');
      case 'first_completion':
        return (hasCompletion ? 1.0 : 0.0, hasCompletion ? '1 / 1' : '0 / 1');
      case 'first_upgrade':
        return (hasUpgrade ? 1.0 : 0.0, hasUpgrade ? '1 / 1' : '0 / 1');
      case 'first_goal':
        return (hasGoal ? 1.0 : 0.0, hasGoal ? '1 / 1' : '0 / 1');
      case 'goal_complete':
        return (hasCompletedGoal ? 1.0 : 0.0, hasCompletedGoal ? '1 / 1' : '0 / 1');
      case 'first_level_up':
        return _ratio(level.clamp(0, 2), 2, 'level');
      default:
        return (0.0, '—');
    }
  }

  static (double, String) _ratio(int current, int target, String unit) {
    if (target <= 0) return (0.0, '0 / 0');
    final clamped = current.clamp(0, target);
    return (clamped / target, '$clamped / $target $unit');
  }
}
