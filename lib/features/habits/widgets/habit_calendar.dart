import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/habit_entry.dart';

class HabitCalendar extends StatelessWidget {
  final List<HabitEntry> entries;

  const HabitCalendar({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final last30 = AppDateUtils.getLast30Days();
    final completedDates = entries
        .where((e) => e.completed)
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Last 30 Days', style: theme.textTheme.titleMedium),
            Row(
              children: [
                _LegendDot(color: AppColors.green, label: 'Done'),
                const SizedBox(width: 12),
                _LegendDot(color: theme.dividerColor, label: 'Missed'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 10;
            const spacing = 4.0;
            final cellSize =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(last30.length, (i) {
                final day = last30[i];
                final done = completedDates.contains(day);
                final isToday = AppDateUtils.isSameDay(day, DateTime.now());

                return Tooltip(
                  message:
                      '${AppDateUtils.formatShortDate(day)}${done ? ' - Completed' : ''}',
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.green
                          : theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(color: AppColors.blue, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: cellSize * 0.32,
                          fontWeight:
                              isToday ? FontWeight.w600 : FontWeight.w400,
                          color: done
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
