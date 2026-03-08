import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../data/providers.dart';
import '../../domain/entities/goal.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/goals/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text('Failed to load goals',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.read(goalsProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (goals) {
          final filtered = _filter == 'all'
              ? goals
              : goals.where((g) => g.status == _filter).toList();

          return Column(
            children: [
              _FilterChips(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                counts: {
                  'all': goals.length,
                  'active': goals.where((g) => g.status == 'active').length,
                  'completed':
                      goals.where((g) => g.status == 'completed').length,
                  'expired':
                      goals.where((g) => g.status == 'expired').length,
                },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyGoals(hasAnyGoals: goals.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final goal = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalCard(
                              goal: goal,
                              onTap: () =>
                                  context.go('/goals/${goal.id}/edit'),
                            ),
                          ).animate().fadeIn(duration: 250.ms);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, int> counts;

  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  static const _filters = ['all', 'active', 'completed', 'expired'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _filters.map((f) {
          final isSelected = f == selected;
          final count = counts[f] ?? 0;
          final label =
              '${f[0].toUpperCase()}${f.substring(1)} ($count)';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(label),
              onSelected: (_) => onChanged(f),
              selectedColor: _statusColor(f).withValues(alpha: 0.2),
              checkmarkColor: _statusColor(f),
              side: isSelected
                  ? BorderSide(color: _statusColor(f), width: 1.5)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.blue;
    case 'completed':
      return AppColors.green;
    case 'expired':
      return AppColors.red;
    default:
      return AppColors.blue;
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(goal.status);
    final hasDeadline = goal.targetDate != null;
    final remaining = hasDeadline
        ? goal.targetDate!.difference(DateTime.now())
        : null;
    final totalLinked = goal.linkedHabitIds.length + goal.linkedUpgradeIds.length;

    return CardShell(
      onTap: onTap,
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: goal.status),
            ],
          ),
          if (goal.outcomeDescription != null &&
              goal.outcomeDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              goal.outcomeDescription!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          if (totalLinked > 0)
            _ProgressIndicator(goal: goal, color: color),
          if (totalLinked > 0) const SizedBox(height: 10),
          Row(
            children: [
              if (hasDeadline) ...[
                Icon(Icons.schedule_rounded,
                    size: 15, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 4),
                Text(
                  remaining!.isNegative
                      ? 'Overdue'
                      : remaining.inDays == 0
                          ? 'Due today'
                          : '${remaining.inDays}d left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: remaining.isNegative
                        ? AppColors.red
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Icon(Icons.link_rounded,
                  size: 15, color: theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 4),
              Text(
                '$totalLinked linked',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final Goal goal;
  final Color color;

  const _ProgressIndicator({required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    final total =
        goal.linkedHabitIds.length + goal.linkedUpgradeIds.length;
    if (total == 0) return const SizedBox.shrink();

    final fraction = goal.status == 'completed' ? 1.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.layers_rounded,
                size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 4),
            Text(
              '${goal.linkedHabitIds.length} habit${goal.linkedHabitIds.length == 1 ? '' : 's'}, '
              '${goal.linkedUpgradeIds.length} upgrade${goal.linkedUpgradeIds.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final bool hasAnyGoals;

  const _EmptyGoals({required this.hasAnyGoals});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyGoals
                  ? Icons.filter_list_off_rounded
                  : Icons.flag_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 24),
            Text(
              hasAnyGoals ? 'No goals match this filter' : 'No goals yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyGoals
                  ? 'Try selecting a different filter above.'
                  : 'Set a goal to give your habits\na sense of direction.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(
            begin: const Offset(0.95, 0.95),
            duration: 250.ms,
            curve: Curves.easeOutCubic);
  }
}
