import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/xp_calculator.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/xp_bar.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_settings_screen.dart';
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
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
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
                    ref.invalidate(userProfileProvider),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _ProfileHeader(
                profile: profile,
                avatarData: profile.avatarData,
                username: profile.username,
                rank: profile.rank,
                level: profile.level,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => _showXpLog(context, ref),
                child: XpBar(
                  progress: progress,
                  level: profile.level,
                  currentXp: currentXpInLevel.clamp(0, xpForNext),
                  xpForNext: xpForNext,
                ),
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 24),

              _StatsGrid(
                totalXp: profile.totalXp,
                currentStreak: profile.currentStreak,
                longestStreak: profile.longestStreak,
                completedCount: completedCount,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 32),

              Text('Achievements',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              AchievementGrid(
                unlocked: unlockedAchievements,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileSettingsScreen(profile: profile),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Profile Settings'),
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

  void _showXpLog(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.read(timelineProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'XP Log',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'History of your achievements and growth',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: timelineAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (events) {
                    final xpEvents = events
                        .where((e) =>
                            e.type == 'habit_completion' ||
                            e.type == 'upgrade_evaluation' ||
                            e.type == 'onboarding_completion')
                        .toList()
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (xpEvents.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded,
                                  size: 48, color: theme.dividerColor),
                              const SizedBox(height: 12),
                              Text('No XP history yet',
                                  style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: xpEvents.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: theme.dividerColor, height: 24),
                      itemBuilder: (context, index) {
                        final event = xpEvents[index];
                        final isPositive = !event.description.contains('-');

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isPositive
                                        ? AppColors.green
                                        : AppColors.red)
                                    .withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                event.type == 'habit_completion'
                                    ? Icons.check_circle_outline_rounded
                                    : event.type == 'upgrade_evaluation'
                                        ? Icons.rocket_launch_outlined
                                        : Icons.auto_awesome_rounded,
                                size: 18,
                                color:
                                    isPositive ? AppColors.green : AppColors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    event.description,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatTimestamp(event.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    if (ts.year == now.year && ts.month == now.month && ts.day == now.day) {
      return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    }
    return '${ts.day}/${ts.month}';
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
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppAvatar(
                avatarData: avatarData,
                customAvatarPath: profile.customAvatarPath,
                avatarType: profile.avatarType,
                size: 88,
              ),
            ),
            Positioned(
              bottom: -4,
              child: LevelBadge(level: level, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          username,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            rank,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.bold,
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          icon: Icons.bolt_rounded,
          label: 'Total XP',
          value: _formatNumber(totalXp),
          color: AppColors.blue,
        ),
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: '$currentStreak',
          color: AppColors.amber,
        ),
        _StatCard(
          icon: Icons.emoji_events_outlined,
          label: 'Longest',
          value: '$longestStreak',
          color: AppColors.amber,
        ),
        _StatCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Done',
          value: completedCount.toString(),
          color: AppColors.green,
        ),
      ],
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontSize: 9,
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
