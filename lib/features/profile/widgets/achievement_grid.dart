import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/achievement.dart';
import '../logic/achievement_progress.dart';

class AchievementGrid extends StatelessWidget {
  final List<AchievementProgress> progressList;

  const AchievementGrid({super.key, required this.progressList});

  @override
  Widget build(BuildContext context) {
    final sorted = [...progressList]..sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        if (!a.isUnlocked && !b.isUnlocked) {
          return b.progress.compareTo(a.progress);
        }
        return 0;
      });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        return _AchievementTile(progress: item);
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementProgress progress;

  const _AchievementTile({required this.progress});

  void _showSheet(BuildContext context) {
    final def = progress.definition;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _AchievementIcon(
              definition: def,
              isUnlocked: progress.isUnlocked,
              ringProgress: progress.isUnlocked ? 1.0 : progress.progress,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              def.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              def.description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!progress.isUnlocked) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress.progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor:
                            theme.dividerColor.withValues(alpha: 0.3),
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    progress.progressLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        def.unlockHint.isNotEmpty
                            ? def.unlockHint
                            : def.description,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (progress.unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '${AppStrings.unlockedOn} ${DateFormat.yMMMd().format(progress.unlockedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = progress.definition;
    final isUnlocked = progress.isUnlocked;
    final color = isUnlocked ? AppColors.blue : Colors.grey;

    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AchievementIcon(
            definition: def,
            isUnlocked: isUnlocked,
            ringProgress: isUnlocked ? 1.0 : progress.progress,
            size: 52,
            iconColor: isUnlocked ? color : theme.disabledColor,
          ),
          const SizedBox(height: 6),
          Text(
            def.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400,
              color: isUnlocked ? null : theme.disabledColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final Achievement definition;
  final bool isUnlocked;
  final double ringProgress;
  final double size;
  final Color? iconColor;

  const _AchievementIcon({
    required this.definition,
    required this.isUnlocked,
    required this.ringProgress,
    required this.size,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? (isUnlocked ? AppColors.blue : theme.disabledColor);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isUnlocked && ringProgress > 0)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: ringProgress.clamp(0.05, 1.0),
                strokeWidth: 2,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                color: AppColors.blue.withValues(alpha: 0.6),
              ),
            ),
          Container(
            width: size - 8,
            height: size - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? color.withValues(alpha: 0.15)
                  : theme.dividerColor.withValues(alpha: 0.3),
              border: Border.all(
                color: isUnlocked
                    ? color.withValues(alpha: 0.5)
                    : theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              IconData(definition.iconCodePoint, fontFamily: 'MaterialIcons'),
              size: size * 0.42,
              color: color,
            ),
          ),
          if (!isUnlocked)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: size * 0.2,
                  color: theme.disabledColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
