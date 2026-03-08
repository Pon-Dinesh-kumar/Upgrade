import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/utils/gamification_engine.dart';
import '../../data/providers.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/upgrade_group.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const GoalFormScreen({super.key, this.goalId});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _outcomeCtrl;

  DateTime? _targetDate;
  Set<String> _linkedHabitIds = {};
  Set<String> _linkedUpgradeIds = {};
  String _status = 'active';
  bool _saving = false;

  bool get _isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _outcomeCtrl = TextEditingController();

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final goals = ref.read(goalsProvider).valueOrNull ?? [];
    final existing = goals.where((g) => g.id == widget.goalId).firstOrNull;
    if (existing == null) return;

    _nameCtrl.text = existing.name;
    _descCtrl.text = existing.description;
    _outcomeCtrl.text = existing.outcomeDescription ?? '';
    setState(() {
      _targetDate = existing.targetDate;
      _linkedHabitIds = existing.linkedHabitIds.toSet();
      _linkedUpgradeIds = existing.linkedUpgradeIds.toSet();
      _status = existing.status;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _outcomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (_isEditing) {
        final goals = ref.read(goalsProvider).valueOrNull ?? [];
        final existing =
            goals.where((g) => g.id == widget.goalId).firstOrNull;
        if (existing != null) {
          await ref.read(goalsProvider.notifier).save(
                existing.copyWith(
                  name: _nameCtrl.text.trim(),
                  description: _descCtrl.text.trim(),
                  outcomeDescription: _outcomeCtrl.text.trim().isEmpty
                      ? null
                      : _outcomeCtrl.text.trim(),
                  targetDate: _targetDate,
                  linkedHabitIds: _linkedHabitIds.toList(),
                  linkedUpgradeIds: _linkedUpgradeIds.toList(),
                  status: _status,
                ),
              );
        }
      } else {
        await ref.read(goalsProvider.notifier).save(
              Goal(
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                outcomeDescription: _outcomeCtrl.text.trim().isEmpty
                    ? null
                    : _outcomeCtrl.text.trim(),
                targetDate: _targetDate,
                linkedHabitIds: _linkedHabitIds.toList(),
                linkedUpgradeIds: _linkedUpgradeIds.toList(),
                status: _status,
              ),
            );
      }

      await ref.read(gamificationEngineProvider).checkGoalAchievements();
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);
    final upgradesAsync = ref.watch(upgradesProvider);

    final allHabits = habitsAsync.valueOrNull
            ?.where((h) => !h.archived)
            .toList() ??
        <Habit>[];
    final allUpgrades = upgradesAsync.valueOrNull
            ?.where((u) => !u.archived)
            .toList() ??
        <UpgradeGroup>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'New Goal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. Run a marathon',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details about this goal',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outcomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Outcome Description',
                hintText: 'What does success look like?',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 24),
            CardShell(
              onTap: _pickTargetDate,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: AppColors.blue, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _targetDate == null
                          ? 'Set target date'
                          : 'Target: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (_targetDate != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () =>
                          setState(() => _targetDate = null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _LinkedSection<Habit>(
              title: 'Link Habits',
              items: allHabits,
              selectedIds: _linkedHabitIds,
              getId: (h) => h.id,
              getLabel: (h) => h.name,
              getIcon: (h) =>
                  IconData(h.iconCodePoint, fontFamily: 'MaterialIcons'),
              getColor: (h) => Color(h.color),
              onChanged: (ids) => setState(() => _linkedHabitIds = ids),
            ),
            const SizedBox(height: 20),
            _LinkedSection<UpgradeGroup>(
              title: 'Link Upgrades',
              items: allUpgrades,
              selectedIds: _linkedUpgradeIds,
              getId: (u) => u.id,
              getLabel: (u) => u.name,
              getIcon: (u) =>
                  IconData(u.iconCodePoint, fontFamily: 'MaterialIcons'),
              getColor: (u) => Color(u.color),
              onChanged: (ids) =>
                  setState(() => _linkedUpgradeIds = ids),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Text('Status', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              _StatusSelector(
                selected: _status,
                onChanged: (s) => setState(() => _status = s),
              ),
            ],
          ].animate().fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}

class _LinkedSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Set<String> selectedIds;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final IconData Function(T) getIcon;
  final Color Function(T) getColor;
  final ValueChanged<Set<String>> onChanged;

  const _LinkedSection({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.getId,
    required this.getLabel,
    required this.getIcon,
    required this.getColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            'No items available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final id = getId(item);
              final isSelected = selectedIds.contains(id);
              final color = getColor(item);

              return FilterChip(
                selected: isSelected,
                avatar: Icon(getIcon(item), size: 18, color: color),
                label: Text(getLabel(item)),
                onSelected: (selected) {
                  final updated = Set<String>.from(selectedIds);
                  if (selected) {
                    updated.add(id);
                  } else {
                    updated.remove(id);
                  }
                  onChanged(updated);
                },
                selectedColor: color.withValues(alpha: 0.15),
                checkmarkColor: color,
                side: isSelected
                    ? BorderSide(color: color.withValues(alpha: 0.5))
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _StatusSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _statuses = ['active', 'completed', 'expired'];

  static Color _color(String s) {
    switch (s) {
      case 'active':
        return AppColors.blue;
      case 'completed':
        return AppColors.green;
      case 'expired':
        return AppColors.red;
      default:
        return AppColors.blue;
    }
  }

  static IconData _icon(String s) {
    switch (s) {
      case 'active':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'expired':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _statuses.map((s) {
        final isSelected = s == selected;
        final color = _color(s);
        final label = s[0].toUpperCase() + s.substring(1);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: isSelected,
            avatar: Icon(_icon(s), size: 18, color: color),
            label: Text(label),
            onSelected: (_) => onChanged(s),
            selectedColor: color.withValues(alpha: 0.15),
            side: isSelected
                ? BorderSide(color: color.withValues(alpha: 0.5))
                : null,
          ),
        );
      }).toList(),
    );
  }
}
