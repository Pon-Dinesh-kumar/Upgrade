import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/profile_copy.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/user_profile.dart';

class LifeImpactCard extends ConsumerWidget {
  final UserProfile profile;

  const LifeImpactCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(habitEntriesProvider).valueOrNull ?? [];
    final daysShowedUp = entries.where((e) => e.completed).length;
    final activeCount = ref.watch(activeUpgradesProvider).length;
    final rankLine = ProfileCopy.rankMessage(profile.rank);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.lifeImpact,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ImpactMetric(
                  value: '$daysShowedUp',
                  label: AppStrings.daysShowedUp,
                ),
              ),
              Expanded(
                child: _ImpactMetric(
                  value: '${profile.currentStreak}',
                  label: AppStrings.dayRhythm,
                ),
              ),
              Expanded(
                child: _ImpactMetric(
                  value: '$activeCount',
                  label: AppStrings.activeUpgradesCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Level ${profile.level} · ${profile.rank}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rankLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ImpactMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
