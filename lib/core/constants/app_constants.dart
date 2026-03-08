import 'dart:math';

class AppConstants {
  AppConstants._(); // prevent instantiation

  static const String appName = 'UPGRADE';
  static const String appVersion = '1.0.0';

  static const Map<String, int> xpByDifficulty = {
    'easy': 15,
    'medium': 30,
    'hard': 60,
  };

  static const Map<int, double> streakMultipliers = {
    7: 1.25,
    30: 1.5,
    100: 2.0,
    365: 3.0,
  };

  static const List<MapEntry<int, String>> rankTitles = [
    MapEntry(0, 'Novice'),
    MapEntry(6, 'Apprentice'),
    MapEntry(16, 'Adept'),
    MapEntry(26, 'Specialist'),
    MapEntry(36, 'Expert'),
    MapEntry(51, 'Master'),
    MapEntry(71, 'Grandmaster'),
    MapEntry(91, 'Legend'),
  ];

  static const List<String> difficulties = ['easy', 'medium', 'hard'];
  static const List<String> frequencies = ['daily', 'weekly', 'custom'];

  static const Map<int, String> moodEmojis = {
    1: '😔',
    2: '😕',
    3: '😐',
    4: '🙂',
    5: '😄',
  };

  // Avatar part labels for the NotionAvatar customizer UI
  static const List<String> avatarParts = [
    'face', 'hair', 'eyes', 'eyebrows', 'nose',
    'mouth', 'glasses', 'beard', 'accessories', 'details',
  ];

  static const Map<String, String> avatarPartLabels = {
    'face': 'Face',
    'hair': 'Hair',
    'eyes': 'Eyes',
    'eyebrows': 'Brows',
    'nose': 'Nose',
    'mouth': 'Mouth',
    'glasses': 'Glasses',
    'beard': 'Beard',
    'accessories': 'Extras',
    'details': 'Details',
  };

  // Upgrade difficulty tiers
  static const List<String> upgradeDifficulties = ['easy', 'medium', 'hard'];

  // Base XP awarded per upgrade difficulty
  static const Map<String, int> upgradeBaseXp = {
    'easy': 200,
    'medium': 500,
    'hard': 1000,
  };

  // Weight of each habit difficulty in upgrade score calculation
  static const Map<String, int> difficultyWeights = {
    'easy': 2,
    'medium': 3,
    'hard': 5,
  };

  // Upgrade impact level display labels (internal keys remain easy/medium/hard)
  static const Map<String, String> upgradeImpactLabels = {
    'easy': 'Minor',
    'medium': 'Moderate',
    'hard': 'Major',
  };

  static String getRank(int level) {
    String rank = 'Novice';
    for (final entry in rankTitles) {
      if (level >= entry.key) rank = entry.value;
    }
    return rank;
  }

  static int xpForLevel(int level) {
    if (level <= 1) return 100;
    return (100 * pow(level, 1.5)).floor();
  }

  static double getStreakMultiplier(int streak) {
    double multiplier = 1.0;
    for (final entry in streakMultipliers.entries) {
      if (streak >= entry.key) multiplier = entry.value;
    }
    return multiplier;
  }
}
