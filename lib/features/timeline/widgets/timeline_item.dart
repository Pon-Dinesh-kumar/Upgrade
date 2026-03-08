import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo_icon.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/timeline_event.dart';

class TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  static const _typeConfig = <String, ({IconData icon, Color color, bool useAppLogo})>{
    'habit_complete': (icon: Icons.check_circle, color: AppColors.green, useAppLogo: false),
    'streak_milestone': (
      icon: Icons.local_fire_department,
      color: AppColors.amber,
      useAppLogo: false
    ),
    'level_up': (icon: Icons.arrow_upward, color: AppColors.blue, useAppLogo: false),
    'upgrade_level_up': (icon: Icons.rocket_launch, color: AppColors.blue, useAppLogo: true),
    'achievement_unlock': (
      icon: Icons.emoji_events,
      color: AppColors.amber,
      useAppLogo: false
    ),
    'goal_complete': (icon: Icons.flag_rounded, color: AppColors.green, useAppLogo: false),
  };

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig[event.type] ??
        (icon: Icons.circle, color: AppColors.blue, useAppLogo: false);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: config.color, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  config.useAppLogo
                      ? AppLogoIcon(size: 16, color: config.color)
                      : Icon(config.icon, size: 16, color: config.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppDateUtils.formatRelative(event.timestamp),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
