import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'datasources/local/local_storage.dart';
import 'repositories/user_repository_impl.dart';
import 'repositories/habit_repository_impl.dart';
import 'repositories/upgrade_repository_impl.dart';
import 'repositories/upgrade_habit_repository_impl.dart';
import 'repositories/goal_repository_impl.dart';
import 'repositories/achievement_repository_impl.dart';
import 'repositories/timeline_repository_impl.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/habit.dart';
import '../domain/entities/habit_entry.dart';
import '../domain/entities/upgrade_group.dart';
import '../domain/entities/upgrade_habit.dart';
import '../domain/entities/goal.dart';
import '../domain/entities/achievement.dart';
import '../domain/entities/timeline_event.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/repositories/upgrade_repository.dart';
import '../domain/repositories/upgrade_habit_repository.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/achievement_repository.dart';
import '../domain/repositories/timeline_repository.dart';
import '../core/utils/xp_calculator.dart';
import '../core/constants/app_constants.dart';

// --- Infrastructure ---

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  return LocalStorage.getInstance();
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// --- Repositories ---

final userRepoProvider = FutureProvider<UserRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return UserRepositoryImpl(storage);
});

final habitRepoProvider = FutureProvider<HabitRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return HabitRepositoryImpl(storage);
});

final upgradeRepoProvider = FutureProvider<UpgradeRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return UpgradeRepositoryImpl(storage);
});

final upgradeHabitRepoProvider = FutureProvider<UpgradeHabitRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return UpgradeHabitRepositoryImpl(storage);
});

final goalRepoProvider = FutureProvider<GoalRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return GoalRepositoryImpl(storage);
});

final achievementRepoProvider = FutureProvider<AchievementRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return AchievementRepositoryImpl(storage);
});

final timelineRepoProvider = FutureProvider<TimelineRepository>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return TimelineRepositoryImpl(storage);
});

// --- Theme ---

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    final isDark = prefs.getBool('isDarkMode') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await _ref.read(sharedPrefsProvider.future);
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }
}

// --- User Profile ---

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(userRepoProvider.future);
      final profile = await repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(UserProfile profile) async {
    final repo = await _ref.read(userRepoProvider.future);
    await repo.saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> addXp(int xp) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newTotalXp = current.totalXp + xp;
    final newLevel = XpCalculator.levelFromTotalXp(newTotalXp);
    final newRank = AppConstants.getRank(newLevel);
    final updated = current.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
      rank: newRank,
    );
    await save(updated);
  }

  Future<void> updateStreak(int streak) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newLongest = streak > current.longestStreak ? streak : current.longestStreak;
    final updated = current.copyWith(
      currentStreak: streak,
      longestStreak: newLongest,
    );
    await save(updated);
  }
}

// --- Habits ---

final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitsNotifier(ref);
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final Ref _ref;
  HabitsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(habitRepoProvider.future);
      final habits = await repo.getAllHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(Habit habit) async {
    final repo = await _ref.read(habitRepoProvider.future);
    await repo.saveHabit(habit);
    await load();
  }

  Future<void> delete(String id) async {
    final repo = await _ref.read(habitRepoProvider.future);
    await repo.deleteHabit(id);
    await load();
  }

  Future<void> toggleArchive(String id) async {
    final repo = await _ref.read(habitRepoProvider.future);
    final habit = await repo.getHabit(id);
    if (habit != null) {
      await repo.saveHabit(habit.copyWith(archived: !habit.archived));
      await load();
    }
  }
}

// --- Habit Entries ---

final habitEntriesProvider = StateNotifierProvider<HabitEntriesNotifier, AsyncValue<List<HabitEntry>>>((ref) {
  return HabitEntriesNotifier(ref);
});

class HabitEntriesNotifier extends StateNotifier<AsyncValue<List<HabitEntry>>> {
  final Ref _ref;
  HabitEntriesNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(habitRepoProvider.future);
      final entries = await repo.getAllEntries();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(HabitEntry entry) async {
    final repo = await _ref.read(habitRepoProvider.future);
    await repo.saveEntry(entry);
    await load();
  }

  Future<void> delete(String id) async {
    final repo = await _ref.read(habitRepoProvider.future);
    await repo.deleteEntry(id);
    await load();
  }
}

// --- Upgrades ---

final upgradesProvider = StateNotifierProvider<UpgradesNotifier, AsyncValue<List<UpgradeGroup>>>((ref) {
  return UpgradesNotifier(ref);
});

// --- Upgrade Habits (memberships) ---

final upgradeHabitsProvider = StateNotifierProvider<UpgradeHabitsNotifier, AsyncValue<List<UpgradeHabit>>>((ref) {
  return UpgradeHabitsNotifier(ref);
});

class UpgradeHabitsNotifier extends StateNotifier<AsyncValue<List<UpgradeHabit>>> {
  final Ref _ref;
  UpgradeHabitsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(upgradeHabitRepoProvider.future);
      final memberships = await repo.getAll();
      state = AsyncValue.data(memberships);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(UpgradeHabit membership) async {
    final repo = await _ref.read(upgradeHabitRepoProvider.future);
    await repo.save(membership);
    await load();
  }
}

