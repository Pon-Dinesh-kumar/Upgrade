import '../../../../data/datasources/local/local_storage.dart';
import '../../domain/ai_models.dart';

class AIMemoryStore {
  static const _key = 'ai_coach_memory';
  final LocalStorage _storage;

  AIMemoryStore(this._storage);

  Future<AIMemoryState> load() async {
    final raw = await _storage.readObject(_key);
    if (raw == null) return AIMemoryState.empty();
    return AIMemoryState.fromJson(raw);
  }

  Future<void> save(AIMemoryState state) async {
    await _storage.writeObject(_key, state.toJson());
  }

  Future<void> clear() => _storage.deleteFile(_key);
}
