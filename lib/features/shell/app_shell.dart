import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_logo_icon.dart';

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
  DateTime? _lastBackPress;

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
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.brightness == Brightness.dark 
        ? const Color(0xFF5C5C5C) 
        : const Color(0xFF9B9B9B);

    return [
      NavigationDestination(
        icon: AppLogoIcon(size: 24, color: unselectedColor),
        selectedIcon: AppLogoIcon(size: 24, color: selectedColor),
        label: 'Upgrades',
      ),
      const NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), label: 'Habits'),
      const NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.smart_toy_rounded), label: 'Upgrade AI'),
      const NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
    ];
  }

  List<NavigationRailDestination> _railDestinations(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.brightness == Brightness.dark 
        ? const Color(0xFF5C5C5C) 
        : const Color(0xFF9B9B9B);

    return [
      NavigationRailDestination(
        icon: AppLogoIcon(size: 24, color: unselectedColor),
        selectedIcon: AppLogoIcon(size: 24, color: selectedColor),
        label: const Text('Upgrades'),
      ),
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
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != oldWidget.navigationShell.currentIndex) {
      if (!_isAnimating && _pageController.hasClients) {
        final page = _pageController.page?.round();
        if (page != widget.navigationShell.currentIndex) {
          _pageController.jumpToPage(widget.navigationShell.currentIndex);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final isWide = MediaQuery.of(context).size.width > 600;
    
    final pageView = PageView(
      key: const ValueKey('AppShellPageView'),
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: widget.children.asMap().entries.map((e) {
        return KeyedSubtree(
          key: ValueKey('Branch_${e.key}'),
          child: e.value,
        );
      }).toList(),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final currentIndex = widget.navigationShell.currentIndex;
        // 2 is the index for 'Home' (Dashboard)
        if (currentIndex != 2) {
          _onTap(2);
          return;
        }

        // If we are on Home, implement double tap to exit
        final now = DateTime.now();
        if (_lastBackPress == null || 
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // If double tapped within 2 seconds, we can pop (quit app)
        // Since we can't easily trigger a system quit from here without 'canPop: true',
        // we'll need to use SystemNavigator.pop() or similar if available, 
        // but for now we'll allow the pop by setting canPop logic or just exiting.
        // Actually, the best way with PopScope is to set canPop dynamically or use SystemNavigator.
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _onTap,
          destinations: _destinations(context),
        ),
      ),
    );
  }
}
