import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/gamification_engine.dart';
import '../../data/providers.dart';
import '../../domain/entities/habit.dart';

const _iconOptions = <int>[
  0xe571, 0xe0f7, 0xf06bb, 0xe25a, 0xe3aa, 0xe332,
  0xe52f, 0xe1e1, 0xe534, 0xe310, 0xe539, 0xe559,
  0xe1b1, 0xe065, 0xe900, 0xe043, 0xe491, 0xe22a,
  0xe0c4, 0xe3e7,
];

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class HabitFormScreen extends ConsumerStatefulWidget {
  final String? habitId;
  const HabitFormScreen({super.key, this.habitId});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _unitCtrl;

  int _iconCodePoint = _iconOptions.first;
  String _difficulty = 'medium';
  String _frequency = 'daily';
  Set<int> _customDays = {};
  String? _upgradeId;
  bool _saving = false;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
    _unitCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _initFromExisting(Habit habit) {
    if (_didInit) return;
    _didInit = true;
    _nameCtrl.text = habit.name;
    _descCtrl.text = habit.description;
    _iconCodePoint = habit.iconCodePoint;
    _difficulty = habit.difficulty;
    _frequency = habit.frequency;
    _upgradeId = habit.upgradeId;
    if (habit.targetValue != null) {
      _targetCtrl.text = habit.targetValue!.toStringAsFixed(
          habit.targetValue! == habit.targetValue!.roundToDouble() ? 0 : 1);
    }
    if (habit.unit != null) _unitCtrl.text = habit.unit!;
    if (habit.frequencyConfig != null) {
      _customDays = habit.frequencyConfig!
          .split(',')
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    }
  }

  bool get _isEditing => widget.habitId != null;

  int _resolveColor() {
    final upgrades = ref.read(upgradesProvider).valueOrNull ?? [];
    final upgrade = upgrades.where((u) => u.id == _upgradeId).firstOrNull;
    return upgrade?.color ?? 0xFF2383E2;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_upgradeId == null) return;
    setState(() => _saving = true);

    final existing = _isEditing
        ? ref
            .read(habitsProvider)
            .valueOrNull
            ?.firstWhere((h) => h.id == widget.habitId)
        : null;

    final targetVal = double.tryParse(_targetCtrl.text);
    final unit = _unitCtrl.text.trim().isNotEmpty ? _unitCtrl.text.trim() : null;
    final freqConfig = _frequency == 'custom' && _customDays.isNotEmpty
        ? _customDays.toList().map((d) => d.toString()).join(',')
        : null;

    final habit = Habit(
      id: existing?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      iconCodePoint: _iconCodePoint,
      color: _resolveColor(),
      upgradeId: _upgradeId!,
      frequency: _frequency,
      frequencyConfig: freqConfig,
      difficulty: _difficulty,
      targetValue: targetVal,
      unit: unit,
      currentStreak: existing?.currentStreak ?? 0,
      longestStreak: existing?.longestStreak ?? 0,
      createdAt: existing?.createdAt,
      archived: existing?.archived ?? false,
    );

    await ref.read(habitsProvider.notifier).save(habit);
    await ref.read(gamificationEngineProvider).addHabitToUpgrade(habit.id, habit.upgradeId);
    await ref.read(gamificationEngineProvider).checkHabitCreationAchievements();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isEditing) {
      final habits = ref.watch(habitsProvider).valueOrNull ?? [];
      final existing = habits.where((h) => h.id == widget.habitId).firstOrNull;
      if (existing != null) _initFromExisting(existing);
    }

    final upgrades = ref.watch(upgradesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
      ),
      body: upgrades.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogoIcon(
                        size: 48, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(height: 16),
                    Text(
                      'No upgrades yet',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every habit must belong to an upgrade.\nCreate an upgrade first to get started.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/upgrades/new'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Upgrade'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 24),

                  Text('Icon', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildIconPicker(),
                  const SizedBox(height: 24),

                  _buildDropdown(
                    label: 'Difficulty',
                    value: _difficulty,
                    items: AppConstants.difficulties,
                    onChanged: (v) => setState(() => _difficulty = v!),
                    colorMap: AppColors.difficultyColors,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    label: 'Frequency',
                    value: _frequency,
                    items: AppConstants.frequencies,
                    onChanged: (v) => setState(() {
                      _frequency = v!;
                      if (v != 'custom') _customDays.clear();
                    }),
                  ),

                  if (_frequency == 'custom') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        final selected = _customDays.contains(day);
                        return FilterChip(
                          label: Text(_weekdayLabels[i]),
                          selected: selected,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _customDays.add(day);
                              } else {
                                _customDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _targetCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Target Value'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _unitCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Unit', hintText: 'e.g. minutes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _upgradeId,
                    decoration: const InputDecoration(labelText: 'Upgrade *'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Upgrade is required' : null,
                    items: upgrades.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Row(
                            children: [
                              Icon(
                                IconData(u.iconCodePoint,
                                    fontFamily: 'MaterialIcons'),
                                size: 18,
                                color: Color(u.color),
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Text(u.name, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        )).toList(),
                    onChanged: (v) => setState(() => _upgradeId = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Create Habit'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIconPicker() {
    final accentColor = AppColors.blue;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _iconOptions.map((code) {
        final isSelected = code == _iconCodePoint;
        return GestureDetector(
          onTap: () => setState(() => _iconCodePoint = code),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: accentColor, width: 1.5)
                  : null,
            ),
            child: Icon(
              IconData(code, fontFamily: 'MaterialIcons'),
              color: isSelected
                  ? accentColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Map<String, Color>? colorMap,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        final display = item[0].toUpperCase() + item.substring(1);
        return DropdownMenuItem(
          value: item,
          child: Row(
            children: [
              if (colorMap != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorMap[item] ?? AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(display),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
