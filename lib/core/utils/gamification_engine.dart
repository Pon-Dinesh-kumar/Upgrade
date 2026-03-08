import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/entities/upgrade_habit.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/timeline_event.dart';
import '../constants/app_constants.dart';
import 'xp_calculator.dart';
import 'date_utils.dart';

class GamificationEngine {
  final Ref _ref;

  GamificationEngine(this._ref);

  Future<void> completeHabit(Habit habit) async {
    final today = AppDateUtils.today();
    final entry = HabitEntry(
      habitId: habit.id,
      date: today,
      completed: true,
    );
    await _ref.read(habitEntriesProvider.notifier).save(entry);

    final newStreak = await _calculateStreak(habit.id);
    final updatedHabit = habit.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    );
    await _ref.read(habitsProvider.notifier).save(updatedHabit);

    await _checkStreakAchievements(newStreak);
    await _updatePlayerStreak();
  }

  Future<void> evaluateUpgrade(String upgradeId) async {
    await _ref.read(habitEntriesProvider.notifier).load();
    await _ref.read(habitsProvider.notifier).load();
    await _ref.read(upgradesProvider.notifier).load();
    await _ref.read(upgradeHabitsProvider.notifier).load();

    final upgrade = (_ref.read(upgradesProvider).valueOrNull ?? [])
        .where((u) => u.id == upgradeId)
        .firstOrNull;
    if (upgrade == null) return;

    final memberships = (_ref.read(upgradeHabitsProvider).valueOrNull ?? [])
        .where((m) => m.upgradeId == upgradeId)
        .toList();
    final habits = _ref.read(habitsProvider).valueOrNull ?? [];
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];

    final completionScore = XpCalculator.computeUpgradeScore(
      upgrade,
      memberships,
      habits,
      entries,
    );
    final passed = completionScore >= upgrade.cutoffPercentage;
    final activeHabitCount = memberships.where((m) => m.leftDate == null).length;
    final xpEarned = XpCalculator.calculateUpgradeXp(
      upgrade,
      completionScore,
      activeHabitCount,
    );

    final updatedUpgrade = upgrade.copyWith(
      status: passed ? 'completed' : 'failed',
      completionScore: completionScore,
      xpAwarded: xpEarned,
    );
    await _ref.read(upgradesProvider.notifier).save(updatedUpgrade);

    await _ref.read(userProfileProvider.notifier).addXp(xpEarned);

    final profile = _ref.read(userProfileProvider).valueOrNull;
    final oldLevel = profile?.level ?? 1;
    final newLevel = _ref.read(userProfileProvider).valueOrNull?.level ?? 1;

    await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
      type: 'upgrade_evaluated',
      title: passed ? 'Upgrade completed: ${upgrade.name}' : 'Upgrade failed: ${upgrade.name}',
      description: 'Score: ${(completionScore * 100).toStringAsFixed(0)}% — $xpEarned XP',
      linkedEntityId: upgrade.id,
    ));

    if (newLevel > oldLevel) {
      await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
        type: 'level_up',
        title: 'Level Up!',
        description: 'You reached level $newLevel — ${AppConstants.getRank(newLevel)}',
      ));
      await _checkAchievement('first_level_up');
      if (newLevel >= 10) await _checkAchievement('reach_level_10');
    }

    await _checkAchievement('first_upgrade');
  }

  Future<void> evaluateDueUpgrades() async {
    await _ref.read(upgradesProvider.notifier).load();
    final today = AppDateUtils.today();
    final dueUpgrades = (_ref.read(upgradesProvider).valueOrNull ?? [])
        .where((u) =>
            u.status == 'active' &&
            !DateTime(u.endDate.year, u.endDate.month, u.endDate.day).isAfter(today))
        .toList();
    for (final upgrade in dueUpgrades) {
      await evaluateUpgrade(upgrade.id);
    }
  }

  Future<void> addHabitToUpgrade(String habitId, String upgradeId) async {
    final membership = UpgradeHabit(
      upgradeId: upgradeId,
      habitId: habitId,
      joinedDate: AppDateUtils.today(),
    );
    await _ref.read(upgradeHabitsProvider.notifier).save(membership);

    final habits = _ref.read(habitsProvider).valueOrNull ?? [];
    final habit = habits.where((h) => h.id == habitId).firstOrNull;
    if (habit != null) {
      await _ref.read(habitsProvider.notifier).save(habit.copyWith(upgradeId: upgradeId));
    }

    await _checkAchievement('first_upgrade');
  }

  Future<void> removeHabitFromUpgrade(String habitId, String upgradeId) async {
    await _ref.read(upgradeHabitsProvider.notifier).load();
    final memberships = (_ref.read(upgradeHabitsProvider).valueOrNull ?? [])
        .where((m) => m.habitId == habitId && m.upgradeId == upgradeId && m.leftDate == null)
        .toList();
    final membership = memberships.firstOrNull;
    if (membership != null) {
      await _ref.read(upgradeHabitsProvider.notifier).save(
            membership.copyWith(leftDate: AppDateUtils.today()),
          );
    }
  }

  Future<int> _calculateStreak(String habitId) async {
    await _ref.read(habitEntriesProvider.notifier).load();
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];
    final habitEntries = entries
        .where((e) => e.habitId == habitId && e.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (habitEntries.isEmpty) return 0;

    int streak = 1;
    var current = AppDateUtils.today();
    for (int i = 0; i < habitEntries.length; i++) {
      final entryDate = DateTime(
        habitEntries[i].date.year,
        habitEntries[i].date.month,
        habitEntries[i].date.day,
      );
      if (AppDateUtils.isSameDay(entryDate, current)) {
        continue;
      }
      final yesterday = current.subtract(const Duration(days: 1));
      if (AppDateUtils.isSameDay(entryDate, yesterday)) {
        streak++;
        current = yesterday;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _checkAchievement(String key) async {
    final repo = await _ref.read(achievementRepoProvider.future);
    if (await repo.isUnlocked(key)) return;

    final def = Achievement.definitions.where((a) => a.key == key).firstOrNull;
    if (def == null) return;

    await _ref.read(achievementsProvider.notifier).unlock(def);
    await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
      type: 'achievement_unlock',
      title: 'Achievement: ${def.name}',
      description: def.description,
    ));
  }

  Future<void> _checkStreakAchievements(int streak) async {
    if (streak >= 7) await _checkAchievement('7_day_streak');
    if (streak >= 30) await _checkAchievement('30_day_streak');
    if (streak >= 100) await _checkAchievement('100_day_streak');
    if (streak >= 365) await _checkAchievement('365_day_streak');
  }

  Future<void> checkHabitCreationAchievements() async {
    final habits = _ref.read(habitsProvider).valueOrNull ?? [];
    if (habits.isNotEmpty) await _checkAchievement('first_habit');
    if (habits.length >= 10) await _checkAchievement('10_habits');
  }

  Future<void> checkUpgradeCreationAchievements() async {
    final upgrades = _ref.read(upgradesProvider).valueOrNull ?? [];
    if (upgrades.isNotEmpty) await _checkAchievement('first_upgrade');
  }

  Future<void> checkGoalAchievements() async {
    final goals = _ref.read(goalsProvider).valueOrNull ?? [];
    if (goals.isNotEmpty) await _checkAchievement('first_goal');
    if (goals.any((g) => g.status == 'completed')) {
      await _checkAchievement('goal_complete');
    }
  }

  Future<void> _updatePlayerStreak() async {
    final habits = _ref.read(habitsProvider).valueOrNull ?? [];
    if (habits.isEmpty) return;
    final maxStreak = habits.fold<int>(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );
    await _ref.read(userProfileProvider.notifier).updateStreak(maxStreak);
  }
}

final gamificationEngineProvider = Provider<GamificationEngine>((ref) {
  return GamificationEngine(ref);
});
