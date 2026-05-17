import 'package:flutter/cupertino.dart';
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AppShell(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upgrades',
                builder: (context, state) => const UpgradesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) => CupertinoPage(
                      key: state.pageKey,
                      child: const UpgradeFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => CupertinoPage(
                      key: state.pageKey,
                      child: UpgradeDetailScreen(upgradeId: state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (context, state) => CupertinoPage(
                          key: state.pageKey,
                          child: UpgradeFormScreen(upgradeId: state.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (context, state) => const HabitsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) => CupertinoPage(
                      key: state.pageKey,
                      child: const HabitFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => CupertinoPage(
                      key: state.pageKey,
                      child: HabitDetailScreen(habitId: state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (context, state) => CupertinoPage(
                          key: state.pageKey,
                          child: HabitFormScreen(habitId: state.pathParameters['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upgrade-ai',
                builder: (context, state) => const UpgradeAIScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const AISettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Independent routes
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
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
    ],
  );
});
