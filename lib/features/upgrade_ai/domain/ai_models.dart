import 'dart:convert';

enum AIMessageRole { system, user, assistant }

class AIChatMessage {
  final String id;
  final AIMessageRole role;
  final String content;
  final DateTime createdAt;

  AIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AIChatMessage.fromJson(Map<String, dynamic> json) => AIChatMessage(
        id: (json['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
        role: AIMessageRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => AIMessageRole.user,
        ),
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum AIToolActionType {
  createHabit,
  editHabit,
  createUpgrade,
  editUpgrade,
  createGoal,
  editGoal,
}

class AIToolAction {
  final String id;
  final AIToolActionType type;
  final Map<String, dynamic> payload;
  final String reason;

  AIToolAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'reason': reason,
      };

  factory AIToolAction.fromJson(Map<String, dynamic> json) => AIToolAction(
        id: (json['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
        type: AIToolActionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AIToolActionType.createGoal,
        ),
        payload: (json['payload'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v),
            ) ??
            <String, dynamic>{},
        reason: json['reason'] as String? ?? '',
      );
}

class AIProviderConfig {
  final String providerId;
  final String model;
  final String apiKey;

  AIProviderConfig({
    required this.providerId,
    required this.model,
    required this.apiKey,
  });
}

class AIContextSnapshot {
  final String compactSummary;
  final String fullContext;

  AIContextSnapshot({
    required this.compactSummary,
    required this.fullContext,
  });
}

class AIAssistantResponse {
  final String reply;
  final List<AIToolAction> proposedActions;

  AIAssistantResponse({
    required this.reply,
    required this.proposedActions,
  });
}

class AIMemoryState {
  final List<AIChatMessage> recentMessages;
  final String longTermSummary;
  final List<String> activeCommitments;

  AIMemoryState({
    required this.recentMessages,
    required this.longTermSummary,
    required this.activeCommitments,
  });

  Map<String, dynamic> toJson() => {
        'recentMessages': recentMessages.map((e) => e.toJson()).toList(),
        'longTermSummary': longTermSummary,
        'activeCommitments': activeCommitments,
      };

  factory AIMemoryState.fromJson(Map<String, dynamic> json) => AIMemoryState(
        recentMessages: ((json['recentMessages'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => AIChatMessage.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v))))
            .toList(),
        longTermSummary: json['longTermSummary'] as String? ?? '',
        activeCommitments: ((json['activeCommitments'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  static AIMemoryState empty() => AIMemoryState(
        recentMessages: const [],
        longTermSummary: '',
        activeCommitments: const [],
      );
}

AIAssistantResponse parseAIResponse(String raw) {
  // Try to find a JSON block in the response
  String content = raw.trim();

  // 1. Try to extract from markdown code blocks if present
  final jsonPattern = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
  final matches = jsonPattern.allMatches(content);
  
  if (matches.isNotEmpty) {
    for (final match in matches) {
      final candidate = match.group(1)!.trim();
      if (candidate.contains('"reply"') || candidate.contains('"proposedActions"')) {
        content = candidate;
        break;
      }
    }
  } else {
    // 2. Try to find the first { and last } if no markdown block
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start >= 0 && end > start) {
      content = content.substring(start, end + 1);
    }
  }

  Map<String, dynamic>? jsonMap;
  try {
    jsonMap = jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    // 3. Fallback for raw text that might be valid JSON but missing braces or with extra text
    final looksLikeJson = raw.trim().startsWith('{') || 
                         raw.trim().contains('"proposedActions"') || 
                         raw.trim().contains('"reply"');
    if (looksLikeJson && raw.length < 2000) {
      // If it's short, it might just be the AI talking normally or a slightly malformed JSON
      if (!raw.contains('{')) {
        return AIAssistantResponse(reply: raw.trim(), proposedActions: const []);
      }
    }
    return AIAssistantResponse(reply: raw.trim(), proposedActions: const []);
  }

  final reply = jsonMap['reply']?.toString() ?? '';
  
  // Robustly handle proposedActions being null, a single map, or a list
  final actionsRaw = jsonMap['proposedActions'];
  final List<AIToolAction> actionList = [];
  
  if (actionsRaw is List) {
    for (final item in actionsRaw) {
      if (item is Map) {
        try {
          actionList.add(AIToolAction.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v))
          ));
        } catch (_) {}
      }
    }
  } else if (actionsRaw is Map) {
    try {
      actionList.add(AIToolAction.fromJson(
        actionsRaw.map((k, v) => MapEntry(k.toString(), v))
      ));
    } catch (_) {}
  }

  return AIAssistantResponse(
    reply: reply.isNotEmpty ? reply : raw.trim(),
    proposedActions: actionList,
  );
}
