import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/minimalist_avatar_display.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/upgrade_group.dart';
import '../../domain/entities/upgrade_habit.dart';
import '../../domain/entities/timeline_event.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 3 – Upgrade state
  final _upgradeNameController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _upgradeDurationController = TextEditingController(text: '30');
  String _upgradeDifficulty = 'medium';
  late DateTime _startDate = DateTime.now();
  late DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _cutoff = 0.7;
  int _upgradeColor = AppColors.upgradeColorOptions[5]; // blue default
  int _upgradeIcon = AppConstants.upgradeIconOptions.first; // fitness_center default

  @override
  void initState() {
    super.initState();
    _upgradeDurationController.addListener(_onDurationChanged);
  }

  void _onDurationChanged() {
    final days = int.tryParse(_upgradeDurationController.text) ?? 0;
    if (days > 0) {
      setState(() {
        _endDate = _startDate.add(Duration(days: days));
      });
    }
  }

  void _updateDurationFromDates() {
    final diff = _endDate.difference(_startDate).inDays;
    _upgradeDurationController.text = diff.toString();
  }

  // Page 4 – Habits state
  final List<_HabitDraft> _habits = [];

  // Page 5 – Profile state
  final _usernameController = TextEditingController();
  Map<String, int> _avatarData = UserProfile.randomAvatarData();
  String? _customAvatarPath;
  bool _isLaunching = false;

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;

      final storage = ref.read(localStorageProvider).valueOrNull;
      if (storage == null) return;
      await storage.importFromBackup(map);
      
      // Re-load all providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(upgradesProvider);
      ref.invalidate(habitsProvider);
      ref.invalidate(upgradeHabitsProvider);
      
      await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(upgradesProvider.future),
        ref.read(habitsProvider.future),
        ref.read(upgradeHabitsProvider.future),
      ]);

      if (mounted) context.go('/launch');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: result.files.single.path!,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: AppColors.darkBg,
              toolbarWidgetColor: AppColors.darkText,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final file = File(croppedFile.path);
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'pfp_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
          final savedImage = await file.copy(path.join(directory.path, fileName));
          
          setState(() {
            _customAvatarPath = savedImage.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _upgradeNameController.dispose();
    _outcomeController.dispose();
    _upgradeDurationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() => _goToPage(_currentPage + 1);

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.blue,
            surface: Theme.of(ctx).cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  static List<int> get _habitIconOptions => AppConstants.habitIconOptions;
  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _showAddHabitSheet() {
    final nameCtrl = TextEditingController();
    String difficulty = 'medium';
    String frequency = 'daily';
    int selectedIcon = AppConstants.habitIconOptions.first;
    Set<int> customDays = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final isValid = nameCtrl.text.trim().isNotEmpty;
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'New Habit',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Habit name',
                      hintText: 'e.g. Run 30 minutes',
                      prefixIcon: Icon(
                        IconData(selectedIcon, fontFamily: 'MaterialIcons'),
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Icon',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _habitIconOptions.map((code) {
                      final sel = code == selectedIcon;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedIcon = code),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: sel
                                ? AppColors.green.withValues(alpha: 0.2)
                                : theme.cardColor,
                            border: Border.all(
                              color: sel ? AppColors.green : theme.dividerColor,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            IconData(code, fontFamily: 'MaterialIcons'),
                            size: 18,
                            color: sel ? AppColors.green : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Difficulty',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.difficulties.map((d) {
                      final sel = d == difficulty;
                      final color =
                          AppColors.difficultyColors[d] ?? AppColors.blue;
                      return GestureDetector(
                        onTap: () => setSheetState(() => difficulty = d),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: sel
                                ? color.withValues(alpha: 0.2)
                                : theme.cardColor,
                            border: Border.all(
                              color: sel ? color : theme.dividerColor,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sel)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Icon(Icons.check_circle_rounded,
                                      size: 14, color: color),
                                ),
                              Text(
                                d[0].toUpperCase() + d.substring(1),
                                style: TextStyle(
                                  color: sel
                                      ? color
                                      : theme.textTheme.bodySmall?.color,
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Frequency',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.frequencies.map((f) {
                      final sel = f == frequency;
                      return GestureDetector(
                        onTap: () => setSheetState(() => frequency = f),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: sel
                                ? AppColors.blue.withValues(alpha: 0.15)
                                : theme.cardColor,
                            border: Border.all(
                              color: sel
                                  ? AppColors.blue
                                  : theme.dividerColor,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(
                              color: sel
                                  ? AppColors.blue
                                  : theme.textTheme.bodySmall?.color,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (frequency == 'custom') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        final sel = customDays.contains(day);
                        return FilterChip(
                          label: Text(_weekdayLabels[i],
                              style: TextStyle(fontSize: 12,
                                  color: sel ? AppColors.blue : theme.textTheme.bodySmall?.color)),
                          selected: sel,
                          onSelected: (v) => setSheetState(() {
                            if (v) { customDays.add(day); } else { customDays.remove(day); }
                          }),
                          selectedColor: AppColors.blue.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.blue,
                          side: BorderSide(color: sel ? AppColors.blue : theme.dividerColor),
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isValid
                          ? () {
                              String? freqConfig;
                              if (frequency == 'custom' && customDays.isNotEmpty) {
                                final sorted = customDays.toList()..sort();
                                freqConfig = sorted.join(',');
                              }
                              setState(() {
                                _habits.add(_HabitDraft(
                                  name: nameCtrl.text.trim(),
                                  difficulty: difficulty,
                                  frequency: frequency,
                                  frequencyConfig: freqConfig,
                                  iconCodePoint: selectedIcon,
                                ));
                              });
                              Navigator.pop(ctx);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: theme.dividerColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchApp() async {
    if (_usernameController.text.trim().isEmpty) return;
    setState(() => _isLaunching = true);

    try {
      final upgrade = UpgradeGroup(
        name: _upgradeNameController.text.trim(),
        difficulty: _upgradeDifficulty,
        startDate: _startDate,
        endDate: _endDate,
        cutoffPercentage: _cutoff,
        color: _upgradeColor,
        iconCodePoint: _upgradeIcon,
        outcomeDescription: _outcomeController.text.trim().isEmpty
            ? null
            : _outcomeController.text.trim(),
      );
      // Wait for upgrade to save
      await ref.read(upgradesProvider.notifier).save(upgrade);

      // CRITICAL: Ensure habits are saved BEFORE the profile is saved.
      // The router checks for hasProfileProvider to redirect away from onboarding.
      // If profile is saved first, the app might redirect before habits are saved.
      
      final List<Habit> habitsToSave = [];
      final List<UpgradeHabit> membershipsToSave = [];

      for (int i = 0; i < _habits.length; i++) {
        final draft = _habits[i];
        final habit = Habit(
          name: draft.name,
          upgradeId: upgrade.id,
          difficulty: draft.difficulty,
          frequency: draft.frequency,
          frequencyConfig: draft.frequencyConfig,
          iconCodePoint: draft.iconCodePoint,
          color: upgrade.color,
        );
        habitsToSave.add(habit);

        final membership = UpgradeHabit(
          upgradeId: upgrade.id,
          habitId: habit.id,
          joinedDate: DateTime.now(),
        );
        membershipsToSave.add(membership);
      }

      // Save all habits and memberships in batch
      await ref.read(habitsProvider.notifier).saveAll(habitsToSave);
      await ref.read(upgradeHabitsProvider.notifier).saveAll(membershipsToSave);

      final profile = UserProfile(
        username: _usernameController.text.trim(),
        avatarData: _avatarData,
        customAvatarPath: _customAvatarPath,
        avatarType: _customAvatarPath != null ? 'custom' : 'minimalist',
      );
      
      // Wait for profile to save - this is the signal to the router that onboarding is done
      await ref.read(userProfileProvider.notifier).save(profile);

      // Re-load all providers to ensure state is fresh
      ref.invalidate(userProfileProvider);
      ref.invalidate(upgradesProvider);
      ref.invalidate(habitsProvider);
      ref.invalidate(upgradeHabitsProvider);
      
      // Wait for futures to complete
      await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(upgradesProvider.future),
        ref.read(habitsProvider.future),
        ref.read(upgradeHabitsProvider.future),
      ]);

      // Trigger achievements for onboarding creation
      final engine = ref.read(gamificationEngineProvider);
      await engine.checkHabitCreationAchievements();
      await engine.checkUpgradeCreationAchievements();

      // Log onboarding XP gain
      await ref.read(timelineProvider.notifier).addEvent(TimelineEvent(
        type: 'onboarding_completion',
        title: 'Initial Level Up',
        description: 'Completed onboarding journey (+100 XP)',
      ));

      if (mounted) context.go('/launch');
    } catch (e) {
      if (mounted) {
        setState(() => _isLaunching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: _currentPage < 4 
                    ? const BouncingScrollPhysics() 
                    : const NeverScrollableScrollPhysics(),
                scrollDirection: _currentPage < 4 ? Axis.vertical : Axis.horizontal,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const _WelcomePage(),
                  _IntroPage(
                    onRestore: _restoreBackup,
                  ),
                  _CreateUpgradePage(
                    nameController: _upgradeNameController,
                    outcomeController: _outcomeController,
                    durationController: _upgradeDurationController,
                    difficulty: _upgradeDifficulty,
                    startDate: _startDate,
                    endDate: _endDate,
                    cutoff: _cutoff,
                    selectedColor: _upgradeColor,
                    selectedIcon: _upgradeIcon,
                    onDifficultyChanged: (v) =>
                        setState(() => _upgradeDifficulty = v),
                    onPickDate: ({required bool isStart}) async {
                      await _pickDate(isStart: isStart);
                      if (isStart) {
                        _onDurationChanged();
                      } else {
                        _updateDurationFromDates();
                      }
                    },
                    onDurationChanged: _onDurationChanged,
                    onCutoffChanged: (v) => setState(() => _cutoff = v),
                    onColorChanged: (v) => setState(() => _upgradeColor = v),
                    onIconChanged: (v) => setState(() => _upgradeIcon = v),
                    onNameChanged: () => setState(() {}),
                    onContinue: () {
                      HapticFeedback.mediumImpact();
                      if (_upgradeNameController.text.trim().isNotEmpty) {
                        _nextPage();
                      }
                    },
                  ),
                  _AddHabitsPage(
                    upgradeName: _upgradeNameController.text.trim(),
                    habits: _habits,
                    onAddHabit: () {
                      HapticFeedback.lightImpact();
                      _showAddHabitSheet();
                    },
                    onRemoveHabit: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _habits.removeAt(i));
                    },
                    onContinue: () {
                      HapticFeedback.mediumImpact();
                      if (_habits.isNotEmpty) _nextPage();
                    },
                  ),
                  _ProfilePage(
                    usernameController: _usernameController,
                    avatarData: _avatarData,
                    customAvatarPath: _customAvatarPath,
                    isLaunching: _isLaunching,
                    onAvatarRandomize: () =>
                        setState(() {
                          _avatarData = UserProfile.randomAvatarData();
                          _customAvatarPath = null;
                        }),
                    onPickCustomAvatar: _pickProfileImage,
                    onUsernameChanged: () => setState(() {}),
                    onLaunch: () {
                      HapticFeedback.heavyImpact();
                      _launchApp();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit draft model (before persistence)
// ---------------------------------------------------------------------------
class _HabitDraft {
  final String name;
  final String difficulty;
  final String frequency;
  final String? frequencyConfig;
  final int iconCodePoint;
  const _HabitDraft({
    required this.name,
    required this.difficulty,
    required this.frequency,
    this.frequencyConfig,
    this.iconCodePoint = 0xe571,
  });
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .slideX(begin: -0.12, curve: Curves.easeOutCubic),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ).animate().fadeIn(delay: 100.ms, duration: 200.ms),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Widget? iconWidget;
  final bool enabled;
  final bool loading;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    this.iconWidget,
    this.enabled = true,
    this.loading = false,
    this.color = AppColors.blue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Theme.of(context).dividerColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconWidget != null) ...[
                    iconWidget!,
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 – Welcome
// ---------------------------------------------------------------------------
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue,
            ),
            child: const Center(
              child: AppLogoIcon(size: 56),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.4, 0.4),
                  duration: 300.ms,
                  curve: Curves.easeOutCubic)
              .fadeIn(duration: 250.ms),
          const SizedBox(height: 44),
          Text(
            'UPGRADE',
            style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                  letterSpacing: 8,
                ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 300.ms)
              .slideY(begin: 0.3, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Text(
            'Turn your real goals into a system you can\ntrack, complete, and grow from.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.4,
                fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) - 1,
              ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 300.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
          const Spacer(flex: 3),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ShimmerArrowIndicator(),
              const SizedBox(height: 12),
              Text(
                 'SWIPE UP TO START',
                 style: const TextStyle(
                   color: AppColors.blue,
                   fontSize: 15,
                   fontWeight: FontWeight.w800,
                   letterSpacing: 2,
                 ),
               ),
            ],
          ).animate().fadeIn(delay: 450.ms, duration: 250.ms),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ShimmerArrowIndicator extends StatelessWidget {
  final bool isSubtle;
  const _ShimmerArrowIndicator({this.isSubtle = false});

  @override
  Widget build(BuildContext context) {
    final color = isSubtle 
        ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3) ?? AppColors.blue 
        : AppColors.blue;
    final size = isSubtle ? 32.0 : 44.0;
    final spacing = isSubtle ? 10.0 : 14.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < 4; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i * spacing),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: color.withValues(alpha: 1.0 - (i * 0.2)),
              size: size,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  delay: (i * 100).ms,
                  duration: isSubtle ? 2000.ms : 1500.ms,
                  color: Colors.white.withValues(alpha: isSubtle ? 0.2 : 0.4),
                )
                .slideY(
                  begin: 0.4,
                  end: -0.4,
                  duration: isSubtle ? 2000.ms : 1500.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 600.ms)
                .then(delay: 600.ms)
                .fadeOut(duration: 600.ms),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 – Choice Page (Backup vs New)
// ---------------------------------------------------------------------------
class _IntroPage extends StatelessWidget {
  final VoidCallback onRestore;

  const _IntroPage({
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'How UPGRADE\nWorks',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          _FeatureCard(
            icon: Icons.keyboard_double_arrow_up_rounded,
            iconColor: AppColors.blue,
            title: 'Define an Upgrade',
            description:
                'Pick a real goal. Fitness, learning, career\u2014anything you want to improve.',
            delay: 200.ms,
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.green,
            title: 'Build daily habits',
            description:
                'Break your goal into small, repeatable actions that compound over time.',
            delay: 400.ms,
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.stars_rounded,
            iconColor: AppColors.amber,
            title: 'Level up for real',
            description:
                'Complete upgrades to gain XP and level up. Your level = your real-life progress.',
            delay: 600.ms,
          ),
          const Spacer(),
          Center(
            child: const _ShimmerArrowIndicator(isSubtle: true),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
              label: const Text('Restore from JSON backup', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Duration delay;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay, duration: 400.ms).slideY(begin: 0.1);
  }
}

// ---------------------------------------------------------------------------
// Page 3 – Create First Upgrade
// ---------------------------------------------------------------------------
class _CreateUpgradePage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController outcomeController;
  final TextEditingController durationController;
  final String difficulty;
  final DateTime startDate;
  final DateTime endDate;
  final double cutoff;
  final int selectedColor;
  final int selectedIcon;
  final ValueChanged<String> onDifficultyChanged;
  final void Function({required bool isStart}) onPickDate;
  final VoidCallback onDurationChanged;
  final ValueChanged<double> onCutoffChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onIconChanged;
  final VoidCallback onNameChanged;
  final VoidCallback onContinue;

  static List<int> get _iconOptions => AppConstants.upgradeIconOptions;

  const _CreateUpgradePage({
    required this.nameController,
    required this.outcomeController,
    required this.durationController,
    required this.difficulty,
    required this.startDate,
    required this.endDate,
    required this.cutoff,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onDifficultyChanged,
    required this.onPickDate,
    required this.onDurationChanged,
    required this.onCutoffChanged,
    required this.onColorChanged,
    required this.onIconChanged,
    required this.onNameChanged,
    required this.onContinue,
  });

  static const _tiers = [
    ('easy', 'Minor', AppColors.green),
    ('medium', 'Moderate', AppColors.blue),
    ('hard', 'Major', AppColors.amber),
  ];

  String _fmt(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = nameController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            const _SectionTitle(
              title: 'Set your first goal',
              subtitle: 'Define your objective and timeline. This will be\nthe core of your growth journey.',
            ),
            const SizedBox(height: 28),

            TextField(
              controller: nameController,
              onChanged: (_) => onNameChanged(),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Upgrade name',
                hintText: 'e.g. Get Fit',
                prefixIcon: Icon(
                  IconData(selectedIcon, fontFamily: 'MaterialIcons'),
                  size: 22,
                  color: Color(selectedColor),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 250.ms),
            const SizedBox(height: 24),

            Text('Impact Level',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 180.ms, duration: 250.ms),
            const SizedBox(height: 8),
            Row(
              children: _tiers.map((t) {
                final sel = t.$1 == difficulty;
                final color = t.$3;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: t.$1 == 'hard' ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => onDifficultyChanged(t.$1),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: sel
                              ? color.withValues(alpha: 0.18)
                              : theme.cardColor,
                          border: Border.all(
                            color: sel ? color : theme.dividerColor,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.$2,
                          style: TextStyle(
                            color: sel
                                ? color
                                : theme.textTheme.bodySmall?.color,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms, duration: 250.ms),
            const SizedBox(height: 24),

            Text('Duration',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 230.ms, duration: 250.ms),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Days:', style: TextStyle(fontSize: 14)),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (_) => onDurationChanged(),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 240.ms, duration: 250.ms),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'Start',
                    value: _fmt(startDate),
                    onTap: () => onPickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateChip(
                    label: 'End',
                    value: _fmt(endDate),
                    onTap: () => onPickDate(isStart: false),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 260.ms, duration: 250.ms),
            const SizedBox(height: 24),

            Text('Completion Threshold',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 290.ms, duration: 250.ms),
            const SizedBox(height: 4),
            Text(
              'Minimum % of habits you need to complete for this upgrade to count as passed. Lower it for more flexibility.',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 295.ms, duration: 200.ms),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.blue,
                      inactiveTrackColor:
                          AppColors.blue.withValues(alpha: 0.15),
                      thumbColor: AppColors.blue,
                      overlayColor: AppColors.blue.withValues(alpha: 0.12),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: cutoff,
                      min: 0.5,
                      max: 1.0,
                      divisions: 10,
                      onChanged: onCutoffChanged,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(cutoff * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 320.ms, duration: 250.ms),
            const SizedBox(height: 16),

            TextField(
              controller: outcomeController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Outcome (optional)',
                hintText: 'e.g. Be healthier and more energetic',
                prefixIcon:
                    Icon(Icons.emoji_events_rounded, color: AppColors.amber),
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 250.ms),
            const SizedBox(height: 24),

            Text('Color',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 360.ms, duration: 250.ms),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.upgradeColorOptions.map((c) {
                final sel = c == selectedColor;
                return GestureDetector(
                  onTap: () => onColorChanged(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c),
                      border: sel
                          ? Border.all(color: theme.textTheme.bodyLarge?.color ?? Colors.white, width: 2.5)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 370.ms, duration: 250.ms),
            const SizedBox(height: 20),

            Text('Icon',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 375.ms, duration: 250.ms),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _iconOptions.map((code) {
                final sel = code == selectedIcon;
                return GestureDetector(
                  onTap: () => onIconChanged(code),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: sel
                          ? Color(selectedColor).withValues(alpha: 0.15)
                          : theme.dividerColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: sel ? Color(selectedColor) : theme.dividerColor.withValues(alpha: 0.3),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      IconData(code, fontFamily: 'MaterialIcons'),
                      size: 20,
                      color: sel ? Color(selectedColor) : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 385.ms, duration: 250.ms),
            const SizedBox(height: 32),

            _PrimaryButton(
              label: 'Continue',
              enabled: isValid,
              onPressed: onContinue,
            ).animate().fadeIn(delay: 380.ms, duration: 250.ms),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateChip(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: theme.textTheme.bodySmall?.color, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.blue),
                const SizedBox(width: 6),
                Text(value,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4 – Add Habits
// ---------------------------------------------------------------------------
class _AddHabitsPage extends StatelessWidget {
  final String upgradeName;
  final List<_HabitDraft> habits;
  final VoidCallback onAddHabit;
  final ValueChanged<int> onRemoveHabit;
  final VoidCallback onContinue;

  const _AddHabitsPage({
    required this.upgradeName,
    required this.habits,
    required this.onAddHabit,
    required this.onRemoveHabit,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHabits = habits.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          _SectionTitle(
            title: 'What will get you there?',
            subtitle: 'Add the daily or weekly habits that will drive \u2018${upgradeName.isEmpty ? "your Upgrade" : upgradeName}\u2019 forward.',
          ),
          const SizedBox(height: 24),

          Expanded(
            child: hasHabits
                ? ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (ctx, i) {
                      final h = habits[i];
                      final color = AppColors.difficultyColors[h.difficulty] ??
                          AppColors.blue;
                      return Dismissible(
                        key: ValueKey('${h.name}_$i'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => onRemoveHabit(i),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.red),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CardShell(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withValues(alpha: 0.15),
                                  ),
                                  child: Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: color,
                                      size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(h.name,
                                          style: TextStyle(
                                            color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${h.difficulty[0].toUpperCase()}${h.difficulty.substring(1)} · ${h.frequency[0].toUpperCase()}${h.frequency.substring(1)}',
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.swipe_left_rounded,
                                    size: 16,
                                    color: Theme.of(context).textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOutCubic);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_task_rounded,
                            size: 56,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No habits yet',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('Tap the button below to add one',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                              fontSize: 13,
                            )),
                      ],
                    ).animate().fadeIn(duration: 250.ms),
                  ),
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Habit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Continue',
            enabled: hasHabits,
            onPressed: onContinue,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 5 – Profile Setup
// ---------------------------------------------------------------------------
class _ProfilePage extends StatelessWidget {
  final TextEditingController usernameController;
  final Map<String, int> avatarData;
  final String? customAvatarPath;
  final bool isLaunching;
  final VoidCallback onAvatarRandomize;
  final VoidCallback onPickCustomAvatar;
  final VoidCallback onUsernameChanged;
  final VoidCallback onLaunch;

  const _ProfilePage({
    required this.usernameController,
    required this.avatarData,
    this.customAvatarPath,
    required this.isLaunching,
    required this.onAvatarRandomize,
    required this.onPickCustomAvatar,
    required this.onUsernameChanged,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = usernameController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            const _SectionTitle(
              title: 'One last thing',
              subtitle: 'Choose your identity. This is who you\u2019re becoming.',
            ),
            const SizedBox(height: 32),
            TextField(
              controller: usernameController,
              onChanged: (_) => onUsernameChanged(),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.blue),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 250.ms),
            const SizedBox(height: 32),
            Text(
              'Your avatar',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ).animate().fadeIn(delay: 200.ms, duration: 250.ms),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: customAvatarPath != null
                        ? Image.file(
                            File(customAvatarPath!),
                            fit: BoxFit.cover,
                          )
                        : MinimalistAvatarDisplay(
                            avatarData: avatarData,
                            size: 120,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: onAvatarRandomize,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Randomize'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onPickCustomAvatar,
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Upload'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 250.ms),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: 'Launch UPGRADE',
              iconWidget: const AppLogoIcon(size: 20),
              enabled: isValid,
              loading: isLaunching,
              color: AppColors.blue,
              onPressed: onLaunch,
            ).animate().fadeIn(delay: 300.ms, duration: 250.ms),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
