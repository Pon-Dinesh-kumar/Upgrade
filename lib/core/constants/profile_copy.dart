/// Shared profile and roadmap copy (minimal tone, Upgrade branding).
class ProfileCopy {
  ProfileCopy._();

  static const Map<String, String> rankMessages = {
    'Novice':
        "Every master was once a beginner. You've taken the hardest step — starting.",
    'Apprentice':
        "You're building real momentum. Your habits are becoming part of who you are.",
    'Adept':
        "Consistency is your superpower now. Most people quit — you didn't.",
    'Specialist':
        "You're in rare territory. Your dedication is shaping a better version of you.",
    'Expert':
        "The discipline you've built is extraordinary. You're proof that effort compounds.",
    'Master':
        "You've earned mastery through relentless commitment. Few reach this far.",
    'Grandmaster':
        "You're among the elite. Your journey inspires everyone around you.",
    'Legend':
        'Living proof that extraordinary results come from ordinary efforts, done daily.',
  };

  static String rankMessage(String rank) =>
      rankMessages[rank] ?? 'Keep going — your future self is cheering you on.';

  static String upgradeTrackMotivation(double score) {
    if (score < 0.3) return "You're laying the foundation for this upgrade.";
    if (score < 0.7) return 'This upgrade is becoming part of who you are.';
    return 'The finish line for this upgrade is in sight.';
  }

  /// Milestone level rewards (text-only titles for roadmap).
  static const Map<int, (String title, String description)> milestoneRewards = {
    1: ('The Seed',
        'Your journey begins here. Every great transformation starts with a single step.'),
    5: ('First Spark',
        "You proved this isn't just a phase. Momentum is building."),
    10: ('On Fire', 'Double digits. Your habits are becoming automatic.'),
    15: ('Unbreakable',
        "You've built a foundation most people never achieve."),
    20: ('Rising Star', 'Consistency is your superpower. Keep shining.'),
    25: ('Champion', 'A quarter-century of levels. That is elite dedication.'),
    30: ('Crowned', "You rule your habits. They don't rule you."),
    40: ('Diamond Mind', "Forged under pressure, you're unbreakable now."),
    50: ('Unstoppable', 'Halfway to 100. Nothing can hold you back.'),
    75: ('Beyond Limits', "You've transcended what most thought possible."),
    100: ('Transcendent', 'The ultimate achievement. You are the upgrade.'),
  };
}
