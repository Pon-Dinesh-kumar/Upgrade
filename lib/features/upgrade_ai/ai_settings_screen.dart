import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import 'ai_providers.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _keyCtrl = TextEditingController();
  String _model = 'gemini-2.5-flash';
  double _strictness = 1;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(aiSettingsStoreProvider);
    final model = await store.getModel();
    final key = await store.getApiKey() ?? '';
    final strictness = await store.getStrictness();
    if (!mounted) return;
    setState(() {
      _model = model;
      _keyCtrl.text = key;
      _strictness = strictness.toDouble();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final store = ref.read(aiSettingsStoreProvider);
    setState(() => _saving = true);
    await store.setProvider('gemini');
    await store.setModel(_model);
    await store.setStrictness(_strictness.round());
    if (_keyCtrl.text.trim().isNotEmpty) {
      await store.setApiKey(_keyCtrl.text.trim());
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI settings saved')),
    );
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          CardShell(
            child: Column(
              children: [
                TextField(
                  controller: _keyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API key',
                    hintText: 'AIza...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _model,
                  items: const [
                    DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('gemini-2.5-flash')),
                    DropdownMenuItem(value: 'gemini-flash-latest', child: Text('gemini-flash-latest')),
                    DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('gemini-2.0-flash')),
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('gemini-1.5-flash')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _model = v);
                  },
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Strictness: ${['Supportive', 'Balanced', 'Drill Sergeant'][_strictness.round()]}',
                  ),
                ),
                Slider(
                  value: _strictness,
                  min: 0,
                  max: 2,
                  divisions: 2,
                  onChanged: (v) => setState(() => _strictness = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving...' : 'Save AI Settings'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(aiSettingsStoreProvider).clearApiKey();
              if (!context.mounted) return;
              _keyCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API key cleared'),
                  backgroundColor: AppColors.red,
                ),
              );
            },
            child: const Text('Clear API key'),
          ),
        ],
      ),
    );
  }
}
