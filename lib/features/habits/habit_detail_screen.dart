import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/streak_flame.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import 'widgets/habit_calendar.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final entriesAsync = ref.watch(habitEntriesProvider);
    final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final theme = Theme.of(context);

    return habitsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (habits) {
        final habit = habits.where((h) => h.id == habitId).firstOrNull;
        if (habit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Habit not found')),
          );
        }

        final allEntries = entriesAsync.valueOrNull ?? [];
        final entries = allEntries
            .where((e) => e.habitId == habitId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final upgrade = upgrades
            .where((u) => u.id == habit.upgradeId)
            .firstOrNull;

        final displayColor = upgrade != null
            ? Color(upgrade.color)
            : Color(habit.color);
        final diffColor = AppColors.difficultyColors[habit.difficulty] ??
            AppColors.blue;

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () =>
                    context.go('/habits/${habit.id}/edit'),
              ),
              IconButton(
                icon: Icon(habit.archived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded),
                tooltip: habit.archived ? 'Unarchive' : 'Archive',
                onPressed: () async {
                  await ref
                      .read(habitsProvider.notifier)
                      .toggleArchive(habit.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(habit.archived
                            ? 'Habit unarchived'
                            : 'Habit archived'),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: AppColors.red),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref, habit),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HabitHeader(
                    habit: habit,
                    diffColor: diffColor,
                    displayColor: displayColor,
                    upgrade: upgrade)
                    .animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 16),
                CardShell(
                  child: HabitCalendar(entries: entries),
                ).animate().fadeIn(duration: 250.ms, delay: 50.ms),
                const SizedBox(height: 16),
                _StatsGrid(habit: habit, entries: entries)
                    .animate().fadeIn(duration: 250.ms, delay: 100.ms),
                const SizedBox(height: 16),
                _WeeklyChart(entries: entries)
                    .animate().fadeIn(duration: 250.ms, delay: 150.ms),
                const SizedBox(height: 16),
                _RecentEntries(entries: entries.take(10).toList())
                    .animate().fadeIn(duration: 250.ms, delay: 200.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
            'Are you sure you want to delete "${habit.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(habitsProvider.notifier).delete(habit.id);
              if (context.mounted) context.go('/habits');
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _HabitHeader extends StatelessWidget {
  final Habit habit;
  final Color diffColor;
  final Color displayColor;
  final dynamic upgrade;

  const _HabitHeader({
    required this.habit,
    required this.diffColor,
    required this.displayColor,
    this.upgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CardShell(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: displayColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: theme.textTheme.headlineSmall),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(habit.description, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _tag(
                      habit.difficulty[0].toUpperCase() +
                          habit.difficulty.substring(1),
                      diffColor,
                    ),
                    _tag(
                      habit.frequency[0].toUpperCase() +
                          habit.frequency.substring(1),
                      AppColors.blue,
                    ),
                    if (upgrade != null)
                      GestureDetector(
                        onTap: () =>
                            GoRouter.of(context).go('/upgrades/${upgrade.id}'),
                        child: _tag(upgrade.name as String, displayColor),
                      ),
                    if (habit.targetValue != null && habit.unit != null)
                      _tag(
                        '${habit.targetValue!.toStringAsFixed(habit.targetValue! == habit.targetValue!.roundToDouble() ? 0 : 1)} ${habit.unit}',
                        AppColors.amber,
                      ),
                  ],
                ),
              ],
            ),
          ),
          StreakFlame(streak: habit.currentStreak, size: 24),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Habit habit;
  final List<HabitEntry> entries;

  const _StatsGrid({required this.habit, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedEntries = entries.where((e) => e.completed).toList();
    final totalCompletions = completedEntries.length;

    final daysSinceCreated =
        DateTime.now().difference(habit.createdAt).inDays + 1;
    final completionRate = daysSinceCreated > 0
        ? (totalCompletions / daysSinceCreated).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department_rounded,
                label: 'Current Streak',
                value: '${habit.currentStreak}',
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_rounded,
                label: 'Longest Streak',
                value: '${habit.longestStreak}',
                color: AppColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_rounded,
                label: 'Completions',
                value: '$totalCompletions',
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_today_rounded,
                label: 'Days Tracked',
                value: '$daysSinceCreated',
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CardShell(
          child: Row(
            children: [
              ProgressRing(
                progress: completionRate,
                size: 48,
                strokeWidth: 5,
                color: AppColors.green,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Completion Rate', style: theme.textTheme.titleMedium),
                  Text(
                    '${(completionRate * 100).toStringAsFixed(1)}% over $daysSinceCreated days',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: color),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<HabitEntry> entries;
  const _WeeklyChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekData = <int, int>{};

    for (var w = 0; w < 4; w++) {
      weekData[w] = 0;
    }

    for (final entry in entries.where((e) => e.completed)) {
      final daysAgo = now.difference(entry.date).inDays;
      if (daysAgo < 0 || daysAgo >= 28) continue;
      final weekIndex = 3 - (daysAgo ~/ 7);
      weekData[weekIndex] = (weekData[weekIndex] ?? 0) + 1;
    }

    final maxVal = weekData.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 7.0 : (maxVal + 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Completions', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        CardShell(
          child: SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} done',
                        TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            '${value.toInt()}',
                            style: theme.textTheme.bodySmall,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['3w ago', '2w ago', 'Last wk', 'This wk'];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[idx],
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (weekData[i] ?? 0).toDouble(),
                        color: AppColors.blue,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.blue.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentEntries extends StatelessWidget {
  final List<HabitEntry> entries;
  const _RecentEntries({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final today = AppDateUtils.today();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Entries', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...entries.map((entry) {
          final moodEmoji = entry.mood != null
              ? AppConstants.moodEmojis[entry.mood] ?? ''
              : '';
          final entryDay = DateTime(entry.date.year, entry.date.month, entry.date.day);
          final isPast = entryDay.isBefore(today);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CardShell(
              child: Row(
                children: [
                  Icon(
                    entry.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: entry.completed
                        ? AppColors.green
                        : theme.dividerColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateUtils.formatDate(entry.date),
                          style: theme.textTheme.titleMedium,
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Text(entry.note!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (entry.value != 1.0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        entry.value.toStringAsFixed(
                            entry.value == entry.value.roundToDouble()
                                ? 0
                                : 1),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppColors.blue),
                      ),
                    ),
                  if (moodEmoji.isNotEmpty)
                    Text(moodEmoji, style: const TextStyle(fontSize: 18)),
                  if (isPast)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.lock_rounded,
                          size: 14, color: theme.disabledColor),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
