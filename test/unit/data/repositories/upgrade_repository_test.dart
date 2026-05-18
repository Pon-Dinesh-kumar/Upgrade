import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/data/repositories/upgrade_repository_impl.dart';
import 'package:upgrade/data/datasources/local/local_storage.dart';
import 'package:upgrade/domain/entities/upgrade_group.dart';

class MockLocalStorage implements LocalStorage {
  Map<String, dynamic> storage = {};

  @override
  Future<List<Map<String, dynamic>>> readList(String key) async {
    return (storage[key] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    storage[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> readObject(String key) async {
    return storage[key] as Map<String, dynamic>?;
  }

  @override
  Future<void> writeObject(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      storage.remove(key);
    } else {
      storage[key] = value;
    }
  }

  @override
  Future<void> deleteFile(String key) async {
    storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    storage.clear();
  }

  @override
  Future<Map<String, dynamic>> exportForBackup() async {
    return Map<String, dynamic>.from(storage);
  }

  @override
  Future<void> importFromBackup(Map<String, dynamic> map) async {
    storage = Map<String, dynamic>.from(map);
  }
}

void main() {
  late UpgradeRepositoryImpl repository;
  late MockLocalStorage mockStorage;

  setUp(() {
    mockStorage = MockLocalStorage();
    repository = UpgradeRepositoryImpl(mockStorage);
  });

  group('UpgradeRepositoryImpl', () {
    test('getAllUpgrades returns empty list when storage is empty', () async {
      final results = await repository.getAllUpgrades();
      expect(results, isEmpty);
    });

    test('saveUpgrade saves an upgrade and getAllUpgrades retrieves it', () async {
      final upgrade = UpgradeGroup(
        id: '1',
        name: 'Test Upgrade',
        description: 'Description',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      await repository.saveUpgrade(upgrade);
      final results = await repository.getAllUpgrades();

      expect(results.length, 1);
      expect(results.first.id, '1');
      expect(results.first.name, 'Test Upgrade');
    });

    test('deleteUpgrade removes an upgrade', () async {
      final upgrade = UpgradeGroup(
        id: '1',
        name: 'Test Upgrade',
        description: 'Description',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      await repository.saveUpgrade(upgrade);
      await repository.deleteUpgrade('1');
      final results = await repository.getAllUpgrades();

      expect(results, isEmpty);
    });
  });
}
