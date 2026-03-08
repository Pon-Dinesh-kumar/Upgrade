import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/xp_calculator.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/notion_avatar_display.dart';
import '../../core/widgets/xp_bar.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import 'avatar_editor_screen.dart';
import 'widgets/achievement_grid.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final entriesAsync = ref.watch(habitEntriesProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text('Failed to load profile',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(userProfileProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text('No profile found',
                  style: theme.textTheme.titleMedium),
            );
          }

          final progress =
              XpCalculator.progressToNextLevel(profile.totalXp);
          final xpForNext =
              XpCalculator.xpRequiredForLevel(profile.level);
          final accumulated = XpCalculator.totalXpForLevel(profile.level - 1);
          final currentXpInLevel = profile.totalXp - accumulated;

          final completedCount = entriesAsync.valueOrNull
                  ?.where((e) => e.completed)
                  .length ??
              0;

          final unlockedAchievements =
              achievementsAsync.valueOrNull ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _ProfileHeader(
                profile: profile,
                avatarData: profile.avatarData,
                username: profile.username,
                rank: profile.rank,
                level: profile.level,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 20),

              XpBar(
                progress: progress,
                level: profile.level,
                currentXp: currentXpInLevel.clamp(0, xpForNext),
                xpForNext: xpForNext,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 24),

              _StatsGrid(
                totalXp: profile.totalXp,
                currentStreak: profile.currentStreak,
                longestStreak: profile.longestStreak,
                completedCount: completedCount,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 24),

              Text('Achievements',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              AchievementGrid(
                unlocked: unlockedAchievements,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final Map<String, int> avatarData;
  final String username;
  final String rank;
  final int level;

  const _ProfileHeader({
    required this.profile,
    required this.avatarData,
    required this.username,
    required this.rank,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AvatarEditorScreen(profile: profile),
                ),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.dividerColor,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NotionAvatarDisplay(
                      avatarData: avatarData,
                      size: 88,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LevelBadge(level: level, size: 34),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          username,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            rank,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int completedCount;

  const _StatsGrid({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.bolt_rounded,
          label: 'Total XP',
          value: _formatNumber(totalXp),
          color: AppColors.blue,
        ),
        _StatCard(
          icon: Icons.local_fire_department,
          label: 'Current Streak',
          value: '$currentStreak days',
          color: AppColors.amber,
        ),
        _StatCard(
          icon: Icons.emoji_events_outlined,
          label: 'Longest Streak',
          value: '$longestStreak days',
          color: AppColors.amber,
        ),
        _StatCard(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: _formatNumber(completedCount),
          color: AppColors.green,
        ),
      ],
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
