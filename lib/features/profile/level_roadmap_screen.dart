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

  // Personal motivational messages per rank tier
  static const _rankMessages = {
    'Novice': "Every master was once a beginner. You've taken the hardest step — starting.",
    'Apprentice': "You're building real momentum. Your habits are becoming part of who you are.",
    'Adept': "Consistency is your superpower now. Most people quit — you didn't.",
    'Specialist': "You're in rare territory. Your dedication is shaping a better version of you.",
    'Expert': "The discipline you've built is extraordinary. You're proof that effort compounds.",
    'Master': "You've earned mastery through relentless commitment. Few reach this far.",
    'Grandmaster': "You're among the elite. Your journey inspires everyone around you.",
    'Legend': "Living proof that extraordinary results come from ordinary efforts, done daily.",
  };

  // Milestone reward descriptions — what the user "unlocks"
  static const _milestoneRewards = {
    1: ('🌱', 'The Seed', 'Your journey begins here. Every great transformation starts with a single step.'),
    5: ('⚡', 'First Spark', 'You proved this isn\'t just a phase. Momentum is building.'),
    10: ('🔥', 'On Fire', "Double digits! Your habits are becoming automatic."),
    15: ('💪', 'Unbreakable', 'You\'ve built a foundation most people never achieve.'),
    20: ('🌟', 'Rising Star', 'Consistency is your superpower. Keep shining.'),
    25: ('🏆', 'Champion', 'A quarter-century of levels. That\'s elite dedication.'),
    30: ('👑', 'Crowned', 'You rule your habits. They don\'t rule you.'),
    40: ('💎', 'Diamond Mind', 'Forged under pressure, you\'re unbreakable now.'),
    50: ('🚀', 'Unstoppable', 'Halfway to 100. Nothing can hold you back.'),
    75: ('🌌', 'Beyond Limits', 'You\'ve transcended what most thought possible.'),
    100: ('✨', 'Transcendent', 'The ultimate achievement. You ARE the upgrade.'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final upgradesAsync = ref.watch(upgradesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Journey')),
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
          final currentRank = AppConstants.getRank(currentLevel);
          final nextRankEntry = AppConstants.rankTitles
              .where((e) => e.key > currentLevel)
              .firstOrNull;

          final completedUpgrades = upgradesAsync.valueOrNull
                  ?.where((u) => u.status == 'completed')
                  .length ??
              0;
          final activeUpgrades = upgradesAsync.valueOrNull
                  ?.where((u) => u.status == 'active')
                  .toList() ??
              [];

          // Build the level items: show nearby levels (past 5 + current + next 15)
          // Ascending order: small levels at top, big levels at bottom
          final minLevel = (currentLevel - 5).clamp(0, currentLevel);
          final maxLevel = (currentLevel + 15).clamp(currentLevel + 5, 100);

          final levelNodes = <int>[];
          for (int l = minLevel; l <= maxLevel; l++) {
            levelNodes.add(l);
          }

          return CustomScrollView(
            slivers: [
              // ─── Personal Hero Card ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _HeroCard(
                    username: profile.username,
                    level: currentLevel,
                    rank: currentRank,
                    totalXp: totalXp,
                    progress: progress,
                    completedUpgrades: completedUpgrades,
                    activeUpgradeCount: activeUpgrades.length,
                    currentStreak: profile.currentStreak,
                    longestStreak: profile.longestStreak,
                    motivationalMessage: _rankMessages[currentRank] ??
                        'Keep going — your future self is cheering you on.',
                    nextRankName: nextRankEntry?.value,
                    nextRankLevel: nextRankEntry?.key,
                  ).animate().fadeIn(duration: 300.ms).slideY(
                      begin: 0.05, curve: Curves.easeOutCubic),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ─── Next Milestone Preview ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NextMilestoneCard(
                    currentLevel: currentLevel,
                    milestoneRewards: _milestoneRewards,
                  ).animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ─── Roadmap Header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Level Roadmap',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ).animate()
                      .fadeIn(delay: 150.ms, duration: 250.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ─── Level Nodes ───
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final level = levelNodes[index];
                      final xpNeeded =
                          XpCalculator.xpRequiredForLevel(level);
                      final isCurrent = level == currentLevel;
                      final isPast = level < currentLevel;
                      final rankEntry = AppConstants.rankTitles
                          .where((e) => e.key == level)
                          .firstOrNull;
                      final milestone = _milestoneRewards[level];

                      return _LevelNode(
                        level: level,
                        xpNeeded: xpNeeded,
                        isCurrent: isCurrent,
                        isPast: isPast,
                        progress: isCurrent ? progress : null,
                        rankName: rankEntry?.value,
                        milestoneEmoji: milestone?.$1,
                        milestoneTitle: milestone?.$2,
                        activeUpgradeCount:
                            isCurrent ? activeUpgrades.length : 0,
                        isFirst: index == 0,
                        isLast: index == levelNodes.length - 1,
                      ).animate().fadeIn(
                            delay: (180 + index * 25).ms,
                            duration: 250.ms,
                          );
                    },
                    childCount: levelNodes.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero Card ───────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String username;
  final int level;
  final String rank;
  final int totalXp;
  final double progress;
  final int completedUpgrades;
  final int activeUpgradeCount;
  final int currentStreak;
  final int longestStreak;
  final String motivationalMessage;
  final String? nextRankName;
  final int? nextRankLevel;

  const _HeroCard({
    required this.username,
    required this.level,
    required this.rank,
    required this.totalXp,
    required this.progress,
    required this.completedUpgrades,
    required this.activeUpgradeCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.motivationalMessage,
    this.nextRankName,
    this.nextRankLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.12),
            AppColors.blue.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username + Level badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rank,
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${totalXp.toStringAsFixed(0)} XP earned',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $level → Level ${level + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blue,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.dividerColor,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.blue),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _HeroStat(
                icon: Icons.local_fire_department_rounded,
                value: '$currentStreak',
                label: 'Streak',
                color: AppColors.amber,
              ),
              const SizedBox(width: 16),
              _HeroStat(
                icon: Icons.emoji_events_rounded,
                value: '$longestStreak',
                label: 'Best',
                color: AppColors.amber,
              ),
              const SizedBox(width: 16),
              _HeroStat(
                icon: Icons.check_circle_rounded,
                value: '$completedUpgrades',
                label: 'Done',
                color: AppColors.green,
              ),
              if (activeUpgradeCount > 0) ...[
                const SizedBox(width: 16),
                _HeroStat(
                  useAppLogo: true,
                  icon: Icons.trending_up_rounded,
                  value: '$activeUpgradeCount',
                  label: 'Active',
                  color: AppColors.green,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Motivational message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💬', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motivationalMessage,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Next rank preview
          if (nextRankName != null && nextRankLevel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.arrow_upward_rounded,
                    size: 14, color: AppColors.blue),
                const SizedBox(width: 6),
                Text(
                  'Next rank: $nextRankName at Level $nextRankLevel',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool useAppLogo;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.useAppLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        useAppLogo
            ? AppLogoIcon(size: 16, color: color)
            : Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

// ─── Next Milestone Card ────────────────────────────────────────────────────
class _NextMilestoneCard extends StatelessWidget {
  final int currentLevel;
  final Map<int, (String, String, String)> milestoneRewards;

  const _NextMilestoneCard({
    required this.currentLevel,
    required this.milestoneRewards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find the next milestone above current level
    final nextMilestone = milestoneRewards.entries
        .where((e) => e.key > currentLevel)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (nextMilestone.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.12),
              AppColors.amber.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Milestones Achieved!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'ve reached legendary status. The journey continues forever.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final next = nextMilestone.first;
    final levelsAway = next.key - currentLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.10),
            AppColors.amber.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(next.value.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Next: ${next.value.$2}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.amber,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$levelsAway level${levelsAway > 1 ? 's' : ''} away',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  next.value.$3,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level Node (Roadmap Item) ──────────────────────────────────────────────
class _LevelNode extends StatelessWidget {
  final int level;
  final int xpNeeded;
  final bool isCurrent;
  final bool isPast;
  final double? progress;
  final String? rankName;
  final String? milestoneEmoji;
  final String? milestoneTitle;
  final int activeUpgradeCount;
  final bool isFirst;
  final bool isLast;

  const _LevelNode({
    required this.level,
    required this.xpNeeded,
    required this.isCurrent,
    required this.isPast,
    this.progress,
    this.rankName,
    this.milestoneEmoji,
    this.milestoneTitle,
    required this.activeUpgradeCount,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMilestone = milestoneEmoji != null;
    final hasRank = rankName != null;
    final isSpecial = hasMilestone || hasRank;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left timeline
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isPast || isCurrent
                              ? [
                                  AppColors.blue.withValues(alpha: 0.5),
                                  AppColors.blue.withValues(alpha: 0.3),
                                ]
                              : [
                                  theme.dividerColor.withValues(alpha: 0.5),
                                  theme.dividerColor.withValues(alpha: 0.3),
                                ],
                        ),
                      ),
                    ),
                  ),
                // Node dot
                Container(
                  width: isCurrent
                      ? 24
                      : isSpecial
                          ? 16
                          : 12,
                  height: isCurrent
                      ? 24
                      : isSpecial
                          ? 16
                          : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.blue
                        : isPast
                            ? AppColors.green
                            : isSpecial
                                ? AppColors.amber.withValues(alpha: 0.3)
                                : theme.dividerColor.withValues(alpha: 0.5),
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                            width: 4,
                          )
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.blue.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isPast && !isCurrent
                      ? const Center(
                          child: Icon(Icons.check_rounded,
                              size: 8, color: Colors.white),
                        )
                      : isCurrent
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isPast
                              ? [
                                  AppColors.blue.withValues(alpha: 0.3),
                                  AppColors.blue.withValues(alpha: 0.5),
                                ]
                              : [
                                  theme.dividerColor.withValues(alpha: 0.3),
                                  theme.dividerColor.withValues(alpha: 0.5),
                                ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isCurrent
                      ? AppColors.blue.withValues(alpha: 0.08)
                      : isSpecial && !isPast
                          ? AppColors.amber.withValues(alpha: 0.04)
                          : Colors.transparent,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.blue.withValues(alpha: 0.3),
                        )
                      : isSpecial && !isPast
                          ? Border.all(
                              color:
                                  AppColors.amber.withValues(alpha: 0.15),
                            )
                          : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hasMilestone) ...[
                          Text(milestoneEmoji!,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : isSpecial
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                            fontSize: isCurrent ? 16 : 14,
                            color: isCurrent
                                ? AppColors.blue
                                : isPast
                                    ? theme.textTheme.bodyLarge?.color
                                    : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        if (hasRank) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent || isPast
                                  ? AppColors.amber
                                      .withValues(alpha: 0.15)
                                  : theme.dividerColor
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🏅 $rankName',
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

                    // Milestone title
                    if (milestoneTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestoneTitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isPast
                              ? AppColors.green
                              : isCurrent
                                  ? AppColors.blue
                                  : AppColors.amber,
                        ),
                      ),
                    ],

                    // Current level progress
                    if (isCurrent && progress != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress!,
                          minHeight: 6,
                          backgroundColor: theme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.blue),
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

                    // Active upgrades at current level
                    if (activeUpgradeCount > 0 && isCurrent) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppLogoIcon(size: 14, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            '$activeUpgradeCount active upgrade${activeUpgradeCount > 1 ? 's' : ''} powering your progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Current level "YOU ARE HERE" tag
                    if (isCurrent) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_rounded,
                                size: 12, color: AppColors.blue),
                            SizedBox(width: 4),
                            Text(
                              'YOU ARE HERE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
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
