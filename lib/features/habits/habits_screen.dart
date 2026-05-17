import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../data/providers.dart';
import '../../domain/entities/habit.dart';
import 'widgets/habit_card.dart';

enum _HabitFilter { all, active, archived }

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> with AutomaticKeepAliveClientMixin {
  _HabitFilter _filter = _HabitFilter.active;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final habitsAsync = ref.watch(habitsProvider);
    final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];

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
            : const Text(AppStrings.habitsTab),
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
        label: const Text(AppStrings.newHabit),
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
            child: AsyncValueWidget(
              value: habitsAsync,
              data: (habits) {
                final filtered = _applyFilters(habits);

                if (filtered.isEmpty) {
                  final (icon, title, subtitle) = _searchQuery.isNotEmpty
                      ? (Icons.search_off_rounded, AppStrings.noMatchesTitle, AppStrings.noMatchesSubtitle)
                      : switch (_filter) {
                          _HabitFilter.all => (Icons.rocket_launch_rounded, AppStrings.noHabitsTitle, AppStrings.noHabitsSubtitle),
                          _HabitFilter.active => (Icons.check_circle_outline_rounded, 'No active habits', 'All your habits are archived.'),
                          _HabitFilter.archived => (Icons.archive_outlined, 'No archived habits', 'Your archived habits will appear here.'),
                        };
                  return AppEmptyState(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  );
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
