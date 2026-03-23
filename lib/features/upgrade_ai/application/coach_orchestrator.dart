import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/gamification_engine.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/timeline_event.dart';
import '../../../domain/entities/upgrade_group.dart';
import '../domain/ai_models.dart';
import '../infrastructure/ai_settings_store.dart';
import '../infrastructure/memory/ai_memory_store.dart';
import '../infrastructure/providers/llm_provider.dart';
import 'context_assembler.dart';

class CoachOrchestrator {
  final Ref _ref;
  final LLMProvider _provider;
  final AIMemoryStore _memoryStore;
  final AISettingsStore _settingsStore;
  final ContextAssembler _contextAssembler;
  final _id = const Uuid();

  CoachOrchestrator(
    this._ref, {
    required LLMProvider provider,
    required AIMemoryStore memoryStore,
    required AISettingsStore settingsStore,
    required ContextAssembler contextAssembler,
  })  : _provider = provider,
        _memoryStore = memoryStore,
        _settingsStore = settingsStore,
        _contextAssembler = contextAssembler;

  static const coachSystemInstruction = '''
You are Upgrade AI Coach: warm, human, strict, accountability-first.
Primary objective: improve user's habits, consistency, and upgrade completion.

Conversation style:
- Sound like a real coach, not a robotic assistant.
- Start with empathy + short reflection, then practical direction.
- Keep answers concise and natural (usually 4-10 lines unless asked for deep detail).
- Ask clarifying questions when intent is unclear.
- Avoid dumping schema, JSON, payloads, or internal details to the user.

Action policy:
- Prefer conversation and planning first.
- By default, do not propose app-changing actions in the first response to a topic.
- First ask 1-2 clarifying questions if requirements are incomplete.
- Only propose app-changing actions when user explicitly asks to create/edit/update/delete or says "apply/go ahead".
- Never claim an action is executed; execution happens only after user confirmation.
- Allowed action types: createHabit, editHabit, createUpgrade, editUpgrade, createGoal, editGoal.

Response requirements:
- End with one concrete next step.
- If user sounds overwhelmed, reduce plan to one tiny action.
- Use provided context as source of truth.
- Never show JSON, schema or tool internals in user-facing prose.
- Before proposing any create/edit action, ask for all missing required fields.
''';

  String _strictnessStyleInstruction(int strictness) {
    switch (strictness) {
      case 0:
        return '''
STRICTNESS_MODE: Supportive
- Tone: encouraging and gentle.
- Challenge softly; avoid harsh language.
- Prioritize confidence-building and small wins.
''';
      case 2:
        return '''
STRICTNESS_MODE: Drill Sergeant
- Tone: firm, blunt, highly accountable.
- Challenge excuses directly; maintain respect.
- Push measurable commitments and deadlines every turn.
''';
      default:
        return '''
STRICTNESS_MODE: Balanced
- Tone: supportive but firm.
- Use direct accountability with constructive coaching.
- Keep standards high without aggression.
''';
    }
  }

  Future<AIAssistantResponse> sendUserMessage(String text) async {
    final apiKey = await _settingsStore.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Gemini API key is not set. Add it in Settings > AI Coach.');
    }
    final model = await _settingsStore.getModel();
    final strictness = await _settingsStore.getStrictness();
    final cfg = AIProviderConfig(providerId: 'gemini', model: model, apiKey: apiKey);

    final memory = await _memoryStore.load();
    final updatedHistory = [
      ...memory.recentMessages,
      AIChatMessage(
        id: _id.v4(),
        role: AIMessageRole.user,
        content: text.trim(),
        createdAt: DateTime.now(),
      )
    ];
    final cappedHistory = updatedHistory.length > 40
        ? updatedHistory.sublist(updatedHistory.length - 40)
        : updatedHistory;

