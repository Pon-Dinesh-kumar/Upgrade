import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../dashboard/dashboard_screen.dart';
import '../habits/habits_screen.dart';
import '../upgrades/upgrades_screen.dart';
import '../timeline/timeline_screen.dart';
import '../upgrade_ai/upgrade_ai_screen.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  const AppShell({super.key, required this.navigationShell, required this.children});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  bool _isAnimating = false;

  void _onTap(int index) {
    final isCurrent = index == widget.navigationShell.currentIndex;
    
    // Always call goBranch. If it's the current branch, initialLocation: true 
    // will navigate back to the root of that branch.
    widget.navigationShell.goBranch(
      index,
      initialLocation: isCurrent,
    );

    // Then animate the PageView if it's currently attached
    if (!isCurrent && _pageController.hasClients) {
      setState(() => _isAnimating = true);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      ).then((_) {
        if (mounted) setState(() => _isAnimating = false);
      });
    }
  }

  void _onPageChanged(int index) {
    if (_isAnimating) return;
    
    if (index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: false,
      );
    }
  }

  List<NavigationDestination> _destinations(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
    return [
      NavigationDestination(icon: AppLogoIcon(size: 24, color: iconColor), label: 'Upgrades'),
      const NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), label: 'Habits'),
      const NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.smart_toy_rounded), label: 'Upgrade AI'),
      const NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
    ];
  }

  List<NavigationRailDestination> _railDestinations(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
    return [
      NavigationRailDestination(icon: AppLogoIcon(size: 24, color: iconColor), label: const Text('Upgrades')),
      const NavigationRailDestination(icon: Icon(Icons.check_circle_outline_rounded), label: Text('Habits')),
      const NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Home')),
      const NavigationRailDestination(icon: Icon(Icons.smart_toy_rounded), label: Text('Upgrade AI')),
      const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Settings')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final isWide = MediaQuery.of(context).size.width > 600;
    
    // Sync page controller if index changes externally (e.g. back button, deep link)
    if (!_isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          final page = _pageController.page?.round();
          if (page != index) {
            _pageController.jumpToPage(index);
          }
        }
      });
    }

    final pageView = PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: widget.children,
    );

    // content is ALWAYS the pageView to support universal swipe
    final content = pageView;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _onTap,
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
        selectedIndex: index,
        onDestinationSelected: _onTap,
        destinations: _destinations(context),
      ),
    );
  }
}
