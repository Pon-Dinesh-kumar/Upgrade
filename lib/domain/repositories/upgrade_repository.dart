import '../entities/upgrade_group.dart';

abstract class UpgradeRepository {
  Future<List<UpgradeGroup>> getAllUpgrades();
  Future<UpgradeGroup?> getUpgrade(String id);
  Future<void> saveUpgrade(UpgradeGroup upgrade);
  Future<void> deleteUpgrade(String id);
  Future<List<UpgradeGroup>> getActiveUpgrades();
}
