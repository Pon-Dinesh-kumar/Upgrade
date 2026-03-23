import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/providers.dart';
import 'application/coach_orchestrator.dart';
import 'application/context_assembler.dart';
import 'infrastructure/ai_settings_store.dart';
import 'infrastructure/memory/ai_memory_store.dart';
import 'infrastructure/providers/gemini_provider.dart';
import 'infrastructure/providers/llm_provider.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final aiSettingsStoreProvider = Provider<AISettingsStore>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AISettingsStore(storage);
});

final aiMemoryStoreProvider = FutureProvider<AIMemoryStore>((ref) async {
  final local = await ref.watch(localStorageProvider.future);
  return AIMemoryStore(local);
});

final llmProviderProvider = Provider<LLMProvider>((ref) {
  return GeminiProvider();
});

final coachOrchestratorProvider = FutureProvider<CoachOrchestrator>((ref) async {
  final memoryStore = await ref.watch(aiMemoryStoreProvider.future);
  final settingsStore = ref.watch(aiSettingsStoreProvider);
  final llm = ref.watch(llmProviderProvider);
  final context = ContextAssembler(ref);
  return CoachOrchestrator(
    ref,
    provider: llm,
    memoryStore: memoryStore,
    settingsStore: settingsStore,
    contextAssembler: context,
  );
});
