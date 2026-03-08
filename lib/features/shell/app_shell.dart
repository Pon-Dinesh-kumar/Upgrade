import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../dashboard/dashboard_screen.dart';
import '../habits/habits_screen.dart';
import '../upgrades/upgrades_screen.dart';
import '../timeline/timeline_screen.dart';
import '../upgrade_ai/upgrade_ai_screen.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  int? _lastSyncedIndex;

  static int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/habits')) return 1;
    if (location.startsWith('/upgrades')) return 2;
    if (location.startsWith('/timeline')) return 3;
    if (location.startsWith('/upgrade-ai')) return 4;
    return 0;
  }

  static const List<String> _paths = ['/', '/habits', '/upgrades', '/timeline', '/upgrade-ai'];

  void _onTap(BuildContext context, int index) {
    context.go(_paths[index]);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
  }

  List<NavigationDestination> _destinations(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
    return [
      const NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), label: 'Habits'),
      NavigationDestination(icon: AppLogoIcon(size: 24, color: iconColor), label: 'Upgrades'),
      const NavigationDestination(icon: Icon(Icons.timeline_rounded), label: 'Timeline'),
      const NavigationDestination(icon: Icon(Icons.smart_toy_rounded), label: 'Upgrade AI'),
    ];
  }

  List<NavigationRailDestination> _railDestinations(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
    return [
      const NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Home')),
      const NavigationRailDestination(icon: Icon(Icons.check_circle_outline_rounded), label: Text('Habits')),
      NavigationRailDestination(icon: AppLogoIcon(size: 24, color: iconColor), label: const Text('Upgrades')),
      const NavigationRailDestination(icon: Icon(Icons.timeline_rounded), label: Text('Timeline')),
      const NavigationRailDestination(icon: Icon(Icons.smart_toy_rounded), label: Text('Upgrade AI')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _currentIndex(context);
    final isWide = MediaQuery.of(context).size.width > 600;
    final isTabChild = widget.child is DashboardScreen ||
        widget.child is HabitsScreen ||
        widget.child is UpgradesScreen ||
        widget.child is TimelineScreen ||
        widget.child is UpgradeAIScreen;
    // Never show PageView for nested paths (e.g. /habits/new); only for the five root tab paths.
    final isRootTabPath = _paths.contains(location);
    final showPageView = isTabChild && isRootTabPath;

    // Sync page to route when route changes from outside (back, deep link)
    if (showPageView && _lastSyncedIndex != index && index >= 0 && index <= 4) {
      _lastSyncedIndex = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final page = _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0;
        if (index != page) _pageController.jumpToPage(index);
      });
    }

    final pageView = PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(),
      onPageChanged: (int page) {
        _lastSyncedIndex = page;
        context.go(_paths[page]);
      },
      children: const [
        DashboardScreen(),
        HabitsScreen(),
        UpgradesScreen(),
        TimelineScreen(),
        UpgradeAIScreen(),
      ],
    );

    // Only show PageView when the router child is one of the five tab screens AND we're on a root
    // tab path; otherwise always show child so profile, settings, and nested routes are not overridden.
    final content = showPageView ? pageView : widget.child;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index.clamp(0, 4),
              onDestinationSelected: (i) => _onTap(context, i),
              labelType: NavigationRailLabelType.all,
              destinations: _railDestinations(context),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, 4),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: _destinations(context),
      ),
    );
  }
}
