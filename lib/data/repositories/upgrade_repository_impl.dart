import '../../domain/entities/upgrade_group.dart';
import '../../domain/repositories/upgrade_repository.dart';
import '../datasources/local/local_storage.dart';

class UpgradeRepositoryImpl implements UpgradeRepository {
  final LocalStorage _storage;
  static const _key = 'upgrades';

  UpgradeRepositoryImpl(this._storage);

  @override
  Future<List<UpgradeGroup>> getAllUpgrades() async {
    final data = await _storage.readList(_key);
    return data.map((e) => UpgradeGroup.fromJson(e)).toList();
  }

  @override
  Future<UpgradeGroup?> getUpgrade(String id) async {
    final all = await getAllUpgrades();
    try {
      return all.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUpgrade(UpgradeGroup upgrade) async {
    final all = await getAllUpgrades();
    final index = all.indexWhere((u) => u.id == upgrade.id);
    if (index >= 0) {
      all[index] = upgrade;
    } else {
      all.add(upgrade);
    }
    await _storage.writeList(_key, all.map((u) => u.toJson()).toList());
  }

  @override
  Future<void> deleteUpgrade(String id) async {
    final all = await getAllUpgrades();
    all.removeWhere((u) => u.id == id);
    await _storage.writeList(_key, all.map((u) => u.toJson()).toList());
  }

  @override
  Future<List<UpgradeGroup>> getActiveUpgrades() async {
    final all = await getAllUpgrades();
    return all.where((u) => !u.archived).toList();
  }
}
