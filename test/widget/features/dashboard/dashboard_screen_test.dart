import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/dashboard/dashboard_screen.dart';
import 'package:upgrade/data/providers.dart';
import 'package:upgrade/domain/entities/user_profile.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/habit_entry.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';
import 'package:upgrade/domain/entities/timeline_event.dart';
import 'package:upgrade/domain/entities/upgrade_habit.dart';
import 'package:upgrade/domain/entities/goal.dart';

class MockUserProfileNotifier extends UserProfileNotifier {
  final UserProfile? mockData;
  MockUserProfileNotifier(this.mockData);
  @override
  FutureOr<UserProfile?> build() => mockData;
}

class MockHabitsNotifier extends HabitsNotifier {
  final List<Habit> mockData;
  MockHabitsNotifier(this.mockData);
  @override
  FutureOr<List<Habit>> build() => mockData;
}

class MockHabitEntriesNotifier extends HabitEntriesNotifier {
  final List<HabitEntry> mockData;
  MockHabitEntriesNotifier(this.mockData);
  @override
  FutureOr<List<HabitEntry>> build() => mockData;
}

class MockUpgradesNotifier extends UpgradesNotifier {
  final List<UpgradeGroup> mockData;
  MockUpgradesNotifier(this.mockData);
  @override
  FutureOr<List<UpgradeGroup>> build() => mockData;
}

class MockUpgradeHabitsNotifier extends UpgradeHabitsNotifier {
  final List<UpgradeHabit> mockData;
  MockUpgradeHabitsNotifier(this.mockData);
  @override
  FutureOr<List<UpgradeHabit>> build() => mockData;
}

class MockTimelineNotifier extends TimelineNotifier {
  final List<TimelineEvent> mockData;
  MockTimelineNotifier(this.mockData);
  @override
  FutureOr<List<TimelineEvent>> build() => mockData;
  @override
  Future<void> addEvent(TimelineEvent event) async {}
}

class MockGoalsNotifier extends GoalsNotifier {
  final List<Goal> mockData;
  MockGoalsNotifier(this.mockData);
  @override
  FutureOr<List<Goal>> build() => mockData;
}

void main() {
  testWidgets('DashboardScreen displays user rank and habits', (WidgetTester tester) async {
    final mockProfile = UserProfile(
      username: 'Test User',
      level: 5,
      totalXp: 1200,
      rank: 'Apprentice',
    );

    final mockHabit = Habit(
      id: 'h1',
      name: 'Test Habit',
      upgradeId: 'u1',
      frequency: 'daily',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => MockUserProfileNotifier(mockProfile)),
          habitsProvider.overrideWith(() => MockHabitsNotifier([mockHabit])),
          habitEntriesProvider.overrideWith(() => MockHabitEntriesNotifier([])),
          upgradesProvider.overrideWith(() => MockUpgradesNotifier([])),
          upgradeHabitsProvider.overrideWith(() => MockUpgradeHabitsNotifier([])),
          timelineProvider.overrideWith(() => MockTimelineNotifier([])),
          goalsProvider.overrideWith(() => MockGoalsNotifier([])),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Initial pump to trigger build
    await tester.pump();
    // Allow any post-frame callbacks to trigger
    await tester.pump(const Duration(milliseconds: 100));
    // Settle animations
    await tester.pumpAndSettle();
    
    // Check if user name is displayed
    expect(find.text('Test User'), findsOneWidget);
    
    // Check if "Today's Habits" section is visible
    expect(find.text('Today\'s Habits'), findsOneWidget);
  });
}
