import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo_icon.dart';
import '../../../core/widgets/card_shell.dart';
import '../../../core/utils/gamification_engine.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/habit.dart';

class TodayHabitsList extends ConsumerWidget {
  const TodayHabitsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(todayHabitsProvider);
    final entries = ref.watch(todayEntriesProvider);
    final allUpgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final completedIds =
        entries.where((e) => e.completed).map((e) => e.habitId).toSet();
    final theme = Theme.of(context);

    if (habits.isEmpty) {
      return _EmptyState();
    }

    final upgradeMap = <String, ({String name, int color})>{};
    for (final u in allUpgrades) {
      upgradeMap[u.id] = (name: u.name, color: u.color);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Today's Habits", style: theme.textTheme.headlineSmall),
            const Spacer(),
            Text(
              '${completedIds.length}/${habits.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          final isDone = completedIds.contains(habit.id);
          final upgradeInfo = upgradeMap[habit.upgradeId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HabitCard(
              habit: habit,
              isDone: isDone,
              upgradeName: upgradeInfo?.name,
              upgradeColor: upgradeInfo != null ? Color(upgradeInfo.color) : null,
            ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * index),
                duration: 250.ms),
          );
        }),
      ],
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isDone;
  final String? upgradeName;
  final Color? upgradeColor;

  const _HabitCard({
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.emoji_nature_rounded,
            size: 40,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 12),
          Text(
            'No habits yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to create your first habit',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
