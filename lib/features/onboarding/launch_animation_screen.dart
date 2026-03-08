import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';

class LaunchAnimationScreen extends StatefulWidget {
  const LaunchAnimationScreen({super.key});

  @override
  State<LaunchAnimationScreen> createState() => _LaunchAnimationScreenState();
}

class _LaunchAnimationScreenState extends State<LaunchAnimationScreen>
    with TickerProviderStateMixin {
  int _completedTasks = 0;
  double _xpProgress = 0.0;
  bool _showLevelUp = false;
  bool _canProceed = false;

  static const _tasks = [
    (icon: Icons.download_rounded, useAppLogo: false, label: 'Install UPGRADE'),
    (icon: Icons.rocket_launch_rounded, useAppLogo: true, label: 'Create your first upgrade'),
    (icon: Icons.check_circle_rounded, useAppLogo: false, label: 'Create your first habit'),
  ];

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(800.ms);

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await Future.delayed(900.ms);
      setState(() {
        _completedTasks = i + 1;
        _xpProgress = (_completedTasks / 3).clamp(0.0, 1.0);
      });
      HapticFeedback.lightImpact();
    }

    await Future.delayed(600.ms);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _showLevelUp = true);

    await Future.delayed(1200.ms);
    if (!mounted) return;
    setState(() => _canProceed = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Text(
                _showLevelUp ? 'Level 1' : 'Level 0',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _showLevelUp ? AppColors.green : theme.textTheme.bodySmall?.color,
                  fontSize: _showLevelUp ? 48 : 40,
                ),
              ).animate(target: _showLevelUp ? 1 : 0).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 8),

              if (!_showLevelUp)
                Text(
                  'Starting your journey...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ).animate().fadeIn(duration: 300.ms)
              else
                Text(
                  'Welcome, ${_canProceed ? "let\u2019s go!" : "Novice"}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 32),

              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: theme.dividerColor,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * _xpProgress,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _showLevelUp ? AppColors.green : AppColors.blue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_xpProgress * 100).round()} / 100 XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 40),

              ...List.generate(3, (i) {
                final task = _tasks[i];
                final done = i < _completedTasks;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: 300.ms,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? AppColors.green.withValues(alpha: 0.15)
                              : theme.dividerColor.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  size: 20, color: AppColors.green)
                              : task.useAppLogo
                                  ? AppLogoIcon(
                                      size: 18,
                                      color: theme.textTheme.bodySmall?.color,
                                    )
                                  : Icon(task.icon,
                                      size: 18,
                                      color: theme.textTheme.bodySmall?.color),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          task.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                            color: done
                                ? theme.textTheme.bodyLarge?.color
                                : theme.textTheme.bodySmall?.color,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.green,
                          ),
                        ),
                      ),
                      if (done)
                        Text('+33 XP',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            )),
                    ],
                  ),
                )
                    .animate(target: done ? 1 : 0)
                    .fadeIn(duration: 250.ms);
              }),

              const Spacer(flex: 3),

              if (_canProceed)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start Your Journey',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(
                    begin: 0.2, curve: Curves.easeOutCubic),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
