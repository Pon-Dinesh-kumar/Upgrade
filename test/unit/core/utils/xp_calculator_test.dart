import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/core/utils/xp_calculator.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';

void main() {
  group('XpCalculator', () {
    test('xpRequiredForLevel returns correct XP', () {
      expect(XpCalculator.xpRequiredForLevel(1), 100);
      expect(XpCalculator.xpRequiredForLevel(2), 282); // floor(100 * 2^1.5) = floor(282.84)
      expect(XpCalculator.xpRequiredForLevel(3), 519); // floor(100 * 3^1.5) = floor(519.61)
    });

    test('levelFromTotalXp returns correct level', () {
      expect(XpCalculator.levelFromTotalXp(0), 1);
      expect(XpCalculator.levelFromTotalXp(50), 1);
      expect(XpCalculator.levelFromTotalXp(100), 2);
      expect(XpCalculator.levelFromTotalXp(381), 2);
      expect(XpCalculator.levelFromTotalXp(382), 3); // 100 + 282 = 382
    });

    test('progressToNextLevel returns correct percentage', () {
      expect(XpCalculator.progressToNextLevel(0), 0.0);
      expect(XpCalculator.progressToNextLevel(50), 0.5); // 50/100
      expect(XpCalculator.progressToNextLevel(100), 0.0); // Level 2, 0/282
      expect(XpCalculator.progressToNextLevel(241), 0.5); // Level 2, 141/282 = 0.5
    });

    test('countScheduledDays daily frequency', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 7);
      // Mocking today to be after the range to avoid today-clipping
      // The code uses DateTime.now() inside, which is hard to mock without a wrapper.
      // However, for dates in the past, it should work fine.
      expect(XpCalculator.countScheduledDays(start, end, 'daily', null), 7);
    });

    test('countScheduledDays weekly frequency (Mondays)', () {
      final start = DateTime(2024, 1, 1); // Monday
      final end = DateTime(2024, 1, 14); // Sunday
      expect(XpCalculator.countScheduledDays(start, end, 'weekly', null), 2);
    });

    test('countScheduledDays custom frequency (Tue, Thu)', () {
      final start = DateTime(2024, 1, 1); // Monday
      final end = DateTime(2024, 1, 7); // Sunday
      // 2nd (Tue), 4th (Thu)
      expect(XpCalculator.countScheduledDays(start, end, 'custom', '2,4'), 2);
    });

    test('calculateUpgradeXp calculates correct XP', () {
      final upgrade = UpgradeGroup(
        id: '1',
        name: 'Test',
        description: 'Test',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        difficulty: 'medium',
        cutoffPercentage: 0.7,
      );

      // Base for medium is 500 (from AppConstants, I should verify this)
      // score 0.8, 1 habit
      // habitBonus = 1.0 + (1-1)*0.1 = 1.0
      // performanceMul = 0.8
      // xpEarned = (500 * 1.0 * 0.8) = 400
      // passed = true (0.8 >= 0.7)
      // overachievement = (0.8 - 0.7) / (1 - 0.7) = 0.1 / 0.3 = 0.333
      // bonus = 500 * 0.2 * 0.333 = 33
      // Total = 400 + 33 = 433
      
      final xp = XpCalculator.calculateUpgradeXp(upgrade, 0.8, 1);
      expect(xp, 433);
    });
  });
}
