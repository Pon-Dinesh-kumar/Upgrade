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

  void _showUnlockHint(BuildContext context) {
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
            // Locked icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    IconData(definition.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    size: 28,
                    color: theme.disabledColor,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: theme.disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              definition.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              definition.description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // How to unlock
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
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      definition.unlockHint.isNotEmpty
                          ? definition.unlockHint
                          : definition.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUnlocked ? AppColors.blue : Colors.grey;

    return GestureDetector(
      onTap: isUnlocked ? null : () => _showUnlockHint(context),
      child: Tooltip(
        message: isUnlocked
            ? '${definition.name}\n${definition.description}'
            : '${definition.name} — Locked',
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
      ),
    );
  }
}
