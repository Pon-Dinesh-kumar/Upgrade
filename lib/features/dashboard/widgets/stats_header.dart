import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../../core/widgets/level_badge.dart';
import '../../../core/widgets/app_logo_icon.dart';
import '../../../core/widgets/streak_flame.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../data/providers.dart';

class StatsHeader extends ConsumerWidget {
  const StatsHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final activeUpgrades = ref.watch(activeUpgradesProvider);
    final theme = Theme.of(context);

    if (profile == null) {
      return const SizedBox(height: 160);
    }

    final xpProgress = XpCalculator.progressToNextLevel(profile.totalXp);
    final xpNeeded = XpCalculator.xpRequiredForLevel(profile.level);
    final xpAccumulated = XpCalculator.totalXpForLevel(profile.level - 1);
    final xpInLevel = profile.totalXp - xpAccumulated;

    final levelCardBg = theme.brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()},',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.username,
                    style: theme.textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        profile.rank,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      StreakFlame(
                        streak: profile.currentStreak,
                        size: 18,
                      ),
                      if (activeUpgrades.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        _ActiveUpgradesBadge(count: activeUpgrades.length),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.go('/level-roadmap'),
              child: LevelBadge(level: profile.level, size: 52),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        XpBar(
          progress: xpProgress,
          level: profile.level,
          currentXp: xpInLevel.clamp(0, xpNeeded),
          xpForNext: xpNeeded,
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActiveUpgradesBadge extends StatelessWidget {
  final int count;
  const _ActiveUpgradesBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.green.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogoIcon(size: 12, color: AppColors.green),
          const SizedBox(width: 4),
          Text(
            '$count active',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
