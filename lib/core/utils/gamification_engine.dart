import 'dart:math';
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
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];

    await _clearTodayEntry(habit.id, today, entries);

    final alreadyDone = entries.any((e) =>
        e.habitId == habit.id &&
        AppDateUtils.isSameDay(e.date, today) &&
        e.completed);

    final entry = HabitEntry(
      habitId: habit.id,
      date: today,
      completed: true,
      failed: false,
    );
    await _ref.read(habitEntriesProvider.notifier).save(entry);

    final newStreak = await _calculateStreak(habit.id);
    final updatedHabit = habit.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
    );
    await _ref.read(habitsProvider.notifier).save(updatedHabit);

    // Only grant XP if this is the FIRST completion of the day
    if (!alreadyDone) {
      final xpBase = AppConstants.xpByDifficulty[habit.difficulty] ?? 10;
      final streakBonus = (xpBase * (min(newStreak - 1, 10) * 0.1)).floor();
      final totalXp = xpBase + streakBonus;
      
      await _ref.read(userProfileProvider.notifier).addXp(totalXp);
      
      // Log XP gain to timeline
      await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
        type: 'habit_completion',
        title: 'Habit Completed',
        description: '${habit.name} (+$totalXp XP)',
        linkedEntityId: habit.id,
      ));
    }

    await _checkAchievement('first_completion');
    await _checkStreakAchievements(newStreak);
    await _updatePlayerStreak();
  }

  /// Mark habit as failed for today (or this week) — can be done any time of day.
  Future<void> failHabit(Habit habit) async {
    final today = AppDateUtils.today();
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];

    final existing = entries
        .where((e) => e.habitId == habit.id && AppDateUtils.isSameDay(e.date, today))
        .firstOrNull;
    if (existing?.failed == true && existing?.completed != true) return;

    if (existing != null) {
      if (existing.completed) {
        await uncompleteHabit(habit, existing.id);
        await _ref.read(habitEntriesProvider.future);
      } else {
        await _ref.read(habitEntriesProvider.notifier).delete(existing.id);
      }
    }

    await _ref.read(habitEntriesProvider.notifier).save(
          HabitEntry(
            habitId: habit.id,
            date: today,
            completed: false,
            failed: true,
          ),
        );

    final newStreak = await _calculateStreak(habit.id);
    await _ref.read(habitsProvider.notifier).save(
          habit.copyWith(currentStreak: newStreak),
        );

    await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
      type: 'habit_failed',
      title: 'Habit missed',
      description: habit.name,
      linkedEntityId: habit.id,
    ));

    await _updatePlayerStreak();
  }

  /// Clear pass/fail for today so the habit is pending again.
  Future<void> resetHabitDay(Habit habit) async {
    final today = AppDateUtils.today();
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];
    final existing = entries
        .where((e) => e.habitId == habit.id && AppDateUtils.isSameDay(e.date, today))
        .firstOrNull;
    if (existing == null) return;

    if (existing.completed) {
      await uncompleteHabit(habit, existing.id);
    } else {
      await _ref.read(habitEntriesProvider.notifier).delete(existing.id);
      final newStreak = await _calculateStreak(habit.id);
      await _ref.read(habitsProvider.notifier).save(
            habit.copyWith(currentStreak: newStreak),
          );
      await _updatePlayerStreak();
    }
  }

  Future<void> _clearTodayEntry(
    String habitId,
    DateTime today,
    List<HabitEntry> entries,
  ) async {
    final existing = entries
        .where((e) => e.habitId == habitId && AppDateUtils.isSameDay(e.date, today))
        .firstOrNull;
    if (existing != null) {
      await _ref.read(habitEntriesProvider.notifier).delete(existing.id);
    }
  }

  Future<void> uncompleteHabit(Habit habit, String entryId) async {
    // Calculate how much XP was awarded for this habit today
    final currentStreak = await _calculateStreak(habit.id);
    final xpBase = AppConstants.xpByDifficulty[habit.difficulty] ?? 10;
    final streakBonus = (xpBase * (min(currentStreak - 1, 10) * 0.1)).floor();
    final totalXpAwarded = xpBase + streakBonus;

    // Delete the entry
    await _ref.read(habitEntriesProvider.notifier).delete(entryId);

    // Subtract the XP
    await _ref.read(userProfileProvider.notifier).addXp(-totalXpAwarded);

    // Log XP loss to timeline
    await _ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
      type: 'habit_completion',
      title: 'Habit Uncompleted',
      description: '${habit.name} (-$totalXpAwarded XP)',
      linkedEntityId: habit.id,
    ));

    // Update streak for the habit
    final newStreak = await _calculateStreak(habit.id);
    final updatedHabit = habit.copyWith(
      currentStreak: newStreak,
      // Note: longestStreak doesn't decrease
    );
    await _ref.read(habitsProvider.notifier).save(updatedHabit);

    await _updatePlayerStreak();
  }

  Future<void> evaluateUpgrade(String upgradeId) async {
    await _ref.read(habitEntriesProvider.future);
    await _ref.read(habitsProvider.future);
    await _ref.read(upgradesProvider.future);
    await _ref.read(upgradeHabitsProvider.future);

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
    await _ref.read(upgradesProvider.future);
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
    await _ref.read(upgradeHabitsProvider.future);
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
    await _ref.read(habitEntriesProvider.future);
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? [];
    var day = AppDateUtils.today();
    int streak = 0;

    while (true) {
      final dayEntry = entries
          .where((e) =>
              e.habitId == habitId &&
              AppDateUtils.isSameDay(e.date, day))
          .firstOrNull;

      if (dayEntry?.failed == true) break;
      if (dayEntry?.completed == true) {
        streak++;
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      if (AppDateUtils.isSameDay(day, AppDateUtils.today())) {
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      break;
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
