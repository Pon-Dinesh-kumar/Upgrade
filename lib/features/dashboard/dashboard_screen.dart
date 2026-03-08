import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/notion_avatar_display.dart';
import '../../core/utils/gamification_engine.dart';
import '../../core/utils/date_utils.dart';
import '../../data/providers.dart';
import '../../domain/entities/timeline_event.dart';
import '../../domain/entities/upgrade_group.dart';
import 'widgets/stats_header.dart';
import 'widgets/today_habits_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasCheckedDue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateDue());
  }

  Future<void> _evaluateDue() async {
    if (_hasCheckedDue) return;
    _hasCheckedDue = true;
    final due = ref.read(dueUpgradesProvider);
    if (due.isNotEmpty) {
      await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentEvents = ref.watch(recentTimelineProvider);
    final activeUpgrades = ref.watch(activeUpgradesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            _hasCheckedDue = false;
            ref.invalidate(habitsProvider);
            ref.invalidate(habitEntriesProvider);
            ref.invalidate(userProfileProvider);
            ref.invalidate(upgradesProvider);
            ref.invalidate(upgradeHabitsProvider);
            ref.invalidate(timelineProvider);
            await Future.delayed(const Duration(milliseconds: 300));
            _evaluateDue();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogoIcon(
                      size: 28,
                      color: theme.iconTheme.color ?? theme.textTheme.headlineSmall?.color,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'UPGRADE',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                actions: [
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: ClipOval(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: profile != null
                            ? NotionAvatarDisplay(avatarData: profile.avatarData, size: 32)
                            : const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.blue,
                                child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => context.push('/settings'),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    const StatsHeader(),
                    const SizedBox(height: 24),

                    if (activeUpgrades.isNotEmpty) ...[
                      _ActiveUpgradesSection(upgrades: activeUpgrades),
                      const SizedBox(height: 24),
                    ],

                    const TodayHabitsList(),
                    const SizedBox(height: 24),

                    if (recentEvents.isNotEmpty) ...[
                      _RecentTimeline(events: recentEvents),
                      const SizedBox(height: 80),
                    ] else
                      const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/new'),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _ActiveUpgradesSection extends StatelessWidget {
  final List<UpgradeGroup> upgrades;
  const _ActiveUpgradesSection({required this.upgrades});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Active Upgrades', style: theme.textTheme.headlineSmall),
            const Spacer(),
            Text(
              '${upgrades.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: upgrades.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _UpgradeCard(upgrade: upgrades[index])
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 60 * index),
                      duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}

class _UpgradeCard extends ConsumerWidget {
  final UpgradeGroup upgrade;
  const _UpgradeCard({required this.upgrade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(liveUpgradeScoreProvider(upgrade.id));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
        upgrade.endDate.year, upgrade.endDate.month, upgrade.endDate.day);
    final daysRemaining = endDay.difference(today).inDays;
    final totalDays = endDay
        .difference(DateTime(upgrade.startDate.year, upgrade.startDate.month,
            upgrade.startDate.day))
        .inDays;
    final elapsed = totalDays - daysRemaining;
    final expectedProgress =
        totalDays > 0 ? (elapsed / totalDays).clamp(0.0, 1.0) : 0.0;
    final onTrack = score >= expectedProgress * upgrade.cutoffPercentage;

    final upgradeColor = Color(upgrade.color);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/upgrades/${upgrade.id}'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: upgradeColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  IconData(upgrade.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 18,
                  color: upgradeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    upgrade.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NotionTag(
              label: upgrade.difficulty[0].toUpperCase() +
                  upgrade.difficulty.substring(1),
              color: AppColors.difficultyColors[upgrade.difficulty] ??
                  AppColors.blue,
            ),
            const Spacer(),
            _FlatProgressBar(
              score: score,
              cutoff: upgrade.cutoffPercentage,
              color: upgradeColor,
              trackColor: trackColor,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 12,
                    color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(
                  daysRemaining > 0 ? '${daysRemaining}d left' : 'Due today',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                const Spacer(),
                _NotionTag(
                  label: onTrack ? 'On track' : 'Behind',
                  color: onTrack ? AppColors.green : AppColors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotionTag extends StatelessWidget {
  final String label;
  final Color color;
  const _NotionTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FlatProgressBar extends StatelessWidget {
  final double score;
  final double cutoff;
  final Color color;
  final Color trackColor;

  const _FlatProgressBar({
    required this.score,
    required this.cutoff,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(score * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Goal: ${(cutoff * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: totalWidth,
                    height: 6,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: (score.clamp(0.0, 1.0) * totalWidth),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: color,
                    ),
                  ),
                  Positioned(
                    left: (cutoff.clamp(0.0, 1.0) * totalWidth) - 0.5,
                    top: -1,
                    child: Container(
                      width: 1,
                      height: 8,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  const _RecentTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    final display = events.take(3).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...display.asMap().entries.map((entry) {
          final i = entry.key;
          final event = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TimelineCard(event: event)
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: 60 * i), duration: 300.ms),
          );
        }),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final TimelineEvent event;
  const _TimelineCard({required this.event});

  IconData get _icon {
    switch (event.type) {
      case 'habit_complete':
        return Icons.check_circle_rounded;
      case 'level_up':
        return Icons.arrow_circle_up_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'achievement_unlock':
        return Icons.emoji_events_rounded;
      case 'upgrade_evaluated':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }

  Widget _iconWidget(Color color) {
    if (event.type == 'upgrade_evaluated') {
      return AppLogoIcon(size: 18, color: color);
    }
    return Icon(_icon, size: 18, color: color);
  }

  Color get _color {
    switch (event.type) {
      case 'habit_complete':
        return AppColors.green;
      case 'level_up':
        return AppColors.blue;
      case 'streak':
        return AppColors.amber;
      case 'achievement_unlock':
        return AppColors.amber;
      case 'upgrade_evaluated':
        return AppColors.green;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.cardColor,
        border: Border(
          left: BorderSide(color: _color, width: 3),
          top: BorderSide(color: theme.dividerColor),
          right: BorderSide(color: theme.dividerColor),
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          _iconWidget(_color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppDateUtils.formatRelative(event.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
