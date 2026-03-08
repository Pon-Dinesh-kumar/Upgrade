import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/notion_avatar_display.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/upgrade_group.dart';
import '../../domain/entities/upgrade_habit.dart';

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
  String _upgradeDifficulty = 'medium';
  late DateTime _startDate = DateTime.now();
  late DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  double _cutoff = 0.7;
  int _upgradeColor = AppColors.upgradeColorOptions[5]; // blue default
  int _upgradeIcon = 0xe5d8; // upgrade icon default

  // Page 4 – Habits state
  final List<_HabitDraft> _habits = [];

  // Page 5 – Profile state
  final _usernameController = TextEditingController();
  Map<String, int> _avatarData = UserProfile.randomAvatarData();
  bool _isLaunching = false;

  @override
  void dispose() {
    _pageController.dispose();
    _upgradeNameController.dispose();
    _outcomeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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

  static const _habitIconOptions = [
    0xe571, 0xe0f7, 0xf06bb, 0xe25a, 0xe3aa, 0xe332,
    0xe52f, 0xe534, 0xe310, 0xe539, 0xe559, 0xe491,
  ];
  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _showAddHabitSheet() {
    final nameCtrl = TextEditingController();
    String difficulty = 'medium';
    String frequency = 'daily';
    int selectedIcon = 0xe571;
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
                    decoration: const InputDecoration(
                      labelText: 'Habit name',
                      hintText: 'e.g. Run 30 minutes',
                      prefixIcon:
                          Icon(Icons.flag_rounded, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Icon',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _habitIconOptions.map((code) {
                      final sel = code == selectedIcon;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedIcon = code),
                        child: Container(
                          width: 38,
                          height: 38,
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
      final profile = UserProfile(
        username: _usernameController.text.trim(),
        avatarData: _avatarData,
      );
      await ref.read(userProfileProvider.notifier).save(profile);

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
      await ref.read(upgradesProvider.notifier).save(upgrade);

      for (final draft in _habits) {
        final habit = Habit(
          name: draft.name,
          upgradeId: upgrade.id,
          difficulty: draft.difficulty,
          frequency: draft.frequency,
          frequencyConfig: draft.frequencyConfig,
          iconCodePoint: draft.iconCodePoint,
        );
        await ref.read(habitsProvider.notifier).save(habit);

        final membership = UpgradeHabit(
          upgradeId: upgrade.id,
          habitId: habit.id,
          joinedDate: DateTime.now(),
        );
        await ref.read(upgradeHabitsProvider.notifier).save(membership);
      }

      if (mounted) context.go('/launch');
    } catch (_) {
      if (mounted) setState(() => _isLaunching = false);
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onGetStarted: _nextPage),
                  _HowItWorksPage(onNext: _nextPage),
                  _CreateUpgradePage(
                    nameController: _upgradeNameController,
                    outcomeController: _outcomeController,
                    difficulty: _upgradeDifficulty,
                    startDate: _startDate,
                    endDate: _endDate,
                    cutoff: _cutoff,
                    selectedColor: _upgradeColor,
                    selectedIcon: _upgradeIcon,
                    onDifficultyChanged: (v) =>
                        setState(() => _upgradeDifficulty = v),
                    onPickDate: _pickDate,
                    onCutoffChanged: (v) => setState(() => _cutoff = v),
                    onColorChanged: (v) => setState(() => _upgradeColor = v),
                    onIconChanged: (v) => setState(() => _upgradeIcon = v),
                    onNameChanged: () => setState(() {}),
                    onContinue: () {
                      if (_upgradeNameController.text.trim().isNotEmpty) {
                        _nextPage();
                      }
                    },
                  ),
                  _AddHabitsPage(
                    upgradeName: _upgradeNameController.text.trim(),
                    habits: _habits,
                    onAddHabit: _showAddHabitSheet,
                    onRemoveHabit: (i) => setState(() => _habits.removeAt(i)),
                    onContinue: () {
                      if (_habits.isNotEmpty) _nextPage();
                    },
                  ),
                  _ProfilePage(
                    usernameController: _usernameController,
                    avatarData: _avatarData,
                    isLaunching: _isLaunching,
                    onAvatarRandomize: () =>
                        setState(() => _avatarData = UserProfile.randomAvatarData()),
                    onUsernameChanged: () => setState(() {}),
                    onLaunch: _launchApp,
                  ),
                ],
              ),
            ),
            _PageIndicator(currentPage: _currentPage, pageCount: 5),
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
  final IconData? icon;
  final Widget? iconWidget;
  final bool enabled;
  final bool loading;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    this.icon,
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
                  ] else if (icon != null) ...[
                    Icon(icon, size: 20),
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
  final VoidCallback onGetStarted;
  const _WelcomePage({required this.onGetStarted});

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
                color: theme.textTheme.bodySmall?.color, height: 1.5),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 300.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
          const Spacer(flex: 3),
          _PrimaryButton(label: 'Get Started', onPressed: onGetStarted)
              .animate()
              .fadeIn(delay: 450.ms, duration: 250.ms)
              .slideY(begin: 0.4, curve: Curves.easeOutCubic),
          const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 – How It Works
