import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/card_shell.dart';
import '../../../domain/entities/upgrade_group.dart';

class UpgradeCard extends StatelessWidget {
  final UpgradeGroup upgrade;
  final int habitCount;
  final double liveScore;
  final VoidCallback onTap;

  const UpgradeCard({
    super.key,
    required this.upgrade,
    required this.habitCount,
    required this.liveScore,
    required this.onTap,
  });

  Color get _statusColor {
    switch (upgrade.status) {
      case 'completed':
        return AppColors.green;
      case 'failed':
        return AppColors.red;
      default:
        return AppColors.blue;
    }
  }

  String get _statusLabel {
    switch (upgrade.status) {
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Active';
    }
  }

  Color get _difficultyColor {
    switch (upgrade.difficulty) {
      case 'easy':
        return AppColors.green;
      case 'hard':
        return AppColors.amber;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgradeColor = Color(upgrade.color);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final displayScore =
        upgrade.status != 'active' && upgrade.completionScore != null
            ? upgrade.completionScore!
            : liveScore;

    return CardShell(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: upgradeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: upgradeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            IconData(upgrade.iconCodePoint, fontFamily: 'MaterialIcons'),
                            color: upgradeColor,
                            size: 24,
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
                                  Expanded(
                                    child: Text(
                                      upgrade.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _StatusBadge(label: _statusLabel, color: _statusColor),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _IconInfo(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: '$habitCount habits',
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 12),
                                  _IconInfo(
                                    icon: Icons.analytics_outlined,
                                    label: '${(displayScore * 100).toStringAsFixed(0)}%',
                                    color: _statusColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _IconInfo(
                                    icon: Icons.calendar_today_rounded,
                                    label: '${upgrade.startDate.month}/${upgrade.startDate.day} - ${upgrade.endDate.month}/${upgrade.endDate.day}',
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FlatProgressBar(
                      score: displayScore,
                      cutoff: upgrade.cutoffPercentage,
                      color: upgradeColor,
                      trackColor: trackColor,
                    ),
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

class _FlatProgressBar extends StatelessWidget {
  final double score;
  final double cutoff;
  final Color color;
  final Color trackColor;

  const _FlatProgressBar({
    required this.score,
    required this.cutoff,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: score.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _IconInfo({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  final Color color;

  const _DifficultyBadge({required this.difficulty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppConstants.upgradeImpactLabels[difficulty] ?? difficulty,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final double score;
  final double cutoff;
  final Color color;
  final String status;

  const _ScoreBar({
    required this.score,
    required this.cutoff,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = status == 'failed'
        ? AppColors.red
        : status == 'completed'
            ? AppColors.green
            : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: score.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width * cutoff.clamp(0.0, 1.0)) - 0.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DaysRemainingChip extends StatelessWidget {
  final DateTime endDate;

  const _DaysRemainingChip({required this.endDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final remaining = end.difference(today).inDays;
    final isOverdue = remaining < 0;
    final label = isOverdue
        ? 'Overdue'
        : remaining == 0
            ? 'Ends today'
            : '$remaining d left';
    final color = isOverdue ? AppColors.red : AppColors.blue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
