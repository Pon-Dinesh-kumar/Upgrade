import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../domain/entities/timeline_event.dart';
import 'widgets/timeline_item.dart';

enum _TimelineFilter {
  all,
  completions,
  streaks,
  levelUps,
  achievements,
  goals,
}

const _filterTypeMap = <_TimelineFilter, Set<String>>{
  _TimelineFilter.completions: {'habit_complete'},
  _TimelineFilter.streaks: {'streak_milestone'},
  _TimelineFilter.levelUps: {'level_up', 'upgrade_level_up'},
  _TimelineFilter.achievements: {'achievement_unlock'},
  _TimelineFilter.goals: {'goal_complete'},
};

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  List<TimelineEvent> _applyFilter(List<TimelineEvent> events) {
    if (_filter == _TimelineFilter.all) return events;
    final types = _filterTypeMap[_filter] ?? {};
    return events.where((e) => types.contains(e.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _TimelineFilter.values.map((f) {
                final label = switch (f) {
                  _TimelineFilter.all => 'All',
                  _TimelineFilter.completions => 'Completions',
                  _TimelineFilter.streaks => 'Streaks',
                  _TimelineFilter.levelUps => 'Level Ups',
                  _TimelineFilter.achievements => 'Achievements',
                  _TimelineFilter.goals => 'Goals',
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text('Failed to load timeline',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(timelineProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                final sorted = List<TimelineEvent>.from(events)
                  ..sort(
                      (a, b) => b.timestamp.compareTo(a.timestamp));
                final filtered = _applyFilter(sorted);

                if (filtered.isEmpty) {
                  return _EmptyState(hasFilter: _filter != _TimelineFilter.all);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TimelineItem(
                        event: filtered[index],
                        isFirst: index == 0,
                        isLast: index == filtered.length - 1,
                      ),
                    ).animate().fadeIn(duration: 250.ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final icon =
        hasFilter ? Icons.filter_list_off_rounded : Icons.timeline_rounded;
    final title = hasFilter ? 'No matching events' : 'No events yet';
    final subtitle = hasFilter
        ? 'Try selecting a different filter'
        : 'Complete habits and reach milestones to fill your timeline!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 250.ms).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 250.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}
