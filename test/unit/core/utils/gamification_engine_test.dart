import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/core/utils/gamification_engine.dart';
import 'package:upgrade/data/providers.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/habit_entry.dart';
import 'package:upgrade/domain/entities/user_profile.dart';
import 'package:upgrade/domain/entities/achievement.dart';
import 'package:upgrade/domain/entities/timeline_event.dart';
import 'package:upgrade/domain/repositories/achievement_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockHabitsNotifier extends HabitsNotifier {
  Habit? savedHabit;
  final List<Habit> initialHabits;
  MockHabitsNotifier({this.initialHabits = const []});

  @override
  FutureOr<List<Habit>> build() => initialHabits;
  
  @override
  Future<void> save(Habit habit) async { 
    savedHabit = habit;
    state = AsyncValue.data([
      ...state.valueOrNull?.where((h) => h.id != habit.id) ?? [],
      habit
    ]);
  }
}

class MockHabitEntriesNotifier extends HabitEntriesNotifier {
  HabitEntry? savedEntry;
  final List<HabitEntry> initialEntries;
  MockHabitEntriesNotifier({this.initialEntries = const []});

  @override
  FutureOr<List<HabitEntry>> build() => initialEntries;
  
  @override
  Future<void> save(HabitEntry entry) async { 
    savedEntry = entry;
    state = AsyncValue.data([
      ...state.valueOrNull ?? [],
      entry
    ]);
  }
}

class MockUserProfileNotifier extends UserProfileNotifier {
  int addedXp = 0;
  final UserProfile? initialProfile;
  MockUserProfileNotifier({this.initialProfile});

  @override
  FutureOr<UserProfile?> build() => initialProfile;
  
  @override
  Future<void> addXp(int xp) async { 
    addedXp += xp;
    if (state.valueOrNull != null) {
      state = AsyncValue.data(state.valueOrNull!.copyWith(totalXp: state.valueOrNull!.totalXp + xp));
    }
  }

  @override
  Future<void> updateStreak(int streak) async {}
}

class MockTimelineNotifier extends TimelineNotifier {
  @override
  FutureOr<List<TimelineEvent>> build() => [];
  @override
  Future<void> addEvent(TimelineEvent event) async {}
}

class MockAchievementsNotifier extends AchievementsNotifier {
  @override
  FutureOr<List<Achievement>> build() => [];
  @override
  Future<void> unlock(Achievement achievement) async {}
}

class MockAchievementRepository extends Mock implements AchievementRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late GamificationEngine engine;
  late MockHabitsNotifier mockHabitsNotifier;
  late MockHabitEntriesNotifier mockHabitEntriesNotifier;
  late MockUserProfileNotifier mockUserProfileNotifier;
  late MockAchievementRepository mockAchievementRepo;

  setUp(() {
    mockHabitsNotifier = MockHabitsNotifier();
    mockHabitEntriesNotifier = MockHabitEntriesNotifier(initialEntries: []);
    mockUserProfileNotifier = MockUserProfileNotifier(
      initialProfile: UserProfile(username: 'test', totalXp: 100)
    );
    mockAchievementRepo = MockAchievementRepository();
    when(() => mockAchievementRepo.isUnlocked(any())).thenAnswer((_) async => false);

    container = ProviderContainer(
      overrides: [
        habitsProvider.overrideWith(() => mockHabitsNotifier),
        habitEntriesProvider.overrideWith(() => mockHabitEntriesNotifier),
        userProfileProvider.overrideWith(() => mockUserProfileNotifier),
        timelineProvider.overrideWith(() => MockTimelineNotifier()),
        achievementsProvider.overrideWith(() => MockAchievementsNotifier()),
        achievementRepoProvider.overrideWith((ref) async => mockAchievementRepo),
      ],
    );
    engine = container.read(gamificationEngineProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('GamificationEngine', () {
    test('completeHabit saves entry and updates XP', () async {
      final habit = Habit(
        id: 'h1',
        name: 'Exercise',
        upgradeId: 'u1',
        difficulty: 'medium',
        currentStreak: 0,
        longestStreak: 0,
      );

      await engine.completeHabit(habit);

      expect(mockHabitEntriesNotifier.savedEntry, isNotNull);
      expect(mockHabitEntriesNotifier.savedEntry?.habitId, 'h1');
      expect(mockHabitsNotifier.savedHabit, isNotNull);
      expect(mockHabitsNotifier.savedHabit?.currentStreak, 1);
      expect(mockUserProfileNotifier.addedXp, 30); // medium = 30 XP
    });
  });
}
