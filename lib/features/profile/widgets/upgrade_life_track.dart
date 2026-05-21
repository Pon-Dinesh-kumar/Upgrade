import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/profile_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/upgrade_progress_bar.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/upgrade_group.dart';

class UpgradeLifeTrack extends ConsumerWidget {
  const UpgradeLifeTrack({super.key});

  static const int _maxActiveVisible = 3;
  static const int _maxCompletedVisible = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final active = ref.watch(activeUpgradesProvider);
    final allUpgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final completed = allUpgrades
        .where((u) => u.status == 'completed')
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    final visibleActive = active.take(_maxActiveVisible).toList();
    final visibleCompleted = completed.take(_maxCompletedVisible).toList();
    final hasMoreActive = active.length > _maxActiveVisible;

    double? topScore;
    for (final u in active) {
      final s = ref.watch(liveUpgradeScoreProvider(u.id));
      if (topScore == null || s > topScore) topScore = s;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.upgradeTrack,
              style: theme.textTheme.headlineSmall,
            ),
            if (hasMoreActive) ...[
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/upgrades'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppStrings.viewAllUpgrades),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (visibleActive.isEmpty && visibleCompleted.isEmpty)
          Text(
            AppStrings.noActiveUpgradesProfile,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          )
        else ...[
          ...visibleActive.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActiveUpgradeRow(upgrade: u),
            ),
          ),
          ...visibleCompleted.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CompletedUpgradeRow(upgrade: u),
            ),
          ),
        ],
        if (topScore != null) ...[
          const SizedBox(height: 4),
          Text(
            ProfileCopy.upgradeTrackMotivation(topScore),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else if (active.isEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go('/upgrades/new'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(AppStrings.newUpgrade),
          ),
        ],
      ],
    );
  }
}

class _ActiveUpgradeRow extends ConsumerWidget {
  final UpgradeGroup upgrade;

  const _ActiveUpgradeRow({required this.upgrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = ref.watch(liveUpgradeScoreProvider(upgrade.id));
    final upgradeColor = Color(upgrade.color);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final impact =
        AppConstants.upgradeImpactLabels[upgrade.difficulty] ?? upgrade.difficulty;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
      upgrade.endDate.year,
      upgrade.endDate.month,
      upgrade.endDate.day,
    );
    final daysRemaining = endDay.difference(today).inDays;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go('/upgrades/${upgrade.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: upgradeColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      upgrade.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    daysRemaining > 0 ? '${daysRemaining}d left' : 'Due today',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$impact impact',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.difficultyColors[upgrade.difficulty],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (upgrade.outcomeDescription != null &&
                  upgrade.outcomeDescription!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  upgrade.outcomeDescription!.trim(),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              UpgradeProgressBar(
                score: score,
                cutoff: upgrade.cutoffPercentage,
                color: upgradeColor,
                trackColor: trackColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedUpgradeRow extends StatelessWidget {
  final UpgradeGroup upgrade;

  const _CompletedUpgradeRow({required this.upgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impact =
        AppConstants.upgradeImpactLabels[upgrade.difficulty] ?? upgrade.difficulty;
    final dateStr = DateFormat.yMMMd().format(upgrade.endDate);

    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 20,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                upgrade.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              Text(
                '${AppStrings.upgradeComplete} · $impact impact · $dateStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
