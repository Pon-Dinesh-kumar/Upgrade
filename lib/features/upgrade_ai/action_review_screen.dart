import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/widgets/card_shell.dart';
import 'domain/ai_models.dart';

class AIActionReviewScreen extends StatefulWidget {
  final AIToolAction action;
  final String title;

  const AIActionReviewScreen({
    super.key,
    required this.action,
    required this.title,
  });

  @override
  State<AIActionReviewScreen> createState() => _AIActionReviewScreenState();
}

class _AIActionReviewScreenState extends State<AIActionReviewScreen> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final sorted = widget.action.payload.keys.toList()..sort();
    _controllers = {
      for (final k in sorted)
        k: TextEditingController(text: _stringify(widget.action.payload[k])),
    };
  }

  String _stringify(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return jsonEncode(v);
  }

  dynamic _parseValue(String input) {
    final t = input.trim();
    if (t.isEmpty) return '';
    if (t == 'true') return true;
    if (t == 'false') return false;
    final intVal = int.tryParse(t);
    if (intVal != null) return intVal;
    final doubleVal = double.tryParse(t);
    if (doubleVal != null) return doubleVal;
    if ((t.startsWith('[') && t.endsWith(']')) || (t.startsWith('{') && t.endsWith('}'))) {
      try {
        return jsonDecode(t);
      } catch (_) {}
    }
    return t;
  }

  void _confirm() {
    final payload = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      payload[entry.key] = _parseValue(entry.value.text);
    }
    Navigator.of(context).pop(
      AIToolAction(
        id: widget.action.id,
        type: widget.action.type,
        reason: widget.action.reason,
        payload: payload,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Review: ${widget.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardShell(
            child: Text(
              widget.action.reason,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          ..._controllers.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: entry.value,
                maxLines: entry.value.text.length > 80 ? 4 : 1,
                decoration: InputDecoration(
                  labelText: entry.key,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _confirm,
            child: const Text('Confirm'),
          ),
        ),
      ),
    );
  }
}
