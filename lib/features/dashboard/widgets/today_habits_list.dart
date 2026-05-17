import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo_icon.dart';
import '../../../core/widgets/card_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/utils/gamification_engine.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/habit.dart';

class TodayHabitsList extends ConsumerWidget {
  const TodayHabitsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final allUpgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final theme = Theme.of(context);

    return habitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (allHabits) {
        // Filter habits for today directly from allHabits
        final todayHabits = allHabits.where((h) {
          if (h.archived) return false;
          return AppDateUtils.shouldCompleteToday(h.frequency, h.frequencyConfig);
        }).toList();

        final allActiveHabits = allHabits.where((h) => !h.archived).toList();

        if (allActiveHabits.isEmpty) {
          return const AppEmptyState(
            icon: Icons.emoji_nature_rounded,
            title: 'No habits yet',
            subtitle: 'Tap + to create your first habit or check your schedule.',
          );
        }

        final habitsToShow = todayHabits.isNotEmpty ? todayHabits : allActiveHabits;
        final isShowingAll = todayHabits.isEmpty && allActiveHabits.isNotEmpty;

        final completedIds = entries.where((e) => e.completed).map((e) => e.habitId).toSet();
        final upgradeMap = <String, ({String name, int color})>{};
        for (final u in allUpgrades) {
          upgradeMap[u.id] = (name: u.name, color: u.color);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isShowingAll ? "Your Habits" : "Today's Habits",
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                if (!isShowingAll)
                  Text(
                    '${completedIds.length}/${todayHabits.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (isShowingAll)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  "No habits scheduled for today, but here's your list:",
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              const SizedBox(height: 12),
            ...habitsToShow.asMap().entries.map((entry) {
              final habit = entry.value;
              final isDone = completedIds.contains(habit.id);
              final upgradeInfo = upgradeMap[habit.upgradeId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HabitCard(
                  key: ValueKey('today-habit-${habit.id}'),
                  habit: habit,
                  isDone: isDone,
                  upgradeName: upgradeInfo?.name,
                  upgradeColor: upgradeInfo != null ? Color(upgradeInfo.color) : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isDone;
  final String? upgradeName;
  final Color? upgradeColor;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.isDone,
    this.upgradeName,
    this.upgradeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficultyColor =
        AppColors.difficultyColors[habit.difficulty] ?? AppColors.blue;
    final displayColor = upgradeColor ?? Color(habit.color);
    final theme = Theme.of(context);

    return CardShell(
      borderColor: isDone ? AppColors.green.withValues(alpha: 0.4) : displayColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => GoRouter.of(context).go('/habits/${habit.id}'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.green.withValues(alpha: 0.1)
                  : displayColor.withValues(alpha: 0.1),
              border: Border.all(
                color: isDone
                    ? AppColors.green.withValues(alpha: 0.3)
                    : displayColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
              size: 20,
              color: isDone ? AppColors.green : displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isDone
                        ? theme.textTheme.bodySmall?.color
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(
                      label: habit.difficulty[0].toUpperCase() +
                          habit.difficulty.substring(1),
                      color: difficultyColor,
                    ),
                    if (upgradeName != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: _Tag(
                          label: upgradeName!,
                          color: displayColor,
                          iconWidget: AppLogoIcon(size: 10, color: displayColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleCompletion(context, ref),
            child: _CheckCircle(isDone: isDone),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompletion(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(todayEntriesProvider);

    if (isDone) {
      final entry = entries.firstWhere(
        (e) => e.habitId == habit.id && e.completed,
      );
      HapticFeedback.lightImpact();
      await ref.read(habitEntriesProvider.notifier).delete(entry.id);
    } else {
      HapticFeedback.mediumImpact();
      await ref.read(gamificationEngineProvider).completeHabit(habit);
      await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final Widget? iconWidget;
  const _Tag({required this.label, required this.color, this.icon, this.iconWidget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null) ...[
            iconWidget!,
            const SizedBox(width: 3),
          ] else if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool isDone;
  const _CheckCircle({required this.isDone});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDone
        ? AppColors.green
        : Theme.of(context).dividerColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? AppColors.green : Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
