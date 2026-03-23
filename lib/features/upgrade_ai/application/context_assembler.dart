import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers.dart';
import '../domain/ai_models.dart';

class ContextAssembler {
  final Ref _ref;
  ContextAssembler(this._ref);

  AIContextSnapshot buildContext() {
    final profile = _ref.read(userProfileProvider).valueOrNull;
    final habits = _ref.read(habitsProvider).valueOrNull ?? const [];
    final entries = _ref.read(habitEntriesProvider).valueOrNull ?? const [];
    final upgrades = _ref.read(upgradesProvider).valueOrNull ?? const [];
    final memberships = _ref.read(upgradeHabitsProvider).valueOrNull ?? const [];
    final goals = _ref.read(goalsProvider).valueOrNull ?? const [];
    final timeline = _ref.read(timelineProvider).valueOrNull ?? const [];
    final activeUpgrades = upgrades.where((u) => u.status == 'active').length;
    final completedToday = _ref.read(todayEntriesProvider).where((e) => e.completed).length;
    final activeHabits = habits.where((h) => !h.archived).length;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final entries7d = entries.where((e) => !e.date.isBefore(DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day))).toList();
    final completed7d = entries7d.where((e) => e.completed).length;
    final expected7d = activeHabits * 7;
    final completionRate7d = expected7d > 0 ? (completed7d / expected7d) : 0.0;
    final weakHabits = habits
        .where((h) => !h.archived)
        .where((h) => h.currentStreak == 0 || h.currentStreak <= 1)
        .take(5)
        .map((h) => h.name)
        .toList();
    final strongHabits = habits
        .where((h) => !h.archived)
        .where((h) => h.currentStreak >= 7)
        .take(5)
        .map((h) => h.name)
        .toList();

    final compact = '''
User: ${profile?.username ?? 'Unknown'}
Level: ${profile?.level ?? 0}, XP: ${profile?.totalXp ?? 0}, Rank: ${profile?.rank ?? 'Unknown'}
Current streak: ${profile?.currentStreak ?? 0}, Longest streak: ${profile?.longestStreak ?? 0}
Habits: $activeHabits active, $completedToday completed today
Upgrades: $activeUpgrades active, ${upgrades.length} total
Goals: ${goals.length}
Timeline events: ${timeline.length}
7d completion: ${(completionRate7d * 100).round()}% ($completed7d/$expected7d)
''';

    final full = '''
$compact

ACTIVE_UPGRADES:
${upgrades.where((u) => u.status == 'active').map((u) => '- ${u.name} (${u.difficulty}) ${u.startDate.toIso8601String().split('T').first} -> ${u.endDate.toIso8601String().split('T').first}, cutoff ${(u.cutoffPercentage * 100).round()}%').join('\n')}

ACTIVE_HABITS:
${habits.where((h) => !h.archived).map((h) => '- ${h.name} [${h.difficulty}] freq=${h.frequency} streak=${h.currentStreak}/${h.longestStreak}').join('\n')}

GOALS:
${goals.map((g) => '- ${g.name} status=${g.status} target=${g.targetDate?.toIso8601String().split('T').first ?? 'none'}').join('\n')}

RECENT_TIMELINE:
${(List.from(timeline)..sort((a, b) => b.timestamp.compareTo(a.timestamp))).take(20).map((t) => '- ${t.timestamp.toIso8601String()}: ${t.title} (${t.type})').join('\n')}

UPGRADE_HABIT_MEMBERSHIPS:
${memberships.map((m) => '- upgrade=${m.upgradeId}, habit=${m.habitId}, joined=${m.joinedDate.toIso8601String()}, left=${m.leftDate?.toIso8601String() ?? 'active'}').join('\n')}

TODAY_ENTRIES:
${entries.where((e) {
      final n = DateTime.now();
      return e.date.year == n.year && e.date.month == n.month && e.date.day == n.day;
    }).map((e) => '- habit=${e.habitId} completed=${e.completed} value=${e.value}').join('\n')}

BEHAVIORAL_SIGNALS:
- Weak habits (low streak): ${weakHabits.isEmpty ? 'none' : weakHabits.join(', ')}
- Strong habits (high streak): ${strongHabits.isEmpty ? 'none' : strongHabits.join(', ')}
- Last 7d completion rate: ${(completionRate7d * 100).toStringAsFixed(1)}%
''';

    return AIContextSnapshot(compactSummary: compact, fullContext: full);
  }
}
