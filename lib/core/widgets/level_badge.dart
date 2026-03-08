import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const LevelBadge({super.key, required this.level, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blue,
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
