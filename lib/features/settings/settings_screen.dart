import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/card_shell.dart';
import '../../data/providers.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/entities/upgrade_group.dart';
import '../../domain/entities/upgrade_habit.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          CardShell(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Mode'),
              subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.blue,
              ),
              value: isDark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: 'Export'),
          const SizedBox(height: 8),
          CardShell(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.table_chart_outlined,
                  color: AppColors.blue),
              title: const Text('Export as Excel'),
              subtitle: const Text('Habits, entries, upgrades, memberships, and goals'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportExcel(context, ref),
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: 'Backup & Restore'),
          const SizedBox(height: 8),
          CardShell(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_rounded, color: AppColors.blue),
                  title: const Text('Backup progress'),
                  subtitle: const Text('Save profile, habits, upgrades, and all data to a file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _backupProgress(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore_rounded, color: AppColors.green),
                  title: const Text('Restore progress'),
                  subtitle: const Text('Load data from a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _restoreProgress(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: 'Data'),
          const SizedBox(height: 8),
          CardShell(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.delete_forever, color: AppColors.red),
              title: const Text('Reset All Data'),
              subtitle: const Text('Permanently delete everything'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirmReset(context, ref),
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          CardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogoIcon(size: 28, color: AppColors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          'v${AppConstants.appVersion}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Level up your life, one habit at a time.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Preparing export...'),
          duration: Duration(seconds: 1),
        ),
      );

      final habits = ref.read(habitsProvider).valueOrNull ?? <Habit>[];
      final entries =
          ref.read(habitEntriesProvider).valueOrNull ?? <HabitEntry>[];
      final upgrades =
          ref.read(upgradesProvider).valueOrNull ?? <UpgradeGroup>[];
      final upgradeHabits =
          ref.read(upgradeHabitsProvider).valueOrNull ?? <UpgradeHabit>[];
      final goals = ref.read(goalsProvider).valueOrNull ?? <Goal>[];

      final xl = Excel.createExcel();

      _addHabitsSheet(xl, habits);
      _addEntriesSheet(xl, entries);
      _addUpgradesSheet(xl, upgrades);
      _addUpgradeHabitsSheet(xl, upgradeHabits);
      _addGoalsSheet(xl, goals);

      xl.delete('Sheet1');

      final bytes = xl.save();
      if (bytes == null) throw Exception('Failed to generate Excel file');

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T').first;
      final filePath = '${dir.path}/upgrade_export_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(filePath)], text: 'UPGRADE Data Export');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _backupProgress(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Creating backup...'), duration: Duration(seconds: 1)),
      );
      final storage = await ref.read(localStorageProvider.future);
      final map = await storage.exportForBackup();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(map);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final path = '${dir.path}/upgrade_backup_$timestamp.json';
      await File(path).writeAsString(jsonStr);
      await Share.shareXFiles([XFile(path)], text: 'Upgrade progress backup');
      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Backup created')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _restoreProgress(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
      withReadStream: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file'), backgroundColor: AppColors.red),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will replace all your current data with the backup. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = await File(path).readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final storage = await ref.read(localStorageProvider.future);
      await storage.importFromBackup(map);
      ref.invalidate(habitsProvider);
      ref.invalidate(habitEntriesProvider);
      ref.invalidate(upgradesProvider);
      ref.invalidate(upgradeHabitsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(achievementsProvider);
      ref.invalidate(timelineProvider);
      ref.invalidate(userProfileProvider);
      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Restore complete')));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _addHabitsSheet(Excel xl, List<Habit> habits) {
    final sheet = xl['Habits'];
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Description'),
      TextCellValue('Frequency'),
      TextCellValue('Difficulty'),
      TextCellValue('Current Streak'),
      TextCellValue('Longest Streak'),
      TextCellValue('Target Value'),
      TextCellValue('Unit'),
      TextCellValue('Upgrade ID'),
      TextCellValue('Archived'),
      TextCellValue('Created At'),
    ]);
    for (final h in habits) {
      sheet.appendRow([
        TextCellValue(h.id),
        TextCellValue(h.name),
        TextCellValue(h.description),
        TextCellValue(h.frequency),
        TextCellValue(h.difficulty),
        IntCellValue(h.currentStreak),
        IntCellValue(h.longestStreak),
        DoubleCellValue(h.targetValue ?? 0),
        TextCellValue(h.unit ?? ''),
        TextCellValue(h.upgradeId),
        TextCellValue(h.archived ? 'Yes' : 'No'),
        TextCellValue(h.createdAt.toIso8601String()),
      ]);
    }
  }

  void _addEntriesSheet(Excel xl, List<HabitEntry> entries) {
    final sheet = xl['Entries'];
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Habit ID'),
      TextCellValue('Date'),
      TextCellValue('Value'),
      TextCellValue('Completed'),
      TextCellValue('Note'),
      TextCellValue('Mood'),
      TextCellValue('Timestamp'),
    ]);
    for (final e in entries) {
      sheet.appendRow([
        TextCellValue(e.id),
        TextCellValue(e.habitId),
        TextCellValue(e.date.toIso8601String()),
        DoubleCellValue(e.value),
        TextCellValue(e.completed ? 'Yes' : 'No'),
        TextCellValue(e.note ?? ''),
        IntCellValue(e.mood ?? 0),
        TextCellValue(e.timestamp.toIso8601String()),
      ]);
    }
  }

  void _addUpgradesSheet(Excel xl, List<UpgradeGroup> upgrades) {
    final sheet = xl['Upgrades'];
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Description'),
      TextCellValue('Difficulty'),
      TextCellValue('Start Date'),
      TextCellValue('End Date'),
      TextCellValue('Cutoff %'),
      TextCellValue('Status'),
      TextCellValue('Completion Score'),
      TextCellValue('XP Awarded'),
      TextCellValue('Archived'),
      TextCellValue('Created At'),
    ]);
    for (final u in upgrades) {
      sheet.appendRow([
        TextCellValue(u.id),
        TextCellValue(u.name),
        TextCellValue(u.description),
        TextCellValue(u.difficulty),
        TextCellValue(u.startDate.toIso8601String()),
        TextCellValue(u.endDate.toIso8601String()),
        DoubleCellValue(u.cutoffPercentage),
        TextCellValue(u.status),
        DoubleCellValue(u.completionScore ?? 0),
        IntCellValue(u.xpAwarded ?? 0),
        TextCellValue(u.archived ? 'Yes' : 'No'),
        TextCellValue(u.createdAt.toIso8601String()),
      ]);
    }
  }

  void _addUpgradeHabitsSheet(Excel xl, List<UpgradeHabit> memberships) {
    final sheet = xl['UpgradeHabits'];
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Upgrade ID'),
      TextCellValue('Habit ID'),
      TextCellValue('Joined Date'),
      TextCellValue('Left Date'),
    ]);
    for (final m in memberships) {
      sheet.appendRow([
        TextCellValue(m.id),
        TextCellValue(m.upgradeId),
        TextCellValue(m.habitId),
        TextCellValue(m.joinedDate.toIso8601String()),
        TextCellValue(m.leftDate?.toIso8601String() ?? ''),
      ]);
    }
  }

  void _addGoalsSheet(Excel xl, List<Goal> goals) {
    final sheet = xl['Goals'];
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Description'),
      TextCellValue('Outcome Description'),
      TextCellValue('Target Date'),
      TextCellValue('Linked Habit IDs'),
      TextCellValue('Linked Upgrade IDs'),
      TextCellValue('Status'),
      TextCellValue('Created At'),
    ]);
    for (final g in goals) {
      sheet.appendRow([
        TextCellValue(g.id),
        TextCellValue(g.name),
        TextCellValue(g.description),
        TextCellValue(g.outcomeDescription ?? ''),
        TextCellValue(g.targetDate?.toIso8601String() ?? ''),
        TextCellValue(g.linkedHabitIds.join(', ')),
        TextCellValue(g.linkedUpgradeIds.join(', ')),
        TextCellValue(g.status),
        TextCellValue(g.createdAt.toIso8601String()),
      ]);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your habits, entries, '
          'goals, upgrades, achievements, and timeline events. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final storage = await ref.read(localStorageProvider.future);
    await storage.deleteAll();

    ref.invalidate(habitsProvider);
    ref.invalidate(habitEntriesProvider);
    ref.invalidate(upgradesProvider);
    ref.invalidate(upgradeHabitsProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(timelineProvider);
    ref.invalidate(userProfileProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data has been reset')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
