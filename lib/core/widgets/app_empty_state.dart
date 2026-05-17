import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_logo_icon.dart';
import '../theme/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool useAppLogo;

  const AppEmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    this.action,
    this.useAppLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useAppLogo)
              AppLogoIcon(
                size: 64,
                color: AppColors.blue.withValues(alpha: 0.5),
              )
            else if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              Icon(
                icon,
                size: 64,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic);
  }
}
