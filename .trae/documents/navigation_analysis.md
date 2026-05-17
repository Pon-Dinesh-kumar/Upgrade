# Navigation Analysis and Documentation Plan

This document outlines the navigation structure of the Upgrade application, which uses the `go_router` package for routing and `riverpod` for state management.

## Navigation Overview

### 1. Routing Engine
The application uses [go_router](https://pub.dev/packages/go_router) to manage deep linking and route transitions. The main router configuration is located in [app_router.dart](file:///home/kk/Upgrade/lib/core/router/app_router.dart).

### 2. Main Navigation Structure
The app uses a `ShellRoute` to wrap the main functional areas with a persistent navigation interface defined in [app_shell.dart](file:///home/kk/Upgrade/lib/features/shell/app_shell.dart).

#### Root Paths (Tabs)
The application has five primary sections accessible via the bottom navigation bar (mobile) or navigation rail (desktop):
- **Home (`/`)**: [DashboardScreen](file:///home/kk/Upgrade/lib/features/dashboard/dashboard_screen.dart)
- **Habits (`/habits`)**: [HabitsScreen](file:///home/kk/Upgrade/lib/features/habits/habits_screen.dart)
- **Upgrades (`/upgrades`)**: [UpgradesScreen](file:///home/kk/Upgrade/lib/features/upgrades/upgrades_screen.dart)
- **Timeline (`/timeline`)**: [TimelineScreen](file:///home/kk/Upgrade/lib/features/timeline/timeline_screen.dart)
- **Upgrade AI (`/upgrade-ai`)**: [UpgradeAIScreen](file:///home/kk/Upgrade/lib/features/upgrade_ai/upgrade_ai_screen.dart)

#### Onboarding Flow
- **Onboarding (`/onboarding`)**: [OnboardingScreen](file:///home/kk/Upgrade/lib/features/onboarding/onboarding_screen.dart)
- **Launch Animation (`/launch`)**: [LaunchAnimationScreen](file:///home/kk/Upgrade/lib/features/onboarding/launch_animation_screen.dart)

#### Other Key Screens
- **Profile (`/profile`)**: [ProfileScreen](file:///home/kk/Upgrade/lib/features/profile/profile_screen.dart)
- **Settings (`/settings`)**: [SettingsScreen](file:///home/kk/Upgrade/lib/features/settings/settings_screen.dart)
- **Roadmap (`/level-roadmap`)**: [LevelRoadmapScreen](file:///home/kk/Upgrade/lib/features/profile/level_roadmap_screen.dart)

### 3. Nested Routing
Sub-routes are used for CRUD operations and detail views:
- **Habits**: `/habits/new`, `/habits/:id`, `/habits/:id/edit`
- **Upgrades**: `/upgrades/new`, `/upgrades/:id`, `/upgrades/:id/edit`
- **Goals**: `/goals/new`, `/goals/:id/edit`
- **AI Settings**: `/upgrade-ai/settings`

### 4. Implementation Details in `AppShell`
The `AppShell` component handles the responsive layout and tab synchronization:
- **Responsive UI**: Uses `NavigationBar` for small screens and `NavigationRail` for screens wider than 600px.
- **PageView Integration**: For the five root tabs, it uses a `PageView` to enable horizontal swiping.
- **Route Synchronization**: It keeps the `PageView` current page and the `go_router` location in sync.
- **Conditional Rendering**: It automatically switches from the `PageView` to showing the `child` widget directly when navigating to a nested route (like a form or detail screen).

## Navigation Enhancement Plan: Clash Royale Style Swipe Navigation

To achieve the smooth, high-performance swipe navigation seen in apps like Clash Royale, we will refactor the navigation architecture to use `StatefulShellRoute`.

### 1. Architectural Change: `StatefulShellRoute`
Instead of a simple `ShellRoute`, we will use `StatefulShellRoute.indexedStack`. This provides several benefits:
- **State Persistence**: Each tab (Home, Habits, Upgrades, etc.) maintains its own navigation state and scroll position.
- **Smooth Transitions**: It provides a `StatefulNavigationShell` that makes it easier to synchronize the `PageView` with the bottom navigation bar.

### 2. Implementation Steps

#### Step 1: Refactor [app_router.dart](file:///home/kk/Upgrade/lib/core/router/app_router.dart)
- Replace `ShellRoute` with `StatefulShellRoute.indexedStack`.
- Define five `StatefulShellBranch` objects, one for each main tab.
- Each branch will contain the root route for that tab and any nested sub-routes (e.g., `/habits/:id`).

#### Step 2: Update [app_shell.dart](file:///home/kk/Upgrade/lib/features/shell/app_shell.dart)
- Change `AppShell` to accept `StatefulNavigationShell` as its child.
- Replace the manual `PageView` logic with a more robust integration:
    - The `PageView` will use the `StatefulNavigationShell` to render the branches.
    - Synchronize `onPageChanged` of `PageView` with `navigationShell.goBranch(index)`.
    - Ensure that clicking the `NavigationBar` or `NavigationRail` triggers a smooth page transition in the `PageView`.
- **Handling Nested Routes**: Ensure that when a user is on a sub-route (like `/habits/new`), the `PageView` doesn't intercept swipes that should be handled by the child screen, or simply hide the `PageView` for those screens as currently implemented, but more cleanly.

#### Step 3: Animation Fine-tuning
- Use `Curve.easeInOutCubic` for page transitions.
- Ensure the bottom navigation bar updates its selected index immediately when a swipe begins to feel responsive.

### 3. Benefits
- **Responsive Feel**: Instant feedback when swiping.
- **Improved UX**: Users can move between major app sections with a single gesture.
- **Platform Consistency**: Follows modern mobile app patterns for high-quality utility and gaming apps.

