import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AISettingsStore {
  static const _apiKeyKey = 'ai.gemini.api_key';
  static const _modelKey = 'ai.gemini.model';
  static const _providerKey = 'ai.provider';
  static const _strictnessKey = 'ai.coach.strictness';
  static const _weeklyModeKey = 'ai.coach.weekly_mode';
  static const _defaultModel = 'gemini-2.5-flash';
  static const _defaultProvider = 'gemini';
  static const _defaultStrictness = 1;

  final FlutterSecureStorage _secureStorage;

  AISettingsStore(this._secureStorage);

  Future<String?> getApiKey() => _secureStorage.read(key: _apiKeyKey);

  Future<void> setApiKey(String value) =>
      _secureStorage.write(key: _apiKeyKey, value: value.trim());

  Future<void> clearApiKey() => _secureStorage.delete(key: _apiKeyKey);

  Future<String> getModel() async =>
      await _secureStorage.read(key: _modelKey) ?? _defaultModel;

  Future<void> setModel(String value) =>
      _secureStorage.write(key: _modelKey, value: value.trim());

  Future<String> getProvider() async =>
      await _secureStorage.read(key: _providerKey) ?? _defaultProvider;

  Future<void> setProvider(String value) =>
      _secureStorage.write(key: _providerKey, value: value.trim());

  Future<int> getStrictness() async {
    final raw = await _secureStorage.read(key: _strictnessKey);
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null || parsed < 0 || parsed > 2) return _defaultStrictness;
    return parsed;
  }

  Future<void> setStrictness(int value) => _secureStorage.write(
        key: _strictnessKey,
        value: value.clamp(0, 2).toString(),
      );

  Future<bool> getWeeklyMode() async {
    final raw = await _secureStorage.read(key: _weeklyModeKey);
    return raw == 'true';
  }

  Future<void> setWeeklyMode(bool value) =>
      _secureStorage.write(key: _weeklyModeKey, value: value ? 'true' : 'false');
}
