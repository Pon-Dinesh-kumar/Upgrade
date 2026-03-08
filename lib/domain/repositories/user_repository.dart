import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> deleteProfile();
  Future<bool> hasProfile();
}
