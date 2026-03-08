import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final int previousLevel;
  final String? upgradeName;
  final int? xpEarned;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.previousLevel,
    this.upgradeName,
    this.xpEarned,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required int newLevel,
    required int previousLevel,
    String? upgradeName,
    int? xpEarned,
  }) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LevelUp',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return LevelUpOverlay(
          newLevel: newLevel,
          previousLevel: previousLevel,
          upgradeName: upgradeName,
          xpEarned: xpEarned,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newRank = AppConstants.getRank(widget.newLevel);
    final oldRank = AppConstants.getRank(widget.previousLevel);
    final rankChanged = newRank != oldRank;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                ),
                child: const Center(
                  child: Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 40),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .shimmer(delay: 600.ms, duration: 800.ms, color: Colors.white24),
              const SizedBox(height: 20),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Level ${widget.previousLevel}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 20, color: AppColors.green),
                  ),
                  Text(
                    'Level ${widget.newLevel}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              if (rankChanged) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    newRank,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
              ],

              if (widget.upgradeName != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Completed: ${widget.upgradeName}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
              ],

              if (widget.xpEarned != null) ...[
                const SizedBox(height: 8),
                Text(
                  '+${widget.xpEarned} XP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}
