import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/local/local_storage.dart';

class GoalRepositoryImpl implements GoalRepository {
  final LocalStorage _storage;
  static const _key = 'goals';

  GoalRepositoryImpl(this._storage);

  @override
  Future<List<Goal>> getAllGoals() async {
    final data = await _storage.readList(_key);
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  @override
  Future<Goal?> getGoal(String id) async {
    final all = await getAllGoals();
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    final all = await getAllGoals();
    final index = all.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      all[index] = goal;
    } else {
      all.add(goal);
    }
    await _storage.writeList(_key, all.map((g) => g.toJson()).toList());
  }

  @override
  Future<void> deleteGoal(String id) async {
    final all = await getAllGoals();
    all.removeWhere((g) => g.id == id);
    await _storage.writeList(_key, all.map((g) => g.toJson()).toList());
  }

  @override
  Future<List<Goal>> getActiveGoals() async {
    final all = await getAllGoals();
    return all.where((g) => g.status == 'active').toList();
  }
}
