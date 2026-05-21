import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers.dart';
import '../logic/achievement_progress.dart';
import 'achievement_grid.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final habits = ref.watch(habitsProvider).valueOrNull ?? [];
    final entries = ref.watch(habitEntriesProvider).valueOrNull ?? [];
    final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final unlocked = ref.watch(achievementsProvider).valueOrNull ?? [];
    final unlockedKeys = unlocked.map((a) => a.key).toSet();

    final progressList = AchievementProgressCalculator.compute(
      profile: profile,
      habits: habits,
      entries: entries,
      upgrades: upgrades,
      goals: goals,
      unlockedKeys: unlockedKeys,
      unlocked: unlocked,
    );

    final total = progressList.length;
    final unlockedCount = progressList.where((p) => p.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.achievements,
              style: theme.textTheme.headlineSmall,
            ),
            const Spacer(),
            Text(
              '$unlockedCount of $total',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AchievementGrid(progressList: progressList),
      ],
    );
  }
}
