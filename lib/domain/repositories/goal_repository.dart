import '../entities/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> getAllGoals();
  Future<Goal?> getGoal(String id);
  Future<void> saveGoal(Goal goal);
  Future<void> deleteGoal(String id);
  Future<List<Goal>> getActiveGoals();
}
