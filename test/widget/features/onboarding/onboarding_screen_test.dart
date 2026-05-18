import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/features/onboarding/onboarding_screen.dart';
import 'package:upgrade/data/providers.dart';
import 'package:upgrade/domain/entities/user_profile.dart';
import 'package:upgrade/domain/entities/habit.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';
import 'package:upgrade/domain/entities/timeline_event.dart';
import 'package:upgrade/domain/entities/upgrade_habit.dart';

class MockUserProfileNotifier extends UserProfileNotifier {
  @override
  FutureOr<UserProfile?> build() => null;
}

class MockHabitsNotifier extends HabitsNotifier {
  @override
  FutureOr<List<Habit>> build() => [];
}

class MockUpgradesNotifier extends UpgradesNotifier {
  @override
  FutureOr<List<UpgradeGroup>> build() => [];
}

class MockUpgradeHabitsNotifier extends UpgradeHabitsNotifier {
  @override
  FutureOr<List<UpgradeHabit>> build() => [];
}

class MockTimelineNotifier extends TimelineNotifier {
  @override
  FutureOr<List<TimelineEvent>> build() => [];
}

void main() {
  testWidgets('OnboardingScreen displays welcome message', (WidgetTester tester) async {
    // Shorter duration for animations in tests if possible, 
    // but here we just wait for them to finish.
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => MockUserProfileNotifier()),
          habitsProvider.overrideWith(() => MockHabitsNotifier()),
          upgradesProvider.overrideWith(() => MockUpgradesNotifier()),
          upgradeHabitsProvider.overrideWith(() => MockUpgradeHabitsNotifier()),
          timelineProvider.overrideWith(() => MockTimelineNotifier()),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Initial pump to trigger build
    await tester.pump();
    
    // Onboarding has many animations (flutter_animate). 
    // pumpAndSettle might timeout due to repeating animations (shimmer/arrows).
    // We pump for a few frames to let initial animations trigger.
    
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    
    // Check for welcome text
    expect(find.text('UPGRADE'), findsOneWidget);
    expect(find.text('SWIPE UP TO START'), findsOneWidget);
  });
}
