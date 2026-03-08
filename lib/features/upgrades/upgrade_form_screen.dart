import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/utils/gamification_engine.dart';
import '../../data/providers.dart';
import '../../domain/entities/upgrade_group.dart';

class UpgradeFormScreen extends ConsumerStatefulWidget {
  final String? upgradeId;

  const UpgradeFormScreen({super.key, this.upgradeId});

  @override
  ConsumerState<UpgradeFormScreen> createState() => _UpgradeFormScreenState();
}

class _UpgradeFormScreenState extends ConsumerState<UpgradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _outcomeCtrl;

  int _selectedIconCodePoint = 0xe5d8;
  int _selectedColor = AppColors.upgradeColorOptions[5];
  String _difficulty = 'medium';
  late DateTime _startDate;
  late DateTime _endDate;
  double _cutoffPercentage = 0.7;
  bool _saving = false;

  bool get _isEditing => widget.upgradeId != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _outcomeCtrl = TextEditingController();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 30));

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final upgrades = ref.read(upgradesProvider).valueOrNull ?? [];
    final existing =
        upgrades.where((u) => u.id == widget.upgradeId).firstOrNull;
    if (existing == null) return;

    _nameCtrl.text = existing.name;
    _descCtrl.text = existing.description;
    _outcomeCtrl.text = existing.outcomeDescription ?? '';
    setState(() {
      _selectedIconCodePoint = existing.iconCodePoint;
      _selectedColor = existing.color;
      _difficulty = existing.difficulty;
      _startDate = existing.startDate;
      _endDate = existing.endDate;
      _cutoffPercentage = existing.cutoffPercentage;
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
        final upgrades = ref.read(upgradesProvider).valueOrNull ?? [];
        final existing =
            upgrades.where((u) => u.id == widget.upgradeId).firstOrNull;
        if (existing != null) {
          await ref.read(upgradesProvider.notifier).save(
                existing.copyWith(
                  name: _nameCtrl.text.trim(),
                  description: _descCtrl.text.trim(),
                  outcomeDescription: _outcomeCtrl.text.trim().isEmpty
                      ? null
                      : _outcomeCtrl.text.trim(),
                  iconCodePoint: _selectedIconCodePoint,
                  color: _selectedColor,
                  difficulty: _difficulty,
                  startDate: _startDate,
                  endDate: _endDate,
                  cutoffPercentage: _cutoffPercentage,
                ),
              );
        }
      } else {
        await ref.read(upgradesProvider.notifier).save(
              UpgradeGroup(
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                outcomeDescription: _outcomeCtrl.text.trim().isEmpty
                    ? null
                    : _outcomeCtrl.text.trim(),
                iconCodePoint: _selectedIconCodePoint,
                color: _selectedColor,
                difficulty: _difficulty,
                startDate: _startDate,
                endDate: _endDate,
                cutoffPercentage: _cutoffPercentage,
              ),
            );
      }

      await ref
          .read(gamificationEngineProvider)
          .checkUpgradeCreationAchievements();
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color get _difficultyColor {
    switch (_difficulty) {
      case 'easy':
        return AppColors.green;
      case 'hard':
        return AppColors.amber;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Upgrade' : 'New Upgrade'),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. Physical Fitness',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What is this upgrade about?',
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
                hintText: 'What does achieving this mean to you?',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),

            const SizedBox(height: 24),
            Text('Impact Level', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDifficultyChip('easy', AppConstants.upgradeImpactLabels['easy']!, AppColors.green),
                const SizedBox(width: 8),
                _buildDifficultyChip('medium', AppConstants.upgradeImpactLabels['medium']!, AppColors.blue),
                const SizedBox(width: 8),
                _buildDifficultyChip('hard', AppConstants.upgradeImpactLabels['hard']!, AppColors.amber),
              ],
            ),

            const SizedBox(height: 24),
            Text('Date Range', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CardShell(
                    onTap: _pickStartDate,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start', style: theme.textTheme.bodySmall),
                            Text(_formatDate(_startDate),
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CardShell(
                    onTap: _pickEndDate,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 16, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End', style: theme.textTheme.bodySmall),
                            Text(_formatDate(_endDate),
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_endDate.difference(_startDate).inDays} days',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cutoff Percentage', style: theme.textTheme.titleMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(_cutoffPercentage * 100).round()}%',
                    style: TextStyle(
                      color: _difficultyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _cutoffPercentage,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              label: '${(_cutoffPercentage * 100).round()}%',
              onChanged: (v) => setState(() => _cutoffPercentage = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50%', style: theme.textTheme.bodySmall),
                Text('100%', style: theme.textTheme.bodySmall),
              ],
            ),

            const SizedBox(height: 24),
            Text('Icon', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _IconGrid(
              selected: _selectedIconCodePoint,
              accentColor: Color(_selectedColor),
              onSelect: (code) =>
                  setState(() => _selectedIconCodePoint = code),
            ),
            const SizedBox(height: 24),
            Text('Color', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ColorRow(
              selected: _selectedColor,
              onSelect: (c) => setState(() => _selectedColor = c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label, Color color) {
    final selected = _difficulty == value;
    return Expanded(
      child: ChoiceChip(
        label: SizedBox(
          width: double.infinity,
          child: Text(label, textAlign: TextAlign.center),
        ),
        selected: selected,
        onSelected: (_) => setState(() => _difficulty = value),
        selectedColor: color.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: selected ? color : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide(
          color: selected ? color : Theme.of(context).dividerColor,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final int selected;
  final Color accentColor;
  final ValueChanged<int> onSelect;

  const _IconGrid({
    required this.selected,
    required this.accentColor,
    required this.onSelect,
  });

  static const List<int> _icons = [
    0xe5d8, 0xe87c, 0xef3d, 0xe80e,
    0xe865, 0xe8e8, 0xe838, 0xea65,
    0xef63, 0xe559, 0xe3e7, 0xe52f,
    0xe25b, 0xef76, 0xe0af, 0xe7fd,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _icons.map((code) {
        final isSelected = code == selected;
        return GestureDetector(
          onTap: () => onSelect(code),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: accentColor, width: 1.5)
                  : null,
            ),
            child: Icon(
              IconData(code, fontFamily: 'MaterialIcons'),
              color: isSelected ? accentColor : Theme.of(context).textTheme.bodyMedium?.color,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _ColorRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppColors.upgradeColorOptions.map((c) {
          final isSelected = c == selected;
          final color = Color(c);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: isDark ? Colors.white : AppColors.lightText,
                          width: 2.5)
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        color: isDark ? Colors.white : Colors.white, size: 18)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
