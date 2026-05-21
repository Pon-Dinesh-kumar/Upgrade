import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/upgrade_bottom_nav.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  const AppShell({super.key, required this.navigationShell, required this.children});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _pageAnimMs = 280;
  static const _homeBranchIndex = 2;

  late final PageController _pageController;
  bool _isAnimating = false;
  DateTime? _lastBackPress;
  double _pageOffset = 0;

  void _onTabSelected(int index) {
    final isCurrent = index == widget.navigationShell.currentIndex;

    widget.navigationShell.goBranch(
      index,
      initialLocation: isCurrent,
    );

    if (!isCurrent && _pageController.hasClients) {
      setState(() => _isAnimating = true);
      _pageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: _pageAnimMs),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
        if (mounted) setState(() => _isAnimating = false);
      });
    }
  }

  void _onPageChanged(int index) {
    if (_isAnimating) return;

    if (index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: false);
    }
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    setState(() => _pageOffset = page);
  }

  @override
  void initState() {
    super.initState();
    _pageOffset = widget.navigationShell.currentIndex.toDouble();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
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
      _pageOffset = widget.navigationShell.currentIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (index != _homeBranchIndex) {
          _onTabSelected(_homeBranchIndex);
          return;
        }

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

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBg
            : AppColors.lightBg,
        body: pageView,
        bottomNavigationBar: UpgradeBottomNav(
          selectedIndex: index,
          pageOffset: _pageOffset,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
