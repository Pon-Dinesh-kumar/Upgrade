import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';

class UpgradeAIScreen extends StatelessWidget {
  const UpgradeAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade AI')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  size: 40,
                  color: AppColors.blue.withValues(alpha: 0.8),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              Text(
                'Upgrade AI',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: 8),
              Text(
                'Your AI accountability partner',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: 32),
              CardShell(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: AppColors.amber.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We're building something special",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'An AI coach that keeps you accountable and helps you stay on track with your upgrades. Stay tuned.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 300.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              Text(
                'Coming soon',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}