class UpgradesNotifier extends StateNotifier<AsyncValue<List<UpgradeGroup>>> {
  final Ref _ref;
  UpgradesNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(upgradeRepoProvider.future);
      final upgrades = await repo.getAllUpgrades();
      state = AsyncValue.data(upgrades);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(UpgradeGroup upgrade) async {
    final repo = await _ref.read(upgradeRepoProvider.future);
    await repo.saveUpgrade(upgrade);
    await load();
  }

  Future<void> delete(String id) async {
    final repo = await _ref.read(upgradeRepoProvider.future);
    await repo.deleteUpgrade(id);
    await load();
  }
}

// --- Goals ---

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalsNotifier(ref);
});

class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final Ref _ref;
  GoalsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(goalRepoProvider.future);
      final goals = await repo.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(Goal goal) async {
    final repo = await _ref.read(goalRepoProvider.future);
    await repo.saveGoal(goal);
    await load();
  }

  Future<void> delete(String id) async {
    final repo = await _ref.read(goalRepoProvider.future);
    await repo.deleteGoal(id);
    await load();
  }
}

// --- Achievements ---

final achievementsProvider = StateNotifierProvider<AchievementsNotifier, AsyncValue<List<Achievement>>>((ref) {
  return AchievementsNotifier(ref);
});

class AchievementsNotifier extends StateNotifier<AsyncValue<List<Achievement>>> {
  final Ref _ref;
  AchievementsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(achievementRepoProvider.future);
      final achievements = await repo.getUnlockedAchievements();
      state = AsyncValue.data(achievements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unlock(Achievement achievement) async {
    final repo = await _ref.read(achievementRepoProvider.future);
    await repo.unlockAchievement(achievement);
    await load();
  }
}

// --- Timeline ---

final timelineProvider = StateNotifierProvider<TimelineNotifier, AsyncValue<List<TimelineEvent>>>((ref) {
  return TimelineNotifier(ref);
});

class TimelineNotifier extends StateNotifier<AsyncValue<List<TimelineEvent>>> {
  final Ref _ref;
  TimelineNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final repo = await _ref.read(timelineRepoProvider.future);
      final events = await repo.getAllEvents();
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEvent(TimelineEvent event) async {
    final repo = await _ref.read(timelineRepoProvider.future);
    await repo.addEvent(event);
    await load();
  }
}

// --- Derived / computed providers ---

final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider);
  return habits.valueOrNull?.where((h) => !h.archived).toList() ?? [];
});

final todayEntriesProvider = Provider<List<HabitEntry>>((ref) {
  final entries = ref.watch(habitEntriesProvider);
  final now = DateTime.now();
  return entries.valueOrNull?.where((e) =>
    e.date.year == now.year && e.date.month == now.month && e.date.day == now.day
  ).toList() ?? [];
});

final todayCompletionProvider = Provider<double>((ref) {
  final habits = ref.watch(todayHabitsProvider);
  final entries = ref.watch(todayEntriesProvider);
  if (habits.isEmpty) return 0.0;
  final completedIds = entries.where((e) => e.completed).map((e) => e.habitId).toSet();
  final completed = habits.where((h) => completedIds.contains(h.id)).length;
  return completed / habits.length;
});

final recentTimelineProvider = Provider<List<TimelineEvent>>((ref) {
  final events = ref.watch(timelineProvider);
  final list = events.valueOrNull ?? [];
  final sorted = List<TimelineEvent>.from(list)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return sorted.take(5).toList();
});

final activeUpgradesProvider = Provider<List<UpgradeGroup>>((ref) {
  final upgrades = ref.watch(upgradesProvider);
  return upgrades.valueOrNull?.where((u) => u.status == 'active').toList() ?? [];
});

final dueUpgradesProvider = Provider<List<UpgradeGroup>>((ref) {
  final active = ref.watch(activeUpgradesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return active.where((u) {
    final end = DateTime(u.endDate.year, u.endDate.month, u.endDate.day);
    return !end.isAfter(today);
  }).toList();
});

final liveUpgradeScoreProvider = Provider.family<double, String>((ref, upgradeId) {
  final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];
  final memberships = ref.watch(upgradeHabitsProvider).valueOrNull ?? [];
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];
  final entries = ref.watch(habitEntriesProvider).valueOrNull ?? [];

  final upgrade = upgrades.where((u) => u.id == upgradeId).firstOrNull;
  if (upgrade == null) return 0.0;

  final upgradeMemberships = memberships.where((m) => m.upgradeId == upgradeId).toList();
  return XpCalculator.computeUpgradeScore(upgrade, upgradeMemberships, habits, entries);
});

final upgradeHabitsForUpgradeProvider = Provider.family<List<UpgradeHabit>, String>((ref, upgradeId) {
  final memberships = ref.watch(upgradeHabitsProvider).valueOrNull ?? [];
  return memberships.where((m) => m.upgradeId == upgradeId).toList();
});