    final context = _contextAssembler.buildContext();
    late final String raw;
    try {
      raw = await _provider.generate(
        config: cfg,
        systemInstruction: '$coachSystemInstruction\n${_strictnessStyleInstruction(strictness)}',
        messages: cappedHistory,
        context: '''
${context.fullContext}

LONG_TERM_MEMORY:
${memory.longTermSummary}

ACTIVE_COMMITMENTS:
${memory.activeCommitments.join(', ')}
''',
      );
    } catch (e) {
      final fallbackReply = _fallbackCoachReply(text, e.toString());
      final fallback = AIAssistantResponse(
        reply: fallbackReply,
        proposedActions: const [],
      );
      final assistantMessage = AIChatMessage(
        id: _id.v4(),
        role: AIMessageRole.assistant,
        content: fallbackReply,
        createdAt: DateTime.now(),
      );
      final fallbackMessages = [...cappedHistory, assistantMessage];
      await _memoryStore.save(
        AIMemoryState(
          recentMessages: fallbackMessages.length > 50
              ? fallbackMessages.sublist(fallbackMessages.length - 50)
              : fallbackMessages,
          longTermSummary: _buildLightSummary(memory.longTermSummary, text, fallbackReply),
          activeCommitments: _extractCommitments(memory.activeCommitments, fallbackReply),
        ),
      );
      return fallback;
    }

    final parsed = parseAIResponse(raw);
    final normalizedActions = parsed.proposedActions
        .map((a) => _normalizeActionFromUserIntent(a, text))
        .toList();
    final actionGate = _filterProposedActions(parsed.reply, text, normalizedActions);
    var reply = _humanizeReply(
      actionGate.reply,
      text,
    );
    final actions = _attachActionPreviews(actionGate.actions);
    if (actions.isEmpty) {
      reply = _stripExecutionClaims(reply);
    }
    final assistantMessage = AIChatMessage(
      id: _id.v4(),
      role: AIMessageRole.assistant,
      content: reply,
      createdAt: DateTime.now(),
    );
    final newMessages = [...cappedHistory, assistantMessage];
    final compressedMessages = newMessages.length > 50
        ? newMessages.sublist(newMessages.length - 50)
        : newMessages;

