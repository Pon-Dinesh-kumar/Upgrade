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

  // ─── Meaningful Upgrade (Goal) Icons ─────────────────────────────────
  // Each icon represents a real-life goal category.
  static const List<int> upgradeIconOptions = [
    0xe533, // fitness_center (gym/strength)
    0xe566, // directions_run (running/cardio)
    0xe3e7, // spa (wellness/meditation)
    0xea65, // psychology (mindset/brain)
    0xe80e, // school (education)
    0xe865, // work (career)
    0xe263, // attach_money (finance)
    0xf06bb, // auto_stories (reading/books)
    0xe0af, // email → code (coding/tech)
    0xef76, // science (research)
    0xe559, // brush (art/creativity)
    0xef63, // music_note (music)
    0xe52f, // restaurant (nutrition/food)
    0xe539, // directions_bike (cycling)
    0xe87c, // favorite (relationships/love)
    0xe53a, // flight_takeoff (travel)
  ];

  // ─── Meaningful Habit Icons ──────────────────────────────────────────
  // Each icon represents a daily actionable habit.
  static const List<int> habitIconOptions = [
    0xe566, // directions_run (run/jog)
    0xe536, // directions_walk (walk)
    0xe533, // fitness_center (exercise)
    0xe539, // directions_bike (cycling)
    0xe534, // pool (swimming)
    0xe3e7, // spa (meditate/relax)
    0xf06bb, // auto_stories (read)
    0xe150, // edit (write/journal)
    0xe52f, // restaurant (eat healthy)
    0xe798, // local_drink (drink water)
    0xf0538, // bedtime (sleep)
    0xe514, // medication (vitamins/pills)
    0xef63, // music_note (play music)
    0xe425, // timer (timed practice)
    0xe877, // task_alt → check_circle (complete task)
    0xea65, // psychology (learn/study)
    0xe25a, // self_improvement (yoga)
    0xe263, // savings (save money)
    0xe88e, // cleaning_services (clean/organize)
    0xea35, // eco (plant/garden)
  ];
}
