import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../data/providers.dart';
import '../../domain/entities/habit.dart';
import 'widgets/habit_card.dart';

enum _HabitFilter { all, active, archived }

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  _HabitFilter _filter = _HabitFilter.active;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Habit> _applyFilters(List<Habit> habits) {
    var filtered = switch (_filter) {
      _HabitFilter.all => habits,
      _HabitFilter.active => habits.where((h) => !h.archived).toList(),
      _HabitFilter.archived => habits.where((h) => h.archived).toList(),
    };

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((h) =>
              h.name.toLowerCase().contains(query) ||
              h.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search habits...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Habits'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/habits/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _HabitFilter.values.map((f) {
                final label = switch (f) {
                  _HabitFilter.all => 'All',
                  _HabitFilter.active => 'Active',
                  _HabitFilter.archived => 'Archived',
                };
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text('Failed to load habits',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(habitsProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (habits) {
                final filtered = _applyFilters(habits);

                if (filtered.isEmpty) {
                  return _EmptyState(filter: _filter, hasSearch: _searchQuery.isNotEmpty);
                }

                final upgradeColorMap = <String, int>{};
                for (final u in upgrades) {
                  upgradeColorMap[u.id] = u.color;
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final habit = filtered[index];
                    final upgrade = upgrades
                        .where((u) => u.id == habit.upgradeId)
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HabitCard(
                        habit: habit,
                        upgradeName: upgrade?.name,
                        upgradeColor: upgrade != null ? Color(upgrade.color) : null,
                        onTap: () => context.go('/habits/${habit.id}'),
                      ),
                    ).animate().fadeIn(
                          duration: 250.ms,
                          delay: (40 * index).ms,
                        );
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
  final _HabitFilter filter;
  final bool hasSearch;

  const _EmptyState({required this.filter, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = hasSearch
        ? (Icons.search_off_rounded, 'No matches', 'Try a different search term')
        : switch (filter) {
            _HabitFilter.all => (
                Icons.rocket_launch_rounded,
                'No habits yet',
                'Create your first habit to start leveling up!'
              ),
            _HabitFilter.active => (
                Icons.check_circle_outline_rounded,
                'No active habits',
                'All your habits are archived, or create a new one'
              ),
            _HabitFilter.archived => (
                Icons.archive_rounded,
                'No archived habits',
                'Archived habits will appear here'
              ),
          };
    final useAppLogo = !hasSearch && filter == _HabitFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            useAppLogo
                ? AppLogoIcon(size: 48, color: theme.textTheme.bodySmall?.color ?? Colors.grey)
                : Icon(icon, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
