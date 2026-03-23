import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../features/shell/app_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/launch_animation_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/habits/habit_detail_screen.dart';
import '../../features/habits/habit_form_screen.dart';
import '../../features/upgrades/upgrades_screen.dart';
import '../../features/upgrades/upgrade_detail_screen.dart';
import '../../features/upgrades/upgrade_form_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/goals/goal_form_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/upgrade_ai/upgrade_ai_screen.dart';
import '../../features/upgrade_ai/ai_settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/level_roadmap_screen.dart';
import '../../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userProfile = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasProfile = userProfile.valueOrNull != null;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasProfile && !isOnboarding) return '/onboarding';
      if (hasProfile && isOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/launch',
        builder: (context, state) => const LaunchAnimationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const HabitFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => HabitDetailScreen(habitId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => HabitFormScreen(habitId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/upgrades',
            builder: (context, state) => const UpgradesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const UpgradeFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => UpgradeDetailScreen(upgradeId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => UpgradeFormScreen(upgradeId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const GoalFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => GoalFormScreen(goalId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: '/upgrade-ai',
            builder: (context, state) => const UpgradeAIScreen(),
          ),
          GoRoute(
            path: '/upgrade-ai/settings',
            builder: (context, state) => const AISettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/level-roadmap',
            builder: (context, state) => const LevelRoadmapScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