// ---------------------------------------------------------------------------
class _HowItWorksPage extends StatelessWidget {
  final VoidCallback onNext;
  const _HowItWorksPage({required this.onNext});

  static const _steps = [
    (
      icon: Icons.rocket_launch_rounded,
      color: AppColors.blue,
      useAppLogo: true,
      title: 'Define an Upgrade',
      body: 'Pick a real goal. Fitness, learning, career\u2014anything you want to improve.',
    ),
    (
      icon: Icons.check_circle_rounded,
      color: AppColors.green,
      useAppLogo: false,
      title: 'Build daily habits',
      body: 'Break your goal into small, repeatable actions that compound over time.',
    ),
    (
      icon: Icons.star_rounded,
      color: AppColors.amber,
      useAppLogo: false,
      title: 'Level up for real',
      body: 'Complete upgrades to gain XP and level up.\nYour level = your real-life progress.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          const _SectionTitle(title: 'How UPGRADE\nWorks'),
          const SizedBox(height: 32),
          ...List.generate(_steps.length, (i) {
            final s = _steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CardShell(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: s.useAppLogo
                            ? AppLogoIcon(size: 24, color: s.color)
                            : Icon(s.icon, color: s.color, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: TextStyle(
                                color: s.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              )),
                          const SizedBox(height: 4),
                          Text(s.body,
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 13,
                                height: 1.4,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (100 + i * 120).ms, duration: 250.ms)
                .slideX(begin: 0.08, curve: Curves.easeOutCubic);
          }),
          const Spacer(),
          _PrimaryButton(label: 'Next', onPressed: onNext)
              .animate()
              .fadeIn(delay: 500.ms, duration: 250.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 – Create First Upgrade
// ---------------------------------------------------------------------------
class _CreateUpgradePage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController outcomeController;
  final String difficulty;
  final DateTime startDate;
  final DateTime endDate;
  final double cutoff;
  final int selectedColor;
  final int selectedIcon;
  final ValueChanged<String> onDifficultyChanged;
  final void Function({required bool isStart}) onPickDate;
  final ValueChanged<double> onCutoffChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onIconChanged;
  final VoidCallback onNameChanged;
  final VoidCallback onContinue;

  static const _iconOptions = [
    0xe5d8, 0xe571, 0xe0f7, 0xf06bb, 0xe25a, 0xe3aa,
    0xe332, 0xe52f, 0xe534, 0xe310, 0xe539, 0xe491,
  ];

  const _CreateUpgradePage({
    required this.nameController,
    required this.outcomeController,
    required this.difficulty,
    required this.startDate,
    required this.endDate,
    required this.cutoff,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onDifficultyChanged,
    required this.onPickDate,
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
              subtitle: 'An Upgrade is a meaningful goal with a timeline. You\u2019ll build habits to power it.',
            ),
            const SizedBox(height: 28),

            TextField(
              controller: nameController,
              onChanged: (_) => onNameChanged(),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Upgrade name',
                hintText: 'e.g. Get Fit',
                prefixIcon: AppLogoIcon(size: 22, color: AppColors.blue),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((code) {
                final sel = code == selectedIcon;
                return GestureDetector(
                  onTap: () => onIconChanged(code),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: sel
                          ? Color(selectedColor).withValues(alpha: 0.2)
                          : theme.cardColor,
                      border: Border.all(
                        color: sel ? Color(selectedColor) : theme.dividerColor,
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
            ).animate().fadeIn(delay: 380.ms, duration: 250.ms),
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
  final bool isLaunching;
  final VoidCallback onAvatarRandomize;
  final VoidCallback onUsernameChanged;
  final VoidCallback onLaunch;

  const _ProfilePage({
    required this.usernameController,
    required this.avatarData,
    required this.isLaunching,
    required this.onAvatarRandomize,
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
                    child: NotionAvatarDisplay(
                      avatarData: avatarData,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onAvatarRandomize,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Randomize'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                    ),
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

// ---------------------------------------------------------------------------
// Page Indicator Dots
// ---------------------------------------------------------------------------
class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  const _PageIndicator({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppColors.blue : Theme.of(context).dividerColor,
          ),
        );
      }),
    );
  }
}
