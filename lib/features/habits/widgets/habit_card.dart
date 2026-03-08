import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/card_shell.dart';
import '../../../core/widgets/streak_flame.dart';
import '../../../domain/entities/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final String? upgradeName;
  final Color? upgradeColor;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.upgradeName,
    this.upgradeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor =
        AppColors.difficultyColors[habit.difficulty] ?? AppColors.blue;
    final displayColor = upgradeColor ?? Color(habit.color);
    final theme = Theme.of(context);

    return CardShell(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: displayColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(habit.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: displayColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  habit.name,
                                  style: theme.textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (habit.archived) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.archive_rounded,
                                    size: 14,
                                    color: theme.textTheme.bodySmall?.color),
                              ],
                            ],
                          ),
                          if (habit.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              habit.description,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _NotionTag(
                                label: habit.difficulty[0].toUpperCase() +
                                    habit.difficulty.substring(1),
                                color: diffColor,
                              ),
                              if (upgradeName != null)
                                _NotionTag(
                                  label: upgradeName!,
                                  color: displayColor,
                                ),
                              if (habit.frequency != 'daily')
                                _NotionTag(
                                  label: habit.frequency,
                                  color: AppColors.blue,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreakFlame(streak: habit.currentStreak, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotionTag extends StatelessWidget {
  final String label;
  final Color color;
  const _NotionTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
