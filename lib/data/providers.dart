import 'dart:async';
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
import '../core/utils/date_utils.dart';
import '../core/utils/gamification_engine.dart';
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

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() async {
    final repo = await ref.watch(userRepoProvider.future);
    return repo.getProfile();
  }

  Future<void> save(UserProfile profile) async {
    final repo = await ref.read(userRepoProvider.future);
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

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  FutureOr<List<Habit>> build() async {
    final repo = await ref.watch(habitRepoProvider.future);
    return repo.getAllHabits();
  }

  Future<void> save(Habit habit) async {
    final repo = await ref.read(habitRepoProvider.future);
    await repo.saveHabit(habit);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(habitRepoProvider.future);
    await repo.deleteHabit(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleArchive(String id) async {
    final repo = await ref.read(habitRepoProvider.future);
    final habit = await repo.getHabit(id);
    if (habit != null) {
      await repo.saveHabit(habit.copyWith(archived: !habit.archived));
      ref.invalidateSelf();
      await future;
    }
  }

  Future<void> saveAll(List<Habit> habits) async {
    final repo = await ref.read(habitRepoProvider.future);
    await repo.saveAllHabits(habits);
    ref.invalidateSelf();
    await future;
  }
}

// --- Habit Entries ---

final habitEntriesProvider = AsyncNotifierProvider<HabitEntriesNotifier, List<HabitEntry>>(() {
  return HabitEntriesNotifier();
});

class HabitEntriesNotifier extends AsyncNotifier<List<HabitEntry>> {
  @override
  FutureOr<List<HabitEntry>> build() async {
    final repo = await ref.watch(habitRepoProvider.future);
    return repo.getAllEntries();
  }

  Future<void> save(HabitEntry entry) async {
    final repo = await ref.read(habitRepoProvider.future);
    await repo.saveEntry(entry);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(habitRepoProvider.future);
    await repo.deleteEntry(id);
    ref.invalidateSelf();
    await future;
  }
}

// --- Upgrades ---

final upgradesProvider = AsyncNotifierProvider<UpgradesNotifier, List<UpgradeGroup>>(() {
  return UpgradesNotifier();
});

class UpgradesNotifier extends AsyncNotifier<List<UpgradeGroup>> {
  @override
  FutureOr<List<UpgradeGroup>> build() async {
    final repo = await ref.watch(upgradeRepoProvider.future);
    return repo.getAllUpgrades();
  }

  Future<void> save(UpgradeGroup upgrade) async {
    final repo = await ref.read(upgradeRepoProvider.future);
    await repo.saveUpgrade(upgrade);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(upgradeRepoProvider.future);
    await repo.deleteUpgrade(id);
    ref.invalidateSelf();
    await future;
  }
}

// --- Upgrade Habits (memberships) ---

final upgradeHabitsProvider = AsyncNotifierProvider<UpgradeHabitsNotifier, List<UpgradeHabit>>(() {
  return UpgradeHabitsNotifier();
});

class UpgradeHabitsNotifier extends AsyncNotifier<List<UpgradeHabit>> {
  @override
  FutureOr<List<UpgradeHabit>> build() async {
    final repo = await ref.watch(upgradeHabitRepoProvider.future);
    return repo.getAll();
  }

  Future<void> save(UpgradeHabit membership) async {
    final repo = await ref.read(upgradeHabitRepoProvider.future);
    await repo.save(membership);
    ref.invalidateSelf();
    await future;
  }

  Future<void> saveAll(List<UpgradeHabit> memberships) async {
    final repo = await ref.read(upgradeHabitRepoProvider.future);
    await repo.saveAll(memberships);
    ref.invalidateSelf();
    await future;
  }
}

// --- Goals ---

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  FutureOr<List<Goal>> build() async {
    final repo = await ref.watch(goalRepoProvider.future);
    return repo.getAllGoals();
  }

  Future<void> save(Goal goal) async {
    final repo = await ref.read(goalRepoProvider.future);
    await repo.saveGoal(goal);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(goalRepoProvider.future);
    await repo.deleteGoal(id);
    ref.invalidateSelf();
    await future;
  }
}

// --- Achievements ---

final achievementsProvider = AsyncNotifierProvider<AchievementsNotifier, List<Achievement>>(() {
  return AchievementsNotifier();
});

class AchievementsNotifier extends AsyncNotifier<List<Achievement>> {
  @override
  FutureOr<List<Achievement>> build() async {
    final repo = await ref.watch(achievementRepoProvider.future);
    return repo.getUnlockedAchievements();
  }

  Future<void> unlock(Achievement achievement) async {
    final repo = await ref.read(achievementRepoProvider.future);
    await repo.unlockAchievement(achievement);
    ref.invalidateSelf();
    await future;
  }
}

// --- Timeline ---

final timelineProvider = AsyncNotifierProvider<TimelineNotifier, List<TimelineEvent>>(() {
  return TimelineNotifier();
});

class TimelineNotifier extends AsyncNotifier<List<TimelineEvent>> {
  @override
  FutureOr<List<TimelineEvent>> build() async {
    final repo = await ref.watch(timelineRepoProvider.future);
    return repo.getAllEvents();
  }

  Future<void> addEvent(TimelineEvent event) async {
    final repo = await ref.read(timelineRepoProvider.future);
    await repo.addEvent(event);
    ref.invalidateSelf();
    await future;
  }
}

final gamificationEngineProvider = Provider<GamificationEngine>((ref) {
  return GamificationEngine(ref);
});

// --- Derived / computed providers ---

final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final habits = habitsAsync.valueOrNull ?? [];
  return habits.where((h) {
    if (h.archived) return false;
    return AppDateUtils.shouldCompleteToday(h.frequency, h.frequencyConfig);
  }).toList();
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
  final habits = ref.watch(habitsProvider).valueOrNull ?? [];
  
  // Filter for memberships in this upgrade where the linked habit exists and is not archived
  return memberships.where((m) => 
    m.upgradeId == upgradeId && 
    habits.any((h) => h.id == m.habitId && !h.archived)
  ).toList();
});
