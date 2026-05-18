import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/habits/habit_detail_screen.dart';
import 'package:upgrade/data/providers.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/habit_entry.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';

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

void main() {
  testWidgets('HabitDetailScreen displays habit info', (WidgetTester tester) async {
    final habit = Habit(
      id: 'h1',
      name: 'Reading',
      upgradeId: 'u1',
      currentStreak: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith(() => MockHabitsNotifier([habit])),
          habitEntriesProvider.overrideWith(() => MockHabitEntriesNotifier([])),
          upgradesProvider.overrideWith(() => MockUpgradesNotifier([])),
        ],
        child: const MaterialApp(
          home: HabitDetailScreen(habitId: 'h1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify habit name is in the app bar
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Reading')),
      findsOneWidget,
    );
    
    // Verify streak stats are shown
    expect(find.text('Current Streak'), findsOneWidget);
    // Find the '3' that is near 'Current Streak'
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Current Streak'), matching: find.byType(Column)).first,
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });
}
