import '../entities/achievement.dart';

abstract class AchievementRepository {
  Future<List<Achievement>> getUnlockedAchievements();
  Future<void> unlockAchievement(Achievement achievement);
  Future<bool> isUnlocked(String key);
}
