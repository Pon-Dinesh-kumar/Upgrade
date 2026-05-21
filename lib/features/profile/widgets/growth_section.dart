import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/xp_bar.dart';

class GrowthSection extends StatelessWidget {
  final double progress;
  final int level;
  final int currentXp;
  final int xpForNext;
  final VoidCallback onXpBarTap;

  const GrowthSection({
    super.key,
    required this.progress,
    required this.level,
    required this.currentXp,
    required this.xpForNext,
    required this.onXpBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.growth,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/level-roadmap'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.viewRoadmap,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onXpBarTap,
            child: XpBar(
              progress: progress,
              level: level,
              currentXp: currentXp,
              xpForNext: xpForNext,
              titlePrefix: 'Level',
              showXpNumbers: true,
            ),
          ),
        ],
      ),
    );
  }
}
