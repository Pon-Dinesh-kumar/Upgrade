import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/local_storage.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalStorage _storage;
  static const _key = 'user_profile';

  UserRepositoryImpl(this._storage);

  @override
  Future<UserProfile?> getProfile() async {
    final data = await _storage.readObject(_key);
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _storage.writeObject(_key, profile.toJson());
  }

  @override
  Future<void> deleteProfile() async {
    await _storage.deleteFile(_key);
  }

  @override
  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }
}
