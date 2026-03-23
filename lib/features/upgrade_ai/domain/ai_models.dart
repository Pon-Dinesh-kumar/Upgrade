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
  // Expect JSON body: {"reply":"...", "proposedActions":[...]}
  String normalized = raw.trim();
  if (normalized.startsWith('```')) {
    final firstNewline = normalized.indexOf('\n');
    final lastFence = normalized.lastIndexOf('```');
    if (firstNewline > 0 && lastFence > firstNewline) {
      normalized = normalized.substring(firstNewline + 1, lastFence).trim();
    }
  }

  Map<String, dynamic>? jsonMap;
  try {
    jsonMap = jsonDecode(normalized) as Map<String, dynamic>;
  } catch (_) {
    final start = normalized.indexOf('{');
    final end = normalized.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final candidate = normalized.substring(start, end + 1);
      try {
        jsonMap = jsonDecode(candidate) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  if (jsonMap == null) {
    return AIAssistantResponse(reply: normalized.trim(), proposedActions: const []);
  }

  final actionList = ((jsonMap['proposedActions'] as List?) ?? const [])
      .whereType<Map>()
      .map((m) => AIToolAction.fromJson(
          m.map((k, v) => MapEntry(k.toString(), v))))
      .toList();
  final reply = (jsonMap['reply'] as String?)?.trim();
  return AIAssistantResponse(
    reply: (reply == null || reply.isEmpty) ? normalized.trim() : reply,
    proposedActions: actionList,
  );
}
