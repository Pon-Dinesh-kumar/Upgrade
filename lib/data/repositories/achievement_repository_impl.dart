import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/local/local_storage.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  final LocalStorage _storage;
  static const _key = 'achievements';

  AchievementRepositoryImpl(this._storage);

  @override
  Future<List<Achievement>> getUnlockedAchievements() async {
    final data = await _storage.readList(_key);
    return data.map((e) => Achievement.fromJson(e)).toList();
  }

  @override
  Future<void> unlockAchievement(Achievement achievement) async {
    final all = await getUnlockedAchievements();
    if (all.any((a) => a.key == achievement.key)) return;
    all.add(achievement.copyWith(unlockedAt: DateTime.now()));
    await _storage.writeList(_key, all.map((a) => a.toJson()).toList());
  }

  @override
  Future<bool> isUnlocked(String key) async {
    final all = await getUnlockedAchievements();
    return all.any((a) => a.key == key);
  }
}
