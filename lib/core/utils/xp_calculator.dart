import 'dart:math';
import '../constants/app_constants.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/entities/upgrade_group.dart';
import '../../domain/entities/upgrade_habit.dart';

class XpCalculator {
  XpCalculator._();

  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 100;
    return max(100, (100 * pow(level, 1.5)).floor());
  }

  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpRequiredForLevel(i);
    }
    return total;
  }

  static int levelFromTotalXp(int totalXp) {
    int level = 1;
    int accumulated = 0;
    while (true) {
      final needed = xpRequiredForLevel(level);
      if (accumulated + needed > totalXp) break;
      accumulated += needed;
      level++;
    }
    return level;
  }

  static double progressToNextLevel(int totalXp) {
    final level = levelFromTotalXp(totalXp);
    int accumulated = 0;
    for (int i = 1; i < level; i++) {
      accumulated += xpRequiredForLevel(i);
    }
    final xpInCurrentLevel = totalXp - accumulated;
    final xpNeeded = xpRequiredForLevel(level);
    return xpNeeded > 0 ? (xpInCurrentLevel / xpNeeded).clamp(0.0, 1.0) : 0.0;
  }

  static int countScheduledDays(
    DateTime windowStart,
    DateTime windowEnd,
    String frequency,
    String? frequencyConfig,
  ) {
    if (windowStart.isAfter(windowEnd)) return 0;

    final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final startDate = DateTime(windowStart.year, windowStart.month, windowStart.day);
    var endDate = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
    if (endDate.isAfter(todayDate)) {
      endDate = todayDate;
    }

    switch (frequency) {
      case 'daily':
        return endDate.difference(startDate).inDays + 1;
      case 'weekly':
        int count = 0;
        var current = startDate;
        while (!current.isAfter(endDate)) {
          if (current.weekday == DateTime.monday) count++;
          current = current.add(const Duration(days: 1));
        }
        return count;
      case 'custom':
        final weekdays = frequencyConfig
            ?.split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList() ??
            [DateTime.monday];
        int count = 0;
        var current = startDate;
        while (!current.isAfter(endDate)) {
          if (weekdays.contains(current.weekday)) count++;
          current = current.add(const Duration(days: 1));
        }
        return count;
      default:
        return endDate.difference(startDate).inDays + 1;
    }
  }

  static int countCompletedEntries(
    String habitId,
    DateTime windowStart,
    DateTime windowEnd,
    List<HabitEntry> allEntries,
  ) {
    final startDate = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final endDate = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
    return allEntries.where((e) {
      if (e.habitId != habitId || !e.completed) return false;
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }).length;
  }

  static double computeUpgradeScore(
    UpgradeGroup upgrade,
    List<UpgradeHabit> memberships,
    List<Habit> habits,
    List<HabitEntry> entries,
  ) {
    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final membership in memberships) {
      final habit = habits.where((h) => h.id == membership.habitId).firstOrNull;
      if (habit == null) continue;

      final weight = AppConstants.difficultyWeights[habit.difficulty] ?? 3;
      var windowStart = membership.joinedDate;
      var windowEnd = membership.leftDate ?? upgrade.endDate;
      if (windowEnd.isAfter(todayDate)) {
        windowEnd = todayDate;
      }

      final applicableDays = countScheduledDays(
        windowStart,
        windowEnd,
        habit.frequency,
        habit.frequencyConfig,
      );
      if (applicableDays == 0) continue;

      final completedDays = countCompletedEntries(
        habit.id,
        windowStart,
        windowEnd,
        entries,
      );
      final habitScore = (completedDays / applicableDays).clamp(0.0, 1.0);
      totalWeightedScore += habitScore * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;
  }

  static int calculateUpgradeXp(
    UpgradeGroup upgrade,
    double completionScore,
    int activeHabitCount,
  ) {
    final base = AppConstants.upgradeBaseXp[upgrade.difficulty] ?? 500;
    final habitBonus = 1.0 + (max(activeHabitCount, 1) - 1) * 0.1;
    final performanceMul = completionScore;
    var xpEarned = (base * habitBonus * performanceMul).floor();
    final passed = completionScore >= upgrade.cutoffPercentage;

    if (passed && completionScore > upgrade.cutoffPercentage) {
      final denom = 1.0 - upgrade.cutoffPercentage;
      final overachievement =
          denom > 0 ? (completionScore - upgrade.cutoffPercentage) / denom : 0.0;
      xpEarned += (base * 0.2 * overachievement).floor();
    }

    if (!passed) {
      xpEarned = (xpEarned * 0.5).floor();
    }

    return xpEarned;
  }
}
