import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/entities/upgrade_group.dart';
import 'swipeable_habit_card.dart';

Widget _habitGestureLegend(ThemeData theme) {
  return Text(
    'Swipe right · done   Swipe left · missed   Tap · open   Long press · reset',
    style: theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
    ),
  );
}

class TodayHabitsList extends ConsumerWidget {
  final String? upgradeId;
  const TodayHabitsList({super.key, this.upgradeId});

  static HabitDayStatus _statusFor(
    Habit habit,
    List<HabitEntry> todayEntries,
    List<HabitEntry> weekEntries,
  ) {
    final pool = habit.frequency == 'weekly' ? weekEntries : todayEntries;
    final forHabit = pool.where((e) => e.habitId == habit.id);
    if (forHabit.any((e) => e.completed)) return HabitDayStatus.passed;
    if (forHabit.any((e) => e.failed)) return HabitDayStatus.failed;
    return HabitDayStatus.pending;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final todayEntries = ref.watch(todayEntriesProvider);
    final weekEntries = ref.watch(thisWeekEntriesProvider);
    final allUpgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final theme = Theme.of(context);

    return habitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (allHabits) {
        final upgradeMap = <String, UpgradeGroup>{};
        for (final u in allUpgrades) {
          upgradeMap[u.id] = u;
        }

        final completedTodayIds =
            todayEntries.where((e) => e.completed).map((e) => e.habitId).toSet();
        final completedThisWeekIds =
            weekEntries.where((e) => e.completed).map((e) => e.habitId).toSet();
        final failedTodayIds =
            todayEntries.where((e) => e.failed).map((e) => e.habitId).toSet();
        final failedWeekIds =
            weekEntries.where((e) => e.failed).map((e) => e.habitId).toSet();

        final todayHabits = allHabits.where((h) {
          if (h.archived) return false;
          if (upgradeId != null && h.upgradeId != upgradeId) return false;

          final parentUpgrade = upgradeMap[h.upgradeId];
          if (parentUpgrade != null && parentUpgrade.archived) return false;

          if (h.frequency == 'weekly') {
            final doneThisWeek = completedThisWeekIds.contains(h.id);
            final doneToday = completedTodayIds.contains(h.id);
            final failedThisWeek = failedWeekIds.contains(h.id);
            final failedToday = failedTodayIds.contains(h.id);
            if (failedThisWeek || failedToday) return true;
            return !doneThisWeek || doneToday;
          }

          if (failedTodayIds.contains(h.id)) return true;
          return AppDateUtils.shouldCompleteToday(h.frequency, h.frequencyConfig);
        }).toList();

        final allActiveHabits = allHabits.where((h) {
          if (h.archived) return false;
          if (upgradeId != null && h.upgradeId != upgradeId) return false;
          final parentUpgrade = upgradeMap[h.upgradeId];
          if (parentUpgrade != null && parentUpgrade.archived) return false;
          return true;
        }).toList();

        if (allActiveHabits.isEmpty) {
          return const AppEmptyState(
            icon: Icons.emoji_nature_rounded,
            title: 'No habits yet',
            subtitle: 'Tap + to create your first habit or check your schedule.',
          );
        }

        final habitsToShow = todayHabits.isNotEmpty ? todayHabits : allActiveHabits;
        final isShowingAll = todayHabits.isEmpty && allActiveHabits.isNotEmpty;

        final passedCount = habitsToShow
            .where((h) =>
                _statusFor(h, todayEntries, weekEntries) == HabitDayStatus.passed)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isShowingAll ? 'Active Habits' : "Today's Habits",
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '$passedCount/${habitsToShow.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: passedCount == habitsToShow.length &&
                            habitsToShow.isNotEmpty
                        ? AppColors.green
                        : null,
                  ),
                ),
              ],
            ),
            if (isShowingAll)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No habits scheduled for today. Showing all active habits:',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    _habitGestureLegend(theme),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: _habitGestureLegend(theme),
              ),
            ...habitsToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final habit = entry.value;
              final status = _statusFor(habit, todayEntries, weekEntries);
              final upgradeInfo = upgradeMap[habit.upgradeId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SwipeableHabitCard(
                  key: ValueKey('today-habit-${habit.id}'),
                  index: index + 1,
                  habit: habit,
                  status: status,
                  upgradeName: upgradeInfo?.name,
                  upgradeColor:
                      upgradeInfo != null ? Color(upgradeInfo.color) : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
