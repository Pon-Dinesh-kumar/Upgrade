import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/xp_calculator.dart';
import '../../data/providers.dart';

class LevelRoadmapScreen extends ConsumerWidget {
  const LevelRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final upgradesAsync = ref.watch(upgradesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Level Roadmap')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile'));
          }

          final currentLevel = profile.level;
          final totalXp = profile.totalXp;
          final progress = XpCalculator.progressToNextLevel(totalXp);

          final completedUpgrades = upgradesAsync.valueOrNull
                  ?.where((u) => u.status == 'completed')
                  .toList() ??
              [];
          final activeUpgrades = upgradesAsync.valueOrNull
                  ?.where((u) => u.status == 'active')
                  .toList() ??
              [];

          final maxLevel = (currentLevel + 20).clamp(20, 100);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: maxLevel + 1,
            itemBuilder: (context, index) {
              final level = maxLevel - index;
              final xpNeeded = XpCalculator.xpRequiredForLevel(level);
              final cumulativeXp = XpCalculator.totalXpForLevel(level);
              final isCurrent = level == currentLevel;
              final isPast = level < currentLevel;
              final rankEntry = AppConstants.rankTitles
                  .where((e) => e.key == level)
                  .firstOrNull;

              final upgradesAtLevel = completedUpgrades
                  .where((u) =>
                      u.xpAwarded != null &&
                      _upgradeAtLevel(u.xpAwarded!, totalXp, level))
                  .toList();

              return _LevelNode(
                level: level,
                xpNeeded: xpNeeded,
                cumulativeXp: cumulativeXp,
                isCurrent: isCurrent,
                isPast: isPast,
                progress: isCurrent ? progress : null,
                rankName: rankEntry?.value,
                completedUpgradeNames:
                    upgradesAtLevel.map((u) => u.name).toList(),
                activeUpgradeCount:
                    isCurrent ? activeUpgrades.length : 0,
                isFirst: index == 0,
                isLast: level == 0,
              );
            },
          );
        },
      ),
    );
  }

  bool _upgradeAtLevel(int xpAwarded, int totalXp, int level) {
    return false;
  }
}

class _LevelNode extends StatelessWidget {
  final int level;
  final int xpNeeded;
  final int cumulativeXp;
  final bool isCurrent;
  final bool isPast;
  final double? progress;
  final String? rankName;
  final List<String> completedUpgradeNames;
  final int activeUpgradeCount;
  final bool isFirst;
  final bool isLast;

  const _LevelNode({
    required this.level,
    required this.xpNeeded,
    required this.cumulativeXp,
    required this.isCurrent,
    required this.isPast,
    this.progress,
    this.rankName,
    required this.completedUpgradeNames,
    required this.activeUpgradeCount,
    required this.isFirst,
    required this.isLast,
  });

  static const _milestoneMessages = {
    1: 'The journey begins',
    6: 'Building momentum',
    16: 'Gaining mastery',
    26: 'Becoming an expert',
    36: 'Pushing boundaries',
    51: 'True dedication',
    71: 'Among the best',
    91: 'Living legend',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestone = _milestoneMessages[level];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPast || isCurrent
                          ? AppColors.blue.withValues(alpha: 0.4)
                          : theme.dividerColor,
                    ),
                  ),
                Container(
                  width: isCurrent ? 20 : 12,
                  height: isCurrent ? 20 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.blue
                        : isPast
                            ? AppColors.green
                            : theme.dividerColor,
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                            width: 3)
                        : null,
                  ),
                  child: isPast && !isCurrent
                      ? const Center(
                          child: Icon(Icons.check_rounded,
                              size: 8, color: Colors.white))
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPast
                          ? AppColors.blue.withValues(alpha: 0.4)
                          : theme.dividerColor,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isCurrent
                      ? AppColors.blue.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.blue.withValues(alpha: 0.3))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.w500,
                            fontSize: isCurrent ? 16 : 14,
                            color: isCurrent
                                ? AppColors.blue
                                : isPast
                                    ? theme.textTheme.bodyLarge?.color
                                    : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        if (rankName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent || isPast
                                  ? AppColors.amber.withValues(alpha: 0.15)
                                  : theme.dividerColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rankName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCurrent || isPast
                                    ? AppColors.amber
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '$xpNeeded XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),

                    if (isCurrent && progress != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress!,
                          minHeight: 6,
                          backgroundColor: theme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress! * 100).round()}% to Level ${level + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    if (activeUpgradeCount > 0 && isCurrent) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppLogoIcon(size: 14, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            '$activeUpgradeCount active upgrade${activeUpgradeCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (milestone != null && !isPast) ...[
                      const SizedBox(height: 6),
                      Text(
                        milestone,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