    final nextMemory = AIMemoryState(
      recentMessages: compressedMessages,
      longTermSummary: _buildLightSummary(memory.longTermSummary, text, reply),
      activeCommitments: _extractCommitments(memory.activeCommitments, reply),
    );
    await _memoryStore.save(nextMemory);
    return AIAssistantResponse(reply: reply, proposedActions: actions);
  }

  Future<List<AIChatMessage>> loadHistory() async => (await _memoryStore.load()).recentMessages;

  Future<void> clearHistory() => _memoryStore.clear();

  Future<String> executeConfirmedAction(AIToolAction action) async {
    switch (action.type) {
      case AIToolActionType.createHabit:
        return _createHabit(action.payload);
      case AIToolActionType.editHabit:
        return _editHabit(action.payload);
      case AIToolActionType.createUpgrade:
        return _createUpgrade(action.payload);
      case AIToolActionType.editUpgrade:
        return _editUpgrade(action.payload);
      case AIToolActionType.createGoal:
        return _createGoal(action.payload);
      case AIToolActionType.editGoal:
        return _editGoal(action.payload);
    }
  }

  String _buildLightSummary(String oldSummary, String userText, String aiReply) {
    final latest = 'User: ${userText.trim()} | Coach: ${aiReply.trim()}';
    final merged = oldSummary.isEmpty ? latest : '$oldSummary\n$latest';
    final lines = merged.split('\n');
    return lines.length > 30 ? lines.sublist(lines.length - 30).join('\n') : merged;
  }

  List<String> _extractCommitments(List<String> current, String reply) {
    final next = List<String>.from(current);
    final lower = reply.toLowerCase();
    if (lower.contains('commit') || lower.contains('promise') || lower.contains('check-in')) {
      next.add(reply.length > 140 ? '${reply.substring(0, 140)}...' : reply);
    }
    return next.length > 25 ? next.sublist(next.length - 25) : next;
  }

  Future<String> _createHabit(Map<String, dynamic> p) async {
    final upgrades = _ref.read(upgradesProvider).valueOrNull ?? [];
    if (upgrades.isEmpty) return 'No upgrades found. Create an upgrade first.';
    final upgradeId = (p['upgradeId'] as String?) ?? upgrades.first.id;
    final habit = Habit(
      name: (p['name'] as String?)?.trim().isNotEmpty == true ? p['name'] as String : 'New Habit',
      description: (p['description'] as String?) ?? '',
      difficulty: _safeDifficulty((p['difficulty'] as String?) ?? 'medium'),
      frequency: _safeFrequency((p['frequency'] as String?) ?? 'daily'),
      targetValue: (p['targetValue'] as num?)?.toDouble(),
      unit: p['unit'] as String?,
      iconCodePoint: (p['iconCodePoint'] as int?) ?? 0xe571,
      color: (p['color'] as int?) ?? 0xFF2383E2,
      upgradeId: upgradeId,
      frequencyConfig: p['frequencyConfig'] as String?,
    );
    await _ref.read(habitsProvider.notifier).save(habit);
    await _ref.read(gamificationEngineProvider).addHabitToUpgrade(habit.id, upgradeId);
    final savedHabits = _ref.read(habitsProvider).valueOrNull ?? [];
    final persisted = savedHabits.any((h) => h.id == habit.id);
    if (!persisted) {
      return 'I could not verify that habit was saved. Please try once more.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(
            type: 'ai_action',
            title: 'AI created habit',
            description: habit.name,
            linkedEntityId: habit.id,
          ),
        );
    return 'Habit created: ${habit.name}';
  }

  Future<String> _editHabit(Map<String, dynamic> p) async {
    final resolved = _resolveHabit(p);
    if (resolved.error != null) return resolved.error!;
    final habit = resolved.found;
    if (habit == null) return 'Habit not found.';
    final updated = habit.copyWith(
      name: p['name'] as String?,
      description: p['description'] as String?,
      difficulty: p['difficulty'] != null ? _safeDifficulty(p['difficulty'].toString()) : null,
      frequency: p['frequency'] != null ? _safeFrequency(p['frequency'].toString()) : null,
      frequencyConfig: p['frequencyConfig'] as String?,
      targetValue: (p['targetValue'] as num?)?.toDouble(),
      unit: p['unit'] as String?,
      iconCodePoint: p['iconCodePoint'] as int?,
      color: p['color'] as int?,
      upgradeId: p['upgradeId'] as String?,
      archived: p['archived'] as bool?,
    );
    await _ref.read(habitsProvider.notifier).save(updated);
    final savedHabits = _ref.read(habitsProvider).valueOrNull ?? [];
    final persisted = savedHabits.where((h) => h.id == updated.id).firstOrNull;
    if (persisted == null) {
      return 'I could not verify that habit update was saved.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(type: 'ai_action', title: 'AI edited habit', description: updated.name, linkedEntityId: updated.id),
        );
    return 'Habit updated: ${updated.name}';
  }

  Future<String> _createUpgrade(Map<String, dynamic> p) async {
    final now = DateTime.now();
    final start = DateTime.tryParse((p['startDate'] as String?) ?? '') ?? DateTime(now.year, now.month, now.day);
    final end = DateTime.tryParse((p['endDate'] as String?) ?? '') ?? start.add(const Duration(days: 30));
    final upgrade = UpgradeGroup(
      name: (p['name'] as String?)?.trim().isNotEmpty == true ? p['name'] as String : 'New Upgrade',
      description: (p['description'] as String?) ?? '',
      outcomeDescription: p['outcomeDescription'] as String?,
      difficulty: _safeDifficulty((p['difficulty'] as String?) ?? 'medium'),
      iconCodePoint: (p['iconCodePoint'] as int?) ?? 0xe5d8,
      color: (p['color'] as int?) ?? 0xFF2383E2,
      startDate: start,
      endDate: end.isAfter(start) ? end : start.add(const Duration(days: 30)),
      cutoffPercentage: ((p['cutoffPercentage'] as num?)?.toDouble() ?? 0.7).clamp(0.4, 1.0),
    );
    await _ref.read(upgradesProvider.notifier).save(upgrade);
    final savedUpgrades = _ref.read(upgradesProvider).valueOrNull ?? [];
    final persisted = savedUpgrades.any((u) => u.id == upgrade.id);
    if (!persisted) {
      return 'I could not verify that upgrade was saved. Please retry.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(type: 'ai_action', title: 'AI created upgrade', description: upgrade.name, linkedEntityId: upgrade.id),
        );
    return 'Upgrade created: ${upgrade.name}';
  }

  Future<String> _editUpgrade(Map<String, dynamic> p) async {
    final resolved = _resolveUpgrade(p);
    if (resolved.error != null) return resolved.error!;
    final upgrade = resolved.found;
    if (upgrade == null) return 'Upgrade not found.';
    final updated = upgrade.copyWith(
      name: p['name'] as String?,
      description: p['description'] as String?,
      outcomeDescription: p['outcomeDescription'] as String?,
      difficulty: p['difficulty'] != null ? _safeDifficulty(p['difficulty'].toString()) : null,
      iconCodePoint: p['iconCodePoint'] as int?,
      color: p['color'] as int?,
      cutoffPercentage: (p['cutoffPercentage'] as num?)?.toDouble(),
      startDate: DateTime.tryParse((p['startDate'] as String?) ?? ''),
      endDate: DateTime.tryParse((p['endDate'] as String?) ?? ''),
      status: p['status'] as String?,
      archived: p['archived'] as bool?,
    );
    await _ref.read(upgradesProvider.notifier).save(updated);
    final savedUpgrades = _ref.read(upgradesProvider).valueOrNull ?? [];
    final persisted = savedUpgrades.where((u) => u.id == updated.id).firstOrNull;
    if (persisted == null) {
      return 'I could not verify that upgrade update was saved.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(type: 'ai_action', title: 'AI edited upgrade', description: updated.name, linkedEntityId: updated.id),
        );
    return 'Upgrade updated: ${updated.name}';
  }

  Future<String> _createGoal(Map<String, dynamic> p) async {
    final goal = Goal(
      name: (p['name'] as String?)?.trim().isNotEmpty == true ? p['name'] as String : 'New Goal',
      description: (p['description'] as String?) ?? '',
      outcomeDescription: p['outcomeDescription'] as String?,
      status: (p['status'] as String?) ?? 'active',
      targetDate: DateTime.tryParse((p['targetDate'] as String?) ?? ''),
      linkedHabitIds: ((p['linkedHabitIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      linkedUpgradeIds: ((p['linkedUpgradeIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
    await _ref.read(goalsProvider.notifier).save(goal);
    final savedGoals = _ref.read(goalsProvider).valueOrNull ?? [];
    final persisted = savedGoals.any((g) => g.id == goal.id);
    if (!persisted) {
      return 'I could not verify that goal was saved. Please retry.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(type: 'ai_action', title: 'AI created goal', description: goal.name, linkedEntityId: goal.id),
        );
    return 'Goal created: ${goal.name}';
  }

  Future<String> _editGoal(Map<String, dynamic> p) async {
    final resolved = _resolveGoal(p);
    if (resolved.error != null) return resolved.error!;
    final goal = resolved.found;
    if (goal == null) return 'Goal not found.';
    final updated = goal.copyWith(
      name: p['name'] as String?,
      description: p['description'] as String?,
      outcomeDescription: p['outcomeDescription'] as String?,
      status: p['status'] as String?,
      targetDate: DateTime.tryParse((p['targetDate'] as String?) ?? ''),
      linkedHabitIds: ((p['linkedHabitIds'] as List?) ?? goal.linkedHabitIds).map((e) => e.toString()).toList(),
      linkedUpgradeIds: ((p['linkedUpgradeIds'] as List?) ?? goal.linkedUpgradeIds).map((e) => e.toString()).toList(),
    );
    await _ref.read(goalsProvider.notifier).save(updated);
    final savedGoals = _ref.read(goalsProvider).valueOrNull ?? [];
    final persisted = savedGoals.where((g) => g.id == updated.id).firstOrNull;
    if (persisted == null) {
      return 'I could not verify that goal update was saved.';
    }
    await _ref.read(timelineProvider.notifier).addEvent(
          TimelineEvent(type: 'ai_action', title: 'AI edited goal', description: updated.name, linkedEntityId: updated.id),
        );
    return 'Goal updated: ${updated.name}';
  }

  String _safeDifficulty(String d) {
    const allowed = {'easy', 'medium', 'hard'};
    return allowed.contains(d) ? d : 'medium';
  }

  String _safeFrequency(String f) {
    const allowed = {'daily', 'weekly', 'custom'};
    return allowed.contains(f) ? f : 'daily';
  }

  String _humanizeReply(String raw, String userText) {
    var reply = raw.trim();
    if (reply.isEmpty) {
      return 'I hear you. Let us take one strong step now. Tell me what matters most this week so I can build your accountability plan.';
    }
    // Remove accidental JSON leakage if model ignored formatting.
    if (reply.startsWith('{') && reply.contains('"proposedActions"')) {
      return 'I have a plan for you. Before we make changes, tell me if you want a strict daily plan or a lighter starter plan.';
    }
    if (!reply.contains('?') && userText.trim().split(' ').length > 4) {
      reply = '$reply\n\nWhat feels hardest right now so I can coach you precisely?';
    }
    return reply;
  }

  AIToolAction _normalizeActionFromUserIntent(AIToolAction action, String userText) {
    if (action.type != AIToolActionType.createHabit && action.type != AIToolActionType.editHabit) {
      return action;
    }
    final payload = Map<String, dynamic>.from(action.payload);
    final lower = userText.toLowerCase();
    final asksDaily = lower.contains('every day') ||
        lower.contains('daily') ||
        lower.contains('each day');
    if (asksDaily) {
      payload['frequency'] = 'daily';
      payload.remove('frequencyConfig');
      return AIToolAction(
        id: action.id,
        type: action.type,
        payload: payload,
        reason: action.reason,
      );
    }
    return action;
  }

  _ActionFilterResult _filterProposedActions(
    String reply,
    String userText,
    List<AIToolAction> actions,
  ) {
    if (actions.isEmpty) return _ActionFilterResult(reply: reply, actions: actions);
    final lower = userText.toLowerCase();
    final explicitActionIntent = lower.contains('create ') ||
        lower.contains('add ') ||
        lower.contains('edit ') ||
        lower.contains('update ') ||
        lower.contains('change ') ||
        lower.contains('delete ') ||
        lower.contains('apply ') ||
        lower.contains('go ahead') ||
        lower.contains('proceed') ||
        lower.contains('set up ') ||
        lower.contains('make habits') ||
        lower.contains('build habits');

    // Don't jump to editing/creating unless user is explicit.
    if (!explicitActionIntent) return _ActionFilterResult(reply: reply, actions: const []);

    var nextReply = reply;
    final vetted = <AIToolAction>[];
    final seenSignatures = <String>{};
    for (final action in actions) {
      final missing = _missingFieldsForAction(action, userText);
      if (missing.isNotEmpty) {
        final ask = _clarificationPrompt(action, missing);
        if (!nextReply.toLowerCase().contains('before i')) {
          nextReply = '${nextReply.trim()}\n\n$ask';
        }
        continue;
      }
      final confidence = _actionConfidence(action, userText);
      if (confidence < 0.72) {
        final ask = _clarificationPrompt(
          action,
          const ['a little more detail to make this accurate'],
        );
        if (!nextReply.toLowerCase().contains('make this accurate')) {
          nextReply = '${nextReply.trim()}\n\n$ask';
        }
        continue;
      }
      final signature = _actionSignature(action);
      if (seenSignatures.contains(signature)) continue;
      seenSignatures.add(signature);
      vetted.add(action);
    }

    // Keep action list focused for UX; avoid dumping many actions at once.
    return _ActionFilterResult(reply: nextReply, actions: vetted.take(3).toList());
  }

  String _clarificationPrompt(AIToolAction action, List<String> missing) {
    return 'Before I ${_verbForAction(action.type)}, I need: ${missing.take(2).join(', ')}. '
        'Share this and I will prepare the exact change for your review.';
  }

  double _actionConfidence(AIToolAction action, String userText) {
    final p = action.payload;
    var score = 0.35;
    final lower = userText.toLowerCase();
    if (lower.contains('create') ||
        lower.contains('edit') ||
        lower.contains('update') ||
        lower.contains('add')) {
      score += 0.2;
    }
    if ((p['name'] as String?)?.trim().isNotEmpty == true) score += 0.15;
    if ((p['id'] as String?)?.trim().isNotEmpty == true) score += 0.2;
    if (action.type == AIToolActionType.createHabit ||
        action.type == AIToolActionType.editHabit) {
      if ((p['upgradeId'] as String?)?.trim().isNotEmpty == true) score += 0.1;
      if ((p['frequency'] as String?)?.trim().isNotEmpty == true) score += 0.1;
    }
    return score.clamp(0.0, 1.0);
  }

  String _actionSignature(AIToolAction action) {
    final p = action.payload;
    return '${action.type.name}|${p['id'] ?? ''}|${p['name'] ?? ''}|${p['upgradeId'] ?? ''}|${p['targetDate'] ?? ''}';
  }

  List<String> _missingFieldsForAction(AIToolAction action, String userText) {
    final p = action.payload;
    switch (action.type) {
      case AIToolActionType.createHabit:
        final missing = <String>[];
        if ((p['name'] as String?)?.trim().isEmpty ?? true) {
          missing.add('habit name');
        }
        final hasUpgrade = (p['upgradeId'] as String?)?.trim().isNotEmpty == true;
        if (!hasUpgrade) missing.add('which upgrade this habit belongs to');
        final frequency = _safeFrequency((p['frequency'] as String?) ?? 'daily');
        if (frequency == 'custom') {
          final cfg = (p['frequencyConfig'] as String?)?.trim() ?? '';
          if (_looksLikeXDaysPerWeek(userText) && !_isValidWeekdayConfig(cfg)) {
            missing.add('exact weekdays (Mon-Sun)');
          }
        }
        if (_looksLikeXDaysPerWeek(userText) &&
            (frequency != 'custom' ||
                !_isValidWeekdayConfig((p['frequencyConfig'] as String?)?.trim() ?? ''))) {
          missing.add('exact weekdays for your ${_daysPerWeek(userText)} days/week target');
        }
        return missing;
      case AIToolActionType.editHabit:
        if (!_hasIdOrName(p)) return const ['habit to edit (name or id)'];
        return const [];
      case AIToolActionType.createUpgrade:
        if ((p['name'] as String?)?.trim().isEmpty ?? true) return const ['upgrade name'];
        return const [];
      case AIToolActionType.editUpgrade:
        if (!_hasIdOrName(p)) return const ['upgrade to edit (name or id)'];
        return const [];
      case AIToolActionType.createGoal:
        if ((p['name'] as String?)?.trim().isEmpty ?? true) return const ['goal name'];
        return const [];
      case AIToolActionType.editGoal:
        if (!_hasIdOrName(p)) return const ['goal to edit (name or id)'];
        return const [];
    }
  }

  bool _hasIdOrName(Map<String, dynamic> p) {
    final id = (p['id'] as String?)?.trim() ?? '';
    final name = (p['name'] as String?)?.trim() ?? '';
    return id.isNotEmpty || name.isNotEmpty;
  }

  bool _isValidWeekdayConfig(String cfg) {
    if (cfg.isEmpty) return false;
    final parts = cfg.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
    if (parts.isEmpty) return false;
    return parts.every((d) => d >= DateTime.monday && d <= DateTime.sunday);
  }

  bool _looksLikeXDaysPerWeek(String text) {
    final t = text.toLowerCase();
    return RegExp(r'\b([1-7])\s*(days?|x)\s*(a|per)?\s*week\b').hasMatch(t) ||
        RegExp(r'\b(once|twice|thrice)\s*(a|per)?\s*week\b').hasMatch(t);
  }

  String _daysPerWeek(String text) {
    final t = text.toLowerCase();
    final m = RegExp(r'\b([1-7])\s*(days?|x)\s*(a|per)?\s*week\b').firstMatch(t);
    if (m != null) return m.group(1) ?? 'specified';
    if (t.contains('once')) return '1';
    if (t.contains('twice')) return '2';
    if (t.contains('thrice')) return '3';
    return 'specified';
  }

  List<AIToolAction> _attachActionPreviews(List<AIToolAction> actions) {
    return actions.map(_attachActionPreview).toList();
  }

  AIToolAction _attachActionPreview(AIToolAction action) {
    switch (action.type) {
      case AIToolActionType.editHabit:
        final resolved = _resolveHabit(action.payload);
        if (resolved.found == null) return action;
        final diff = _habitDiff(resolved.found!, action.payload);
        if (diff.isEmpty) return action;
        return AIToolAction(
          id: action.id,
          type: action.type,
          payload: action.payload,
          reason: '${action.reason}\nPlanned changes: $diff',
        );
      case AIToolActionType.editUpgrade:
        final resolved = _resolveUpgrade(action.payload);
        if (resolved.found == null) return action;
        final diff = _upgradeDiff(resolved.found!, action.payload);
        if (diff.isEmpty) return action;
        return AIToolAction(
          id: action.id,
          type: action.type,
          payload: action.payload,
          reason: '${action.reason}\nPlanned changes: $diff',
        );
      case AIToolActionType.editGoal:
        final resolved = _resolveGoal(action.payload);
        if (resolved.found == null) return action;
        final diff = _goalDiff(resolved.found!, action.payload);
        if (diff.isEmpty) return action;
        return AIToolAction(
          id: action.id,
          type: action.type,
          payload: action.payload,
          reason: '${action.reason}\nPlanned changes: $diff',
        );
      default:
        return action;
    }
  }

  _ResolveResult<Habit> _resolveHabit(Map<String, dynamic> p) {
    final habits = _ref.read(habitsProvider).valueOrNull ?? [];
    final id = (p['id'] as String?)?.trim() ?? '';
    final name = (p['name'] as String?)?.trim().toLowerCase() ?? '';
    if (id.isNotEmpty) return _ResolveResult(found: habits.where((h) => h.id == id).firstOrNull);
    if (name.isEmpty) return const _ResolveResult(error: 'Habit not identified. Tell me the habit name.');
    final exact = habits.where((h) => h.name.trim().toLowerCase() == name).toList();
    if (exact.length == 1) return _ResolveResult(found: exact.first);
    final fuzzy = habits.where((h) => h.name.toLowerCase().contains(name)).toList();
    if (fuzzy.length == 1) return _ResolveResult(found: fuzzy.first);
    if (fuzzy.length > 1) {
      return _ResolveResult(
        error: 'I found multiple habits: ${fuzzy.take(3).map((e) => e.name).join(', ')}. Tell me which one to edit.',
      );
    }
    return const _ResolveResult(error: 'Habit not found.');
  }

  _ResolveResult<UpgradeGroup> _resolveUpgrade(Map<String, dynamic> p) {
    final upgrades = _ref.read(upgradesProvider).valueOrNull ?? [];
    final id = (p['id'] as String?)?.trim() ?? '';
    final name = (p['name'] as String?)?.trim().toLowerCase() ?? '';
    if (id.isNotEmpty) return _ResolveResult(found: upgrades.where((u) => u.id == id).firstOrNull);
    if (name.isEmpty) return const _ResolveResult(error: 'Upgrade not identified. Tell me the upgrade name.');
    final exact = upgrades.where((u) => u.name.trim().toLowerCase() == name).toList();
    if (exact.length == 1) return _ResolveResult(found: exact.first);
    final fuzzy = upgrades.where((u) => u.name.toLowerCase().contains(name)).toList();
    if (fuzzy.length == 1) return _ResolveResult(found: fuzzy.first);
    if (fuzzy.length > 1) {
      return _ResolveResult(
        error: 'I found multiple upgrades: ${fuzzy.take(3).map((e) => e.name).join(', ')}. Tell me which one to edit.',
      );
    }
    return const _ResolveResult(error: 'Upgrade not found.');
  }

  _ResolveResult<Goal> _resolveGoal(Map<String, dynamic> p) {
    final goals = _ref.read(goalsProvider).valueOrNull ?? [];
    final id = (p['id'] as String?)?.trim() ?? '';
    final name = (p['name'] as String?)?.trim().toLowerCase() ?? '';
    if (id.isNotEmpty) return _ResolveResult(found: goals.where((g) => g.id == id).firstOrNull);
    if (name.isEmpty) return const _ResolveResult(error: 'Goal not identified. Tell me the goal name.');
    final exact = goals.where((g) => g.name.trim().toLowerCase() == name).toList();
    if (exact.length == 1) return _ResolveResult(found: exact.first);
    final fuzzy = goals.where((g) => g.name.toLowerCase().contains(name)).toList();
    if (fuzzy.length == 1) return _ResolveResult(found: fuzzy.first);
    if (fuzzy.length > 1) {
      return _ResolveResult(
        error: 'I found multiple goals: ${fuzzy.take(3).map((e) => e.name).join(', ')}. Tell me which one to edit.',
      );
    }
    return const _ResolveResult(error: 'Goal not found.');
  }

  String _habitDiff(Habit existing, Map<String, dynamic> p) {
    final changes = <String>[];
    if ((p['name'] as String?) != null && p['name'] != existing.name) changes.add('name');
    if ((p['frequency'] as String?) != null && p['frequency'] != existing.frequency) changes.add('frequency');
    if ((p['difficulty'] as String?) != null && p['difficulty'] != existing.difficulty) changes.add('difficulty');
    if ((p['targetValue'] as num?) != null && (p['targetValue'] as num).toDouble() != existing.targetValue) {
      changes.add('target');
    }
    return changes.join(', ');
  }

  String _upgradeDiff(UpgradeGroup existing, Map<String, dynamic> p) {
    final changes = <String>[];
    if ((p['name'] as String?) != null && p['name'] != existing.name) changes.add('name');
    if ((p['difficulty'] as String?) != null && p['difficulty'] != existing.difficulty) changes.add('difficulty');
    if ((p['endDate'] as String?) != null) changes.add('end date');
    return changes.join(', ');
  }

  String _goalDiff(Goal existing, Map<String, dynamic> p) {
    final changes = <String>[];
    if ((p['name'] as String?) != null && p['name'] != existing.name) changes.add('name');
    if ((p['status'] as String?) != null && p['status'] != existing.status) changes.add('status');
    if ((p['targetDate'] as String?) != null) changes.add('target date');
    return changes.join(', ');
  }

  String _verbForAction(AIToolActionType type) {
    switch (type) {
      case AIToolActionType.createHabit:
        return 'create this habit';
      case AIToolActionType.editHabit:
        return 'edit this habit';
      case AIToolActionType.createUpgrade:
        return 'create this upgrade';
      case AIToolActionType.editUpgrade:
        return 'edit this upgrade';
      case AIToolActionType.createGoal:
        return 'create this goal';
      case AIToolActionType.editGoal:
        return 'edit this goal';
    }
  }

  String _fallbackCoachReply(String userText, String error) {
    final lower = error.toLowerCase();
    if (lower.contains('429') || lower.contains('rate limit')) {
      return '''
Rate limit hit on your LLM key. We can still move now.

Next 24-hour accountability plan:
1) Pick one high-impact habit and do it today.
2) Set one measurable target for tomorrow.
3) Check in again in 2 hours with: done/not-done + blocker.

Tell me your exact goal in one line and I will draft a strict step-by-step plan while the API cools down.
''';
    }
    if (lower.contains('network') || lower.contains('dns') || lower.contains('socket')) {
      return '''
I cannot reach your LLM right now (network issue), but accountability still stands.

Do this now:
1) Confirm internet is on.
2) In Settings > AI Coach, keep model on gemini-2.5-flash.
3) Retry in 30 seconds.

Meanwhile, tell me one habit you will complete in the next hour.
''';
    }
    if (lower.contains('404') || lower.contains('model not available')) {
      return '''
Your selected model is unavailable for this API key. I can continue once a supported model responds.

Action:
1) Open Settings > AI Coach.
2) Select gemini-2.5-flash.
3) Retry your request.

Now send your goal again and I will produce a strict accountability plan.
''';
    }
    return '''
I could not reach your LLM for this turn, but your progress still matters.

Immediate accountability:
1) Define one measurable action for today.
2) Define deadline.
3) Report completion status in your next message.

Original request: "$userText"
''';
  }

  String _stripExecutionClaims(String reply) {
    final lower = reply.toLowerCase();
    final hasClaim = lower.contains('created') ||
        lower.contains('updated') ||
        lower.contains('edited') ||
        lower.contains('done') ||
        lower.contains('completed') ||
        lower.contains('i have added') ||
        lower.contains('i added') ||
        lower.contains('i changed');
    if (!hasClaim) return reply;
    return '''I have a concrete plan, but I have not executed any app changes yet.
Review the proposed action card and confirm, or share missing details so I can prepare the exact edit.

$reply''';
  }
}

class _ActionFilterResult {
  final String reply;
  final List<AIToolAction> actions;

  const _ActionFilterResult({
    required this.reply,
    required this.actions,
  });
}

class _ResolveResult<T> {
  final T? found;
  final String? error;
  const _ResolveResult({this.found, this.error});
}
