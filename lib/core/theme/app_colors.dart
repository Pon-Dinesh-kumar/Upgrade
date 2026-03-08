import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // -- Semantic accent colors (shared across both themes) --
  static const Color blue = Color(0xFF2383E2);
  static const Color green = Color(0xFF0F7B6C);
  static const Color amber = Color(0xFFC77D1A);
  static const Color red = Color(0xFFEB5757);

  // Light tint backgrounds for tags / badges
  static const Color blueTint = Color(0xFFD3E5EF);
  static const Color greenTint = Color(0xFFDBEDDB);
  static const Color amberTint = Color(0xFFFDECC8);
  static const Color redTint = Color(0xFFFFE2DD);

  // -- Dark theme surface colors --
  static const Color darkBg = Color(0xFF191919);
  static const Color darkSurface = Color(0xFF202020);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkText = Color(0xFFEBEBEB);
  static const Color darkTextSecondary = Color(0xFF9B9B9B);
  static const Color darkTextMuted = Color(0xFF5C5C5C);

  // -- Light theme surface colors --
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F7F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E3E0);
  static const Color lightText = Color(0xFF191919);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextMuted = Color(0xFF9B9B9B);

  // -- Habit difficulty colors --
  static const Map<String, Color> difficultyColors = {
    'easy': green,
    'medium': blue,
    'hard': amber,
  };

  // -- Upgrade color palette (Notion-style muted) --
  static const List<int> upgradeColorOptions = [
    0xFF9B9B9B, // grey
    0xFF937264, // brown
    0xFFC77D1A, // orange
    0xFFCB912E, // yellow
    0xFF0F7B6C, // green
    0xFF2383E2, // blue
    0xFF6940A5, // purple
    0xFFAD1A72, // pink
    0xFFEB5757, // red
    0xFF2E8B8B, // teal
  ];

  // Backward-compat aliases used across codebase — mapped to new palette
  static const Color neonBlue = blue;
  static const Color neonGreen = green;
  static const Color neonOrange = amber;
  static const Color neonRed = red;
  static const Color neonYellow = amber;
  static const Color neonCyan = blue;
  static const Color neonPurple = Color(0xFF6940A5);

  // Kept for code that still references gradients — now single-hue subtle
  static const LinearGradient xpGradient = LinearGradient(
    colors: [blue, blue],
  );
  static const LinearGradient levelUpGradient = LinearGradient(
    colors: [green, green],
  );
  static const LinearGradient streakGradient = LinearGradient(
    colors: [amber, amber],
  );
}
