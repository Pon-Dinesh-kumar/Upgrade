import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/upgrade_progress_bar.dart';
import '../../core/utils/date_utils.dart';
import '../../data/providers.dart';
import '../../domain/entities/timeline_event.dart';
import '../../domain/entities/upgrade_group.dart';
import 'widgets/today_habits_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  bool _hasCheckedDue = false;
  bool _isFabExpanded = false;
  late final AnimationController _fabController;
  late final Animation<double> _expandAnimation;
  late final PageController _upgradePageController;
  int _selectedUpgradeIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _upgradePageController = PageController(viewportFraction: 0.95);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateDue());
  }

  @override
  void dispose() {
    _fabController.dispose();
    _upgradePageController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
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
                    automaticallyImplyLeading: false,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: false,
                    title: Consumer(
                      builder: (context, ref, child) {
                        final profile = ref.watch(userProfileProvider).valueOrNull;
                         final name = profile?.username ?? 'User';
                        final hour = DateTime.now().hour;
                        final greeting = switch (hour) {
                          >= 0 && < 12 => 'Good morning,',
                          >= 12 && < 17 => 'Good afternoon,',
                          _ => 'Good evening,',
                        };

                        return Row(
                           children: [
                             AppLogoIcon(
                               size: 28,
                               color: theme.iconTheme.color ?? theme.textTheme.headlineSmall?.color,
                             ),
                             const SizedBox(width: 12),
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   greeting,
                                   style: theme.textTheme.bodyMedium?.copyWith(
                                     color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                     height: 1.1,
                                   ),
                                 ),
                                 Text(
                                   name,
                                   style: theme.textTheme.titleLarge?.copyWith(
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         );
                      },
                    ),
                    actions: [
                      Consumer(
                        builder: (context, ref, child) {
                          final profile = ref.watch(userProfileProvider).valueOrNull;
                          final streak = profile?.currentStreak ?? 0;
                          final level = profile?.level ?? 1;

                          return Row(
                            children: [
                              if (streak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded,
                                          size: 16, color: Colors.orange),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$streak',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    AppAvatar(
                                      avatarData: profile?.avatarData,
                                      customAvatarPath: profile?.customAvatarPath,
                                      avatarType: profile?.avatarType ?? 'minimalist',
                                      size: 36,
                                      onTap: () => context.push('/profile'),
                                    ),
                                    Positioned(
                                      bottom: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          '$level',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final activeUpgrades = ref.watch(activeUpgradesProvider);
                            if (activeUpgrades.isEmpty) {
                              return const Column(
                                children: [
                                  TodayHabitsList(),
                                  SizedBox(height: 24),
                                ],
                              );
                            }

                            // Ensure index is within bounds
                            if (_selectedUpgradeIndex >= activeUpgrades.length) {
                              _selectedUpgradeIndex = activeUpgrades.length - 1;
                            }
                            if (_selectedUpgradeIndex < 0) {
                              _selectedUpgradeIndex = 0;
                            }

                            final selectedUpgrade = activeUpgrades[_selectedUpgradeIndex];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ActiveUpgradesCarousel(
                                  upgrades: activeUpgrades,
                                  controller: _upgradePageController,
                                  selectedIndex: _selectedUpgradeIndex,
                                  onPageChanged: (index) {
                                    setState(() => _selectedUpgradeIndex = index);
                                  },
                                ),
                                const SizedBox(height: 24),
                                TodayHabitsList(upgradeId: selectedUpgrade.id),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),

                        Consumer(
                          builder: (context, ref, child) {
                            final recentEvents = ref.watch(recentTimelineProvider);
                            if (recentEvents.isEmpty) return const SizedBox(height: 80);
                            return Column(
                              children: [
                                _RecentTimeline(events: recentEvents),
                                const SizedBox(height: 80),
                              ],
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            if (_isFabExpanded)
              GestureDetector(
                onTap: _toggleFab,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _BranchingFab(
        isExpanded: _isFabExpanded,
        animation: _expandAnimation,
        onToggle: _toggleFab,
      ),
    );
  }

  Future<void> _evaluateDue() async {
    if (_hasCheckedDue) return;
    _hasCheckedDue = true;
    final due = ref.read(dueUpgradesProvider);
    if (due.isNotEmpty) {
      await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
    }
  }
}

class _BranchingFab extends StatelessWidget {
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const _BranchingFab({
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: animation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionLabel(label: 'New Upgrade', isVisible: isExpanded),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'fab-upgrade',
                  onPressed: () {
                    onToggle();
                    context.go('/upgrades/new');
                  },
                  backgroundColor: AppColors.green,
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        ScaleTransition(
          scale: animation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionLabel(label: 'New Habit', isVisible: isExpanded),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'fab-habit',
                  onPressed: () {
                    onToggle();
                    context.go('/habits/new');
                  },
                  backgroundColor: AppColors.blue,
                  child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab-main',
          onPressed: onToggle,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _OptionLabel extends StatelessWidget {
  final String label;
  final bool isVisible;

  const _OptionLabel({required this.label, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActiveUpgradesCarousel extends StatelessWidget {
  final List<UpgradeGroup> upgrades;
  final PageController controller;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  const _ActiveUpgradesCarousel({
    required this.upgrades,
    required this.controller,
    required this.selectedIndex,
    required this.onPageChanged,
  });

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
          height: 160, // Fixed height for the carousel
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: upgrades.length,
            padEnds: false,
            itemBuilder: (context, index) {
              final upgrade = upgrades[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _UpgradeCard(upgrade: upgrade),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              upgrades.length,
              (index) => _DotIndicator(
                isActive: selectedIndex == index,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 18 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
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
    
    final upgradeColor = Color(upgrade.color);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/upgrades/${upgrade.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: upgradeColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: upgradeColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: upgradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconData(upgrade.iconCodePoint, fontFamily: 'MaterialIcons'),
                    size: 20,
                    color: upgradeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upgrade.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        upgrade.difficulty[0].toUpperCase() + upgrade.difficulty.substring(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.difficultyColors[upgrade.difficulty],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(score * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: upgradeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Goal: ${(upgrade.cutoffPercentage * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            UpgradeProgressBar(
              score: score,
              cutoff: upgrade.cutoffPercentage,
              color: upgradeColor,
              trackColor: trackColor,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14,
                        color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      daysRemaining > 0 ? '${daysRemaining}d left' : 'Due today',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'On track',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        ...display.map((event) => _TimelineCard(event: event)),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
