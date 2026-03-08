import '../../domain/entities/upgrade_habit.dart';
import '../../domain/repositories/upgrade_habit_repository.dart';
import '../datasources/local/local_storage.dart';

class UpgradeHabitRepositoryImpl implements UpgradeHabitRepository {
  static const String _storageKey = 'upgrade_habits';

  final LocalStorage _storage;

  UpgradeHabitRepositoryImpl(this._storage);

  @override
  Future<List<UpgradeHabit>> getAll() async {
    final list = await _storage.readList(_storageKey);
    return list.map((m) => UpgradeHabit.fromJson(m)).toList();
  }

  @override
  Future<List<UpgradeHabit>> getForUpgrade(String upgradeId) async {
    final all = await getAll();
    return all.where((m) => m.upgradeId == upgradeId).toList();
  }

  @override
  Future<List<UpgradeHabit>> getActiveForUpgrade(String upgradeId) async {
    final all = await getAll();
    return all
        .where((m) => m.upgradeId == upgradeId && m.leftDate == null)
        .toList();
  }

  @override
  Future<UpgradeHabit?> getActiveForHabit(String habitId) async {
    final all = await getAll();
    try {
      return all.firstWhere((m) => m.habitId == habitId && m.leftDate == null);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(UpgradeHabit membership) async {
    final list = await _storage.readList(_storageKey);
    final index = list.indexWhere((m) => m['id'] == membership.id);
    final json = membership.toJson();
    if (index >= 0) {
      list[index] = json;
    } else {
      list.add(json);
    }
    await _storage.writeList(_storageKey, list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await _storage.readList(_storageKey);
    list.removeWhere((m) => m['id'] == id);
    await _storage.writeList(_storageKey, list);
  }

  @override
  Future<void> removeHabitFromUpgrade(String habitId, String upgradeId) async {
    final active = await getActiveForUpgrade(upgradeId);
    final membership = active.where((m) => m.habitId == habitId).firstOrNull;
    if (membership != null) {
      await save(membership.copyWith(leftDate: DateTime.now()));
    }
  }
}
