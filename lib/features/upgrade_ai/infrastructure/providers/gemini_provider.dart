import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/ai_models.dart';
import 'llm_provider.dart';

class GeminiProvider implements LLMProvider {
  static const List<String> _apiBases = [
    'https://generativelanguage.googleapis.com/v1beta',
    'https://generativelanguage.googleapis.com/v1',
  ];
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-flash-latest',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  @override
  Future<String> generate({
    required AIProviderConfig config,
    required String systemInstruction,
    required List<AIChatMessage> messages,
    required String context,
  }) async {
    final conversationText =
        messages.map((m) => '[${m.role.name.toUpperCase()}] ${m.content}').join('\n\n');

    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': '''
CONTEXT:
$context

RECENT_CONVERSATION:
$conversationText

Respond ONLY with valid JSON:
{
  "reply": "assistant message to user",
  "proposedActions": [
    {
      "id": "string",
      "type": "createHabit|editHabit|createUpgrade|editUpgrade|createGoal|editGoal",
      "reason": "why this action helps accountability",
      "payload": { "..." : "..." }
    }
  ]
}

If no actions are needed, return empty array for proposedActions.
'''
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topP': 0.9,
        'maxOutputTokens': 1200,
      }
    };

    final supported = await _listSupportedGenerateModels(config.apiKey);
    final candidates = <String>[
      if (supported.contains(config.model)) config.model,
      ..._fallbackModels.where(supported.contains),
      if (supported.isEmpty) ...[
        config.model,
        ..._fallbackModels.where((m) => m != config.model),
      ],
    ].toSet().toList();

    final failures = <String>[];

    for (final model in candidates) {
      try {
        final text = await _tryGenerate(model: model, apiKey: config.apiKey, body: body);
        return text;
      } catch (e) {
        failures.add('$model: $e');
      }
    }

    throw Exception(
      'Gemini request failed for all candidate models. ${failures.join(' | ')}',
    );
  }

  Future<String> _tryGenerate({
    required String model,
    required String apiKey,
    required Map<String, dynamic> body,
  }) async {
    http.Response? resp;
    for (final base in _apiBases) {
      final uri = Uri.parse('$base/models/$model:generateContent');
      final current = await _postWithRetry(uri: uri, body: body, apiKey: apiKey);
      if (current.statusCode == 404) {
        resp = current;
        continue;
      }
      resp = current;
      break;
    }
    if (resp == null) {
      throw Exception('No response from Gemini API.');
    }

    if (resp.statusCode == 404) {
      throw Exception('Model not available for this API key/version (404).');
    }
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw Exception('API key rejected (${resp.statusCode}). Check Gemini key permissions.');
    }
    if (resp.statusCode == 429) {
      throw Exception('Rate limit reached (429). Try again shortly.');
    }
    if (resp.statusCode >= 500) {
      throw Exception('Gemini server error (${resp.statusCode}).');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Gemini request failed (${resp.statusCode}): ${resp.body}');
    }

    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final promptFeedback = map['promptFeedback'] as Map?;
    final blockReason = promptFeedback?['blockReason']?.toString();
    if (blockReason != null && blockReason.isNotEmpty) {
      throw Exception('Gemini blocked response: $blockReason');
    }
    final candidates = (map['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned no candidates. Response body: ${resp.body}');
    }
    final first = candidates.first as Map;
    final content = first['content'] as Map?;
    final parts = (content?['parts'] as List?) ?? const [];
    if (parts.isEmpty) throw Exception('Gemini returned empty response');
    final text = (parts.first as Map)['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned empty text');
    }
    return text.trim();
  }

  Future<http.Response> _postWithRetry({
    required Uri uri,
    required Map<String, dynamic> body,
    required String apiKey,
  }) async {
    const backoff = [1, 2, 4];
    Exception? lastError;
    for (var i = 0; i < backoff.length; i++) {
      try {
        final resp = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 35));
        if (resp.statusCode != 429) return resp;
        if (i == backoff.length - 1) return resp;
      } on SocketException {
        lastError = Exception('Network DNS/connection failed. Check internet connection.');
        if (i == backoff.length - 1) rethrow;
      } on HttpException catch (e) {
        lastError = Exception('HTTP connection failed: ${e.message}');
        if (i == backoff.length - 1) rethrow;
      } on FormatException catch (e) {
        throw Exception('Invalid request format: ${e.message}');
      } on Exception catch (e) {
        lastError = Exception('Gemini request failed: $e');
        if (i == backoff.length - 1) rethrow;
      }
      await Future.delayed(Duration(seconds: backoff[i]));
    }
    throw lastError ?? Exception('Gemini request failed');
  }

  Future<Set<String>> _listSupportedGenerateModels(String apiKey) async {
    try {
      final out = <String>{};
      for (final base in _apiBases) {
        final uri = Uri.parse('$base/models');
        final resp = await http.get(
          uri,
          headers: {'x-goog-api-key': apiKey},
        ).timeout(const Duration(seconds: 20));
        if (resp.statusCode < 200 || resp.statusCode >= 300) continue;
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        final models = (map['models'] as List?) ?? const [];
        for (final item in models.whereType<Map>()) {
          final methods = ((item['supportedGenerationMethods'] as List?) ?? const [])
              .map((e) => e.toString())
              .toSet();
          if (!methods.contains('generateContent')) continue;
          final name = item['name']?.toString() ?? '';
          if (name.startsWith('models/')) {
            out.add(name.substring('models/'.length));
          }
        }
      }
      return out;
    } catch (_) {
      return <String>{};
    }
  }
}
