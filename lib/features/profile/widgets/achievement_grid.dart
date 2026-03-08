import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/achievement.dart';

class AchievementGrid extends StatelessWidget {
  final List<Achievement> unlocked;

  const AchievementGrid({super.key, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final definitions = Achievement.definitions;
    final unlockedKeys = unlocked.map((a) => a.key).toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: definitions.length,
      itemBuilder: (context, index) {
        final def = definitions[index];
        final isUnlocked = unlockedKeys.contains(def.key);
        return _AchievementTile(
          definition: def,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement definition;
  final bool isUnlocked;

  const _AchievementTile({
    required this.definition,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUnlocked ? AppColors.blue : Colors.grey;

    return Tooltip(
      message: '${definition.name}\n${definition.description}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
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
                  IconData(definition.iconCodePoint,
                      fontFamily: 'MaterialIcons'),
                  size: 24,
                  color: isUnlocked
                      ? color
                      : theme.disabledColor,
                ),
              ),
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 10,
                      color: theme.disabledColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            definition.name,
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
