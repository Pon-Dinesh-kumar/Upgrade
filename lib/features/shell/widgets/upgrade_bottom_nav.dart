import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo_icon.dart';

class UpgradeNavItem {
  final Widget inactiveIcon;
  final Widget activeIcon;
  final String label;

  const UpgradeNavItem({
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
  });
}

/// Flowing bottom navigation — pill follows swipe, haptics on tab change.
class UpgradeBottomNav extends StatefulWidget {
  final int selectedIndex;
  final double pageOffset;
  final ValueChanged<int> onTabSelected;

  const UpgradeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.pageOffset,
    required this.onTabSelected,
  });

  @override
  State<UpgradeBottomNav> createState() => _UpgradeBottomNavState();
}

class _UpgradeBottomNavState extends State<UpgradeBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static List<UpgradeNavItem> _items(Color muted) => [
        UpgradeNavItem(
          inactiveIcon: AppLogoIcon(size: 22, color: muted),
          activeIcon: const AppLogoIcon(size: 22, color: Colors.white),
          label: AppStrings.upgradesTab,
        ),
        UpgradeNavItem(
          inactiveIcon:
              Icon(Icons.check_circle_outline_rounded, color: muted, size: 22),
          activeIcon:
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          label: AppStrings.habitsTab,
        ),
        UpgradeNavItem(
          inactiveIcon: Icon(Icons.dashboard_outlined, color: muted, size: 22),
          activeIcon:
              const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
          label: AppStrings.homeTab,
        ),
        UpgradeNavItem(
          inactiveIcon: Icon(Icons.smart_toy_outlined, color: muted, size: 22),
          activeIcon:
              const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          label: 'AI',
        ),
        UpgradeNavItem(
          inactiveIcon: Icon(Icons.settings_outlined, color: muted, size: 22),
          activeIcon:
              const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
          label: AppStrings.settings,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UpgradeBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final barBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final accent = theme.colorScheme.primary;
    final items = _items(muted);
    final width = MediaQuery.sizeOf(context).width;

    const topRadius = Radius.circular(18);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: Material(
        color: barBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.35),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: _FlowingTabStrip(
                width: width - 16,
                items: items,
                pageOffset: widget.pageOffset,
                accent: accent,
                pulse: _pulseController,
                onTap: (i) {
                  if (i != widget.selectedIndex) {
                    HapticFeedback.mediumImpact();
                  } else {
                    HapticFeedback.lightImpact();
                  }
                  widget.onTabSelected(i);
                },
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _FlowingTabStrip extends StatelessWidget {
  final double width;
  final List<UpgradeNavItem> items;
  final double pageOffset;
  final Color accent;
  final Animation<double> pulse;
  final ValueChanged<int> onTap;

  const _FlowingTabStrip({
    required this.width,
    required this.items,
    required this.pageOffset,
    required this.accent,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabWidth = width / items.length;
    final clampedOffset = pageOffset.clamp(0.0, (items.length - 1).toDouble());
    final pillLeft = clampedOffset * tabWidth;
    final selection = clampedOffset.round().clamp(0, items.length - 1);

    return SizedBox(
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: pillLeft + 4,
            top: 4,
            width: tabWidth - 8,
            height: 44,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: pulse, curve: Curves.elasticOut),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, AppColors.green, 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final focus = (clampedOffset - i).abs();
              final t = (1 - focus.clamp(0.0, 1.0));
              final isSettled = i == selection;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: SizedBox(
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: 0.88 + 0.12 * t,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: isSettled ? item.activeIcon : item.inactiveIcon,
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontSize: 9 + 1 * t,
                            fontWeight:
                                t > 0.5 ? FontWeight.w700 : FontWeight.w500,
                            color: isSettled
                                ? Colors.white
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                            letterSpacing: 0.2,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
