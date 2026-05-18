import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/data/repositories/user_repository_impl.dart';
import 'package:upgrade/data/datasources/local/local_storage.dart';
import 'package:upgrade/domain/entities/user_profile.dart';

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
  late UserRepositoryImpl repository;
  late MockLocalStorage mockStorage;

  setUp(() {
    mockStorage = MockLocalStorage();
    repository = UserRepositoryImpl(mockStorage);
  });

  group('UserRepositoryImpl', () {
    test('getProfile returns null when storage is empty', () async {
      final profile = await repository.getProfile();
      expect(profile, isNull);
    });

    test('saveProfile saves and getProfile retrieves', () async {
      final profile = UserProfile(username: 'tester');
      await repository.saveProfile(profile);
      
      final saved = await repository.getProfile();
      expect(saved?.username, 'tester');
      expect(saved?.id, profile.id);
    });

    test('hasProfile returns correct status', () async {
      expect(await repository.hasProfile(), isFalse);
      
      await repository.saveProfile(UserProfile(username: 'tester'));
      expect(await repository.hasProfile(), isTrue);
    });

    test('deleteProfile removes the profile', () async {
      await repository.saveProfile(UserProfile(username: 'tester'));
      await repository.deleteProfile();
      
      expect(await repository.getProfile(), isNull);
    });
  });
}
