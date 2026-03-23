import '../../domain/ai_models.dart';

abstract class LLMProvider {
  Future<String> generate({
    required AIProviderConfig config,
    required String systemInstruction,
    required List<AIChatMessage> messages,
    required String context,
  });
}
