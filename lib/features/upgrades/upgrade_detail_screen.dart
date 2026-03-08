import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/utils/gamification_engine.dart';
import '../../core/utils/xp_calculator.dart';
import '../../data/providers.dart';
import '../../domain/entities/upgrade_group.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/entities/upgrade_habit.dart';

class UpgradeDetailScreen extends ConsumerWidget {
  final String upgradeId;

  const UpgradeDetailScreen({super.key, required this.upgradeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradesAsync = ref.watch(upgradesProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final entriesAsync = ref.watch(habitEntriesProvider);
    final memberships = ref.watch(upgradeHabitsForUpgradeProvider(upgradeId));
    final liveScore = ref.watch(liveUpgradeScoreProvider(upgradeId));

    return upgradesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $err')),
      ),
      data: (upgrades) {
        final upgrade = upgrades.where((u) => u.id == upgradeId).firstOrNull;
        if (upgrade == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Upgrade not found')),
          );
        }

        final allHabits = habitsAsync.valueOrNull ?? <Habit>[];
        final entries = entriesAsync.valueOrNull ?? <HabitEntry>[];
        final upgradeColor = Color(upgrade.color);
        final displayScore =
            upgrade.status != 'active' && upgrade.completionScore != null
                ? upgrade.completionScore!
                : liveScore;

        return Scaffold(
          appBar: AppBar(
            title: Text(upgrade.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => context.go('/upgrades/${upgrade.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref, upgrade),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(upgrade: upgrade, upgradeColor: upgradeColor),
              const SizedBox(height: 20),
              _LiveScoreSection(
                upgrade: upgrade,
                score: displayScore,
                upgradeColor: upgradeColor,
              ),
              const SizedBox(height: 20),
              _MilestonesSection(
                score: displayScore,
                upgradeColor: upgradeColor,
              ),
              if (upgrade.status != 'active') ...[
                const SizedBox(height: 20),
                _FinalResultSection(upgrade: upgrade),
              ],
              const SizedBox(height: 24),
              _HabitContributionSection(
                upgrade: upgrade,
                memberships: memberships,
                allHabits: allHabits,
                entries: entries,
                upgradeColor: upgradeColor,
                ref: ref,
              ),
            ]
                .animate()
                .fadeIn(duration: 250.ms),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, UpgradeGroup upgrade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Upgrade'),
        content: Text(
            'Are you sure you want to delete "${upgrade.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(upgradesProvider.notifier).delete(upgrade.id);
      if (context.mounted) context.go('/upgrades');
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final UpgradeGroup upgrade;
  final Color upgradeColor;

  const _Header({required this.upgrade, required this.upgradeColor});

  Color get _statusColor {
    switch (upgrade.status) {
      case 'completed':
        return AppColors.green;
      case 'failed':
        return AppColors.red;
      default:
        return AppColors.blue;
    }
  }

  String get _statusLabel {
    switch (upgrade.status) {
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Active';
    }
  }

  Color get _difficultyColor {
    switch (upgrade.difficulty) {
      case 'easy':
        return AppColors.green;
      case 'hard':
        return AppColors.amber;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CardShell(
      borderColor: upgradeColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: upgradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(upgrade.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: upgradeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Badge(
                          label: AppConstants.upgradeImpactLabels[upgrade.difficulty] ?? upgrade.difficulty,
                          color: _difficultyColor,
                        ),
                        const SizedBox(width: 8),
                        _Badge(label: _statusLabel, color: _statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (upgrade.outcomeDescription != null &&
              upgrade.outcomeDescription!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              upgrade.outcomeDescription!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (upgrade.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              upgrade.description,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live Score
// ---------------------------------------------------------------------------

class _LiveScoreSection extends StatelessWidget {
  final UpgradeGroup upgrade;
  final double score;
  final Color upgradeColor;

  const _LiveScoreSection({
    required this.upgrade,
    required this.score,
    required this.upgradeColor,
  });

  String get _trackingLabel {
    if (upgrade.status == 'completed') return 'Completed';
    if (upgrade.status == 'failed') return 'Failed';
    return score >= upgrade.cutoffPercentage ? 'On track' : 'Behind';
  }

  Color get _trackingColor {
    if (upgrade.status == 'completed') return AppColors.green;
    if (upgrade.status == 'failed') return AppColors.red;
    return score >= upgrade.cutoffPercentage
        ? AppColors.green
        : AppColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
        upgrade.endDate.year, upgrade.endDate.month, upgrade.endDate.day);
    final remaining = end.difference(today).inDays;

    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score', style: theme.textTheme.titleMedium),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _trackingColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _trackingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _trackingColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${(score * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: _trackingColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final barColor = upgrade.status == 'failed'
                    ? AppColors.red
                    : upgrade.status == 'completed'
                        ? AppColors.green
                        : upgradeColor;

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: score.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (width * upgrade.cutoffPercentage.clamp(0.0, 1.0)) - 0.5,
                      top: -2,
                      bottom: -2,
                      child: Container(
                        width: 1,
                        decoration: BoxDecoration(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(0.5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cutoff: ${(upgrade.cutoffPercentage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (upgrade.status == 'active')
                Text(
                  remaining < 0
                      ? 'Overdue'
                      : remaining == 0
                          ? 'Ends today'
                          : '$remaining day${remaining == 1 ? '' : 's'} left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: remaining < 0
                        ? AppColors.red
                        : AppColors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestones
// ---------------------------------------------------------------------------

class _MilestonesSection extends StatelessWidget {
  final double score;
  final Color upgradeColor;

  const _MilestonesSection({
    required this.score,
    required this.upgradeColor,
  });

  @override
  Widget build(BuildContext context) {
    const milestones = [0.25, 0.50, 0.75, 1.0];
    const milestoneLabels = ['25%', '50%', '75%', '100%'];

    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Milestones',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 14,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 14,
                      child: Container(
                        height: 4,
                        width: width * score.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: upgradeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    for (var i = 0; i < milestones.length; i++)
                      Positioned(
                        left: (width - 24) * milestones[i],
                        top: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: score >= milestones[i]
                                    ? upgradeColor
                                    : Theme.of(context).dividerColor,
                                border: Border.all(
                                  color: score >= milestones[i]
                                      ? upgradeColor
                                      : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: score >= milestones[i]
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              milestoneLabels[i],
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: score >= milestones[i]
                                        ? upgradeColor
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Final Result (completed / failed)
// ---------------------------------------------------------------------------

class _FinalResultSection extends StatelessWidget {
  final UpgradeGroup upgrade;

  const _FinalResultSection({required this.upgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = upgrade.status == 'completed';
    final color = passed ? AppColors.green : AppColors.red;

    return CardShell(
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              passed ? Icons.emoji_events_rounded : Icons.close_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Upgrade Completed!' : 'Upgrade Failed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Final score: ${((upgrade.completionScore ?? 0) * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          if (upgrade.xpAwarded != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${upgrade.xpAwarded} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-Habit Contribution
// ---------------------------------------------------------------------------

class _HabitContributionSection extends StatelessWidget {
  final UpgradeGroup upgrade;
  final List<UpgradeHabit> memberships;
  final List<Habit> allHabits;
  final List<HabitEntry> entries;
  final Color upgradeColor;
  final WidgetRef ref;

  const _HabitContributionSection({
    required this.upgrade,
    required this.memberships,
    required this.allHabits,
    required this.entries,
    required this.upgradeColor,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMemberships = memberships.where((m) => m.leftDate == null).toList();
    final pastMemberships = memberships.where((m) => m.leftDate != null).toList();
    final isActive = upgrade.status == 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habits (${activeMemberships.length})',
                style: theme.textTheme.titleMedium,
              ),
              if (isActive)
                FilledButton.tonalIcon(
                  onPressed: () => _showAddHabitDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Habit'),
                ),
            ],
          ),
        ),
        if (activeMemberships.isEmpty && pastMemberships.isEmpty)
          CardShell(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.add_task_rounded,
                        size: 36, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(height: 8),
                    Text(
                      'No habits linked yet',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ...activeMemberships.map((m) => _buildHabitTile(context, m, active: true)),
          if (pastMemberships.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Past Members',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...pastMemberships.map((m) => _buildHabitTile(context, m, active: false)),
          ],
        ],
      ],
    );
  }

  Widget _buildHabitTile(BuildContext context, UpgradeHabit membership,
      {required bool active}) {
    final theme = Theme.of(context);
    final habit = allHabits.where((h) => h.id == membership.habitId).firstOrNull;
    if (habit == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    var windowStart = membership.joinedDate;
    var windowEnd = membership.leftDate ?? upgrade.endDate;
    if (windowEnd.isAfter(todayDate)) windowEnd = todayDate;

    final scheduled = XpCalculator.countScheduledDays(
      windowStart,
      windowEnd,
      habit.frequency,
      habit.frequencyConfig,
    );
    final completed = XpCalculator.countCompletedEntries(
      habit.id,
      windowStart,
      windowEnd,
      entries,
    );
    final habitScore = scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 0.0;
    final isActive = upgrade.status == 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardShell(
        onTap: () => GoRouter.of(context).go('/habits/${habit.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: upgradeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: upgradeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completed / $scheduled days  ·  ${(habitScore * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: habitScore,
                      minHeight: 4,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(habit.color)),
                    ),
                  ),
                ],
              ),
            ),
            if (active && isActive) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                color: AppColors.red.withValues(alpha: 0.7),
                tooltip: 'Remove from upgrade',
                onPressed: () => _removeHabit(context, habit.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeHabit(BuildContext context, String habitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Habit'),
        content: const Text(
            'Remove this habit from the upgrade? Its past contributions are preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(gamificationEngineProvider)
          .removeHabitFromUpgrade(habitId, upgrade.id);
    }
  }

  void _showAddHabitDialog(BuildContext context) {
    final assignedIds = memberships
        .where((m) => m.leftDate == null)
        .map((m) => m.habitId)
        .toSet();

    final unassigned = allHabits
        .where((h) => !h.archived && !assignedIds.contains(h.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Habit', style: theme.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          GoRouter.of(context).go('/habits/new');
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (unassigned.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'All habits are already assigned.\nCreate a new one!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: unassigned.length,
                        itemBuilder: (context, index) {
                          final habit = unassigned[index];
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(habit.color)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                IconData(habit.iconCodePoint,
                                    fontFamily: 'MaterialIcons'),
                                color: Color(habit.color),
                                size: 20,
                              ),
                            ),
                            title: Text(habit.name),
                            subtitle: Text(
                                '${habit.frequency} · ${habit.difficulty}'),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () async {
                              Navigator.pop(context);
                              await ref
                                  .read(gamificationEngineProvider)
                                  .addHabitToUpgrade(
                                      habit.id, upgrade.id);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
