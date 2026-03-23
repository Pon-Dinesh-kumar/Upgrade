import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/notion_avatar_display.dart';
import '../../data/providers.dart';
import '../goals/goal_form_screen.dart';
import '../habits/habit_form_screen.dart';
import '../upgrades/upgrade_form_screen.dart';
import 'ai_settings_screen.dart';
import 'ai_providers.dart';
import 'domain/ai_models.dart';

class UpgradeAIScreen extends ConsumerStatefulWidget {
  const UpgradeAIScreen({super.key});

  @override
  ConsumerState<UpgradeAIScreen> createState() => _UpgradeAIScreenState();
}

class _UpgradeAIScreenState extends ConsumerState<UpgradeAIScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AIChatMessage> _messages = [];
  final List<AIToolAction> _pendingActions = [];
  bool _sending = false;
  String? _error;
  bool _hasApiKey = false;
  Timer? _typingTimer;
  int _typingDots = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadAIPreferences();
  }

  Future<void> _loadAIPreferences() async {
    final store = ref.read(aiSettingsStoreProvider);
    final hasApiKey = (await store.getApiKey())?.trim().isNotEmpty == true;
    if (!mounted) return;
    setState(() {
      _hasApiKey = hasApiKey;
    });
  }

  void _setSendingState(bool sending) {
    if (_sending == sending) return;
    if (sending) {
      _typingTimer?.cancel();
      _typingTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted) return;
        setState(() => _typingDots = (_typingDots + 1) % 4);
      });
    } else {
      _typingTimer?.cancel();
      _typingTimer = null;
      _typingDots = 0;
    }
    _sending = sending;
  }

  Future<void> _loadHistory() async {
    final orchestrator = await ref.read(coachOrchestratorProvider.future);
    final history = await orchestrator.loadHistory();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(history);
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    _controller.clear();
    await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty || _sending) return;
    if (!_hasApiKey) {
      setState(() => _error = 'Set your Gemini API key to start chatting with Upgrade AI.');
      return;
    }
    setState(() {
      _setSendingState(true);
      _error = null;
      _messages.add(
        AIChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: AIMessageRole.user,
          content: cleaned,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final orchestrator = await ref.read(coachOrchestratorProvider.future);
      final response = await orchestrator.sendUserMessage(cleaned);
      setState(() {
        _messages.add(
          AIChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: AIMessageRole.assistant,
            content: response.reply,
            createdAt: DateTime.now(),
          ),
        );
        _pendingActions
          ..clear()
          ..addAll(response.proposedActions);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _setSendingState(false));
      }
      _scrollToBottom();
    }
  }

  Future<void> _showQuickApiSetupDialog() async {
    final store = ref.read(aiSettingsStoreProvider);
    final currentModel = await store.getModel();
    final keyCtrl = TextEditingController(text: await store.getApiKey() ?? '');
    String model = currentModel;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Set up Upgrade AI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Paste your Gemini API key')),
              const SizedBox(height: 8),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'AIza...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: model,
                items: const [
                  DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('gemini-2.5-flash')),
                  DropdownMenuItem(value: 'gemini-flash-latest', child: Text('gemini-flash-latest')),
                  DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('gemini-2.0-flash')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() => model = v);
                },
                decoration: const InputDecoration(labelText: 'Model'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final key = keyCtrl.text.trim();
                if (key.isEmpty) return;
                await store.setProvider('gemini');
                await store.setModel(model);
                await store.setApiKey(key);
                if (!mounted) return;
                setState(() {
                  _hasApiKey = true;
                  _error = null;
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    keyCtrl.dispose();
  }

  Future<void> _editAndResendUserMessage(AIChatMessage message) async {
    final ctrl = TextEditingController(text: message.content);
    final edited = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit and resend'),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Resend'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (edited == null || edited.trim().isEmpty) return;
    await _sendMessage(edited);
  }

  Future<void> _reviewAndRun(AIToolAction action) async {
    switch (action.type) {
      case AIToolActionType.createHabit:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HabitFormScreen(initialDraft: action.payload)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
      case AIToolActionType.editHabit:
        final habitId = action.payload['id']?.toString();
        if (habitId == null || habitId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit not identified. Ask coach to specify which habit to edit.')),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HabitFormScreen(habitId: habitId)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
      case AIToolActionType.createUpgrade:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => UpgradeFormScreen(initialDraft: action.payload)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
      case AIToolActionType.editUpgrade:
        final upgradeId = action.payload['id']?.toString();
        if (upgradeId == null || upgradeId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upgrade not identified. Ask coach to specify which upgrade to edit.')),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => UpgradeFormScreen(upgradeId: upgradeId)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
      case AIToolActionType.createGoal:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalFormScreen(initialDraft: action.payload)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
      case AIToolActionType.editGoal:
        final goalId = action.payload['id']?.toString();
        if (goalId == null || goalId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal not identified. Ask coach to specify which goal to edit.')),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalFormScreen(goalId: goalId)),
        );
        if (mounted) {
          setState(() => _pendingActions.removeWhere((a) => a.id == action.id));
        }
        return;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _actionTitle(AIToolAction action) {
    switch (action.type) {
      case AIToolActionType.createHabit:
        return 'Create habit';
      case AIToolActionType.editHabit:
        return 'Edit habit';
      case AIToolActionType.createUpgrade:
        return 'Create upgrade';
      case AIToolActionType.editUpgrade:
        return 'Edit upgrade';
      case AIToolActionType.createGoal:
        return 'Create goal';
      case AIToolActionType.editGoal:
        return 'Edit goal';
    }
  }

  String _actionSummary(AIToolAction action) {
    final p = action.payload;
    switch (action.type) {
      case AIToolActionType.createHabit:
      case AIToolActionType.editHabit:
        return 'Habit: ${p['name'] ?? '(name not specified)'}'
            '${p['frequency'] != null ? '\nFrequency: ${p['frequency']}' : ''}'
            '${p['difficulty'] != null ? '\nDifficulty: ${p['difficulty']}' : ''}';
      case AIToolActionType.createUpgrade:
      case AIToolActionType.editUpgrade:
        return 'Upgrade: ${p['name'] ?? '(name not specified)'}'
            '${p['difficulty'] != null ? '\nImpact: ${p['difficulty']}' : ''}'
            '${p['endDate'] != null ? '\nEnd date: ${p['endDate']}' : ''}';
      case AIToolActionType.createGoal:
      case AIToolActionType.editGoal:
        return 'Goal: ${p['name'] ?? '(name not specified)'}'
            '${p['targetDate'] != null ? '\nTarget date: ${p['targetDate']}' : ''}';
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade AI'),
            SizedBox(height: 2),
            Text(
              'Your personal accountability partner',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'AI settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AISettingsScreen()),
              );
              await _loadAIPreferences();
            },
          ),
          IconButton(
            tooltip: 'Clear chat memory',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final clear = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear chat memory?'),
                      content: const Text(
                        'This will permanently remove AI chat memory and active context.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!clear) return;
              final orchestrator = await ref.read(coachOrchestratorProvider.future);
              await orchestrator.clearHistory();
              if (!mounted) return;
              setState(() {
                _messages.clear();
                _pendingActions.clear();
                _error = null;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasApiKey)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: CardShell(
                borderColor: AppColors.blue.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.blue,
                          child: AppLogoIcon(size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Welcome to Upgrade AI', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Get personalized accountability, habit planning, and proactive coaching.'),
                    const SizedBox(height: 8),
                    const Text('1) Create Gemini API key in Google AI Studio'),
                    const Text('2) Paste it below'),
                    const Text('3) Start coaching chat'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _showQuickApiSetupDialog,
                          icon: const Icon(Icons.key_rounded),
                          label: const Text('Set API Key Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: AppColors.red.withValues(alpha: 0.1),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + _pendingActions.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final m = _messages[index];
                  final isUser = m.role == AIMessageRole.user;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.blue,
                            child: AppLogoIcon(size: 16),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: GestureDetector(
                            onLongPress: isUser ? () => _editAndResendUserMessage(m) : null,
                            child: CardShell(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              borderColor: isUser ? AppColors.blue.withValues(alpha: 0.5) : null,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Text(m.content, style: theme.textTheme.bodyMedium),
                              ),
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          ClipOval(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: profile != null
                                  ? NotionAvatarDisplay(avatarData: profile.avatarData, size: 28)
                                  : CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.grey.shade300,
                                      child: const Icon(Icons.person_rounded, size: 16, color: Colors.black87),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                if (_sending && index == _messages.length) {
                  final dots = '.' * _typingDots;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.blue,
                          child: AppLogoIcon(size: 16),
                        ),
                        const SizedBox(width: 8),
                        CardShell(
                          borderColor: AppColors.blue.withValues(alpha: 0.35),
                          child: Text(
                            'Coach is thinking$dots',
                            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final actionStart = _messages.length + (_sending ? 1 : 0);
                final action = _pendingActions[index - actionStart];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CardShell(
                    padding: const EdgeInsets.all(12),
                    borderColor: AppColors.amber.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposed action: ${_actionTitle(action)}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(action.reason, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(_actionSummary(action), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton(onPressed: () => _reviewAndRun(action), child: const Text('Open Editor')),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => setState(
                                () => _pendingActions.removeWhere((a) => a.id == action.id),
                              ),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_messages.isEmpty && _hasApiKey)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Start weekly planning'),
                    onPressed: () => _sendMessage('Create my weekly plan and ask what you need first.'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Habit audit'),
                    onPressed: () => _sendMessage('Audit my habits and ask follow-up questions before edits.'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Focus mode'),
                    onPressed: () => _sendMessage('Give me one hard task today and hold me accountable.'),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintText: _hasApiKey ? 'Tell coach your goal...' : 'Set API key first...',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
