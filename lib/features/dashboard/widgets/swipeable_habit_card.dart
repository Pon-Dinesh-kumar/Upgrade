import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo_icon.dart';
import '../../../core/widgets/streak_flame.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/habit.dart';

enum HabitDayStatus { pending, passed, failed }

/// Swipe right to pass (green fill), swipe left to fail (red fill). Border unchanged.
class SwipeableHabitCard extends ConsumerStatefulWidget {
  final int index;
  final Habit habit;
  final HabitDayStatus status;
  final String? upgradeName;
  final Color? upgradeColor;

  const SwipeableHabitCard({
    super.key,
    required this.index,
    required this.habit,
    required this.status,
    this.upgradeName,
    this.upgradeColor,
  });

  @override
  ConsumerState<SwipeableHabitCard> createState() => _SwipeableHabitCardState();
}

class _SwipeableHabitCardState extends ConsumerState<SwipeableHabitCard>
    with SingleTickerProviderStateMixin {
  static const double _commitThreshold = 72;

  double _dragX = 0;
  bool _tapEnabled = true;
  bool _isBusy = false;
  bool _crossedPass = false;
  bool _crossedFail = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _snapAnim = CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic);
    _snapController.addListener(() {
      if (_snapController.isAnimating) {
        setState(() => _dragX = _dragX * (1 - _snapAnim.value));
      }
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwipeableHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status && !_snapController.isAnimating) {
      _dragX = 0;
      _crossedPass = false;
      _crossedFail = false;
      _tapEnabled = true;
    }
  }

  Future<void> _commitPass() async {
    if (_isBusy || widget.status == HabitDayStatus.passed) {
      _springBack();
      return;
    }
    setState(() => _isBusy = true);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 30));
    HapticFeedback.mediumImpact();
    await ref.read(gamificationEngineProvider).completeHabit(widget.habit);
    await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
    if (mounted) {
      setState(() {
        _isBusy = false;
        _dragX = 0;
      });
    }
  }

  Future<void> _commitFail() async {
    if (_isBusy || widget.status == HabitDayStatus.failed) {
      _springBack();
      return;
    }
    setState(() => _isBusy = true);
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.lightImpact();
    await ref.read(gamificationEngineProvider).failHabit(widget.habit);
    await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
    if (mounted) {
      setState(() {
        _isBusy = false;
        _dragX = 0;
      });
    }
  }

  void _springBack() {
    _snapController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragX = 0;
          _crossedPass = false;
          _crossedFail = false;
        });
        _snapController.reset();
      }
    });
  }

  Future<void> _onDragEnd() async {
    try {
      if (_dragX >= _commitThreshold) {
        await _commitPass();
      } else if (_dragX <= -_commitThreshold) {
        await _commitFail();
      } else {
        HapticFeedback.selectionClick();
        _springBack();
      }
    } finally {
      if (mounted) setState(() => _tapEnabled = true);
    }
  }

  Color _backgroundColor(ThemeData theme, bool isDark) {
    final base = isDark ? AppColors.darkCard : AppColors.lightCard;
    final passed = widget.status == HabitDayStatus.passed;
    final failed = widget.status == HabitDayStatus.failed;

    if (passed) {
      return Color.lerp(base, AppColors.green.withValues(alpha: 0.22), 1.0)!;
    }
    if (failed) {
      return Color.lerp(base, AppColors.red.withValues(alpha: 0.22), 1.0)!;
    }

    if (_dragX > 8) {
      final t = (_dragX / 140).clamp(0.0, 0.5);
      return Color.lerp(base, AppColors.green.withValues(alpha: 0.28), t)!;
    }
    if (_dragX < -8) {
      final t = (-_dragX / 140).clamp(0.0, 0.5);
      return Color.lerp(base, AppColors.red.withValues(alpha: 0.28), t)!;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayColor = widget.upgradeColor ?? Color(widget.habit.color);
    final difficultyColor =
        AppColors.difficultyColors[widget.habit.difficulty] ?? AppColors.blue;
    final passed = widget.status == HabitDayStatus.passed;
    final failed = widget.status == HabitDayStatus.failed;
    final bg = _backgroundColor(theme, isDark);
    final passHint = (_dragX / _commitThreshold).clamp(0.0, 1.0);
    final failHint = (-_dragX / _commitThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        if (_isBusy) return;
        _tapEnabled = true;
        _crossedPass = false;
        _crossedFail = false;
        HapticFeedback.selectionClick();
      },
      onHorizontalDragUpdate: (d) {
        if (_isBusy) return;
        if (d.delta.dx.abs() > 3) _tapEnabled = false;
        setState(() {
          _dragX += d.delta.dx;
          if (_dragX > 40 && !_crossedPass) {
            _crossedPass = true;
            HapticFeedback.lightImpact();
          }
          if (_dragX < -40 && !_crossedFail) {
            _crossedFail = true;
            HapticFeedback.lightImpact();
          }
        });
      },
      onHorizontalDragEnd: (_) => _onDragEnd(),
      onLongPress: () async {
        if (widget.status == HabitDayStatus.pending || _isBusy) return;
        HapticFeedback.mediumImpact();
        setState(() {
          _isBusy = true;
          _tapEnabled = true;
        });
        await ref.read(gamificationEngineProvider).resetHabitDay(widget.habit);
        await ref.read(gamificationEngineProvider).evaluateDueUpgrades();
        if (mounted) {
          setState(() {
            _isBusy = false;
            _tapEnabled = true;
          });
        }
      },
      onTap: _tapEnabled && !_isBusy
          ? () {
              HapticFeedback.selectionClick();
              context.go('/habits/${widget.habit.id}');
            }
          : null,
      child: Transform.translate(
        offset: Offset(_dragX * 0.28, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: displayColor.withValues(alpha: 0.35), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Stack(
            children: [
              if (passHint > 0.05 && !passed)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: passHint * 0.7,
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.green.withValues(alpha: 0.5), size: 48),
                  ),
                ),
              if (failHint > 0.05 && !failed)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: failHint * 0.7,
                    child: Icon(Icons.close_rounded,
                        color: AppColors.red.withValues(alpha: 0.5), size: 48),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: displayColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: displayColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      IconData(widget.habit.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      size: 20,
                      color: displayColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.index}. ${widget.habit.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                passed ? TextDecoration.lineThrough : null,
                            color: passed || failed
                                ? theme.textTheme.bodyLarge?.color
                                : theme.textTheme.titleLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StreakFlame(
                                streak: widget.habit.currentStreak, size: 14),
                            const SizedBox(width: 8),
                            _Tag(
                              label: widget.habit.difficulty[0].toUpperCase() +
                                  widget.habit.difficulty.substring(1),
                              color: difficultyColor,
                            ),
                            if (widget.upgradeName != null) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: _Tag(
                                  label: widget.upgradeName!,
                                  color: displayColor,
                                  iconWidget: AppLogoIcon(
                                      size: 10, color: displayColor),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? iconWidget;
  const _Tag({required this.label, required this.color, this.iconWidget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null) ...[
            iconWidget!,
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
