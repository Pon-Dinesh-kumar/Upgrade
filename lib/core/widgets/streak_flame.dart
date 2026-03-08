import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StreakFlame extends StatelessWidget {
  final int streak;
  final double size;

  const StreakFlame({super.key, required this.streak, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: isActive ? AppColors.amber : AppColors.darkTextMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '$streak',
          style: TextStyle(
            color: isActive ? AppColors.amber : AppColors.darkTextMuted,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.7,
          ),
        ),
      ],
    );
  }
}
