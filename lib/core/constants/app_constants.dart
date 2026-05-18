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

  // Avatar part labels for the Doodle customizer UI
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

  // ─── Meaningful Upgrade (Goal) Icons ─────────────────────────────────
  // Each icon represents a real-life goal category.
  static const List<int> upgradeIconOptions = [
    0xe28d, // fitness_center (Physical Fitness)
    0xe566, // directions_run (Running/Cardio)
    0xe96c, // self_improvement (Mental Health/Yoga)
    0xea19, // menu_book (Knowledge/Learning)
    0xe0af, // business_center (Career/Work)
    0xef63, // payments (Finance/Money)
    0xe40a, // palette (Creativity/Art)
    0xeb8e, // terminal (Tech/Coding)
    0xe87d, // favorite (Social/Relationships)
    0xf02e, // home_work (Home/Personal Life)
    0xe56c, // restaurant (Nutrition/Health)
    0xe405, // music_note (Hobbies/Music)
    0xe87a, // explore (Adventure/Travel)
    0xea35, // eco (Growth/Nature)
    0xe8e5, // track_changes (Discipline/Focus)
    0xe666, // auto_awesome_history (Routine/Life)
    0xe894, // language (Language learning)
    0xef83, // volunteer_activism (Giving/Kindness)
    0xeb9b, // rocket_launch (Growth/Ambition)
    0xebaa, // shield (Security/Protection)
    0xea4f, // celebration (Milestones)
  ];

  // ─── Meaningful Habit Icons ──────────────────────────────────────────
  // Each icon represents a daily actionable habit.
  static const List<int> habitIconOptions = [
    0xe566, // directions_run (Run)
    0xe536, // directions_walk (Walk)
    0xe28d, // fitness_center (Gym)
    0xe539, // directions_bike (Cycle)
    0xe540, // pool (Swim)
    0xe3e7, // spa (Meditate)
    0xe96c, // self_improvement (Yoga)
    0xf06bb, // auto_stories (Read)
    0xf0668, // edit_note (Journal)
    0xe798, // local_drink (Drink Water)
    0xf0538, // bedtime (Sleep)
    0xe56c, // restaurant (Eat Healthy)
    0xe514, // medication (Vitamins)
    0xef64, // savings (Save Money)
    0xe88e, // cleaning_services (Clean)
    0xea35, // eco (Garden)
    0xe8f9, // work (Work)
    0xe80e, // school (Study)
    0xe0af, // code (Code)
    0xe86c, // check_circle (General Task)
    0xe51a, // sunny (Morning routine)
  ];
}
