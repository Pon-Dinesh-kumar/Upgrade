import 'package:flutter/material.dart';

/// Flat progress bar for an Upgrade score vs cutoff goal (shared Home + Profile).
class UpgradeProgressBar extends StatelessWidget {
  final double score;
  final double cutoff;
  final Color color;
  final Color trackColor;
  final bool showLabels;

  const UpgradeProgressBar({
    super.key,
    required this.score,
    required this.cutoff,
    required this.color,
    required this.trackColor,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(score * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Goal: ${(cutoff * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        if (showLabels) const SizedBox(height: 4),
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: totalWidth,
                    height: 6,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: score.clamp(0.0, 1.0) * totalWidth,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: color,
                    ),
                  ),
                  Positioned(
                    left: cutoff.clamp(0.0, 1.0) * totalWidth - 0.5,
                    top: -1,
                    child: Container(
                      width: 1,
                      height: 8,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
