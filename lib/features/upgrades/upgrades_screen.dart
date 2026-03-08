import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo_icon.dart';
import '../../data/providers.dart';
import 'widgets/upgrade_card.dart';

class UpgradesScreen extends ConsumerWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradesAsync = ref.watch(upgradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrades'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/upgrades/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Upgrade'),
      ),
      body: upgradesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text('Failed to load upgrades',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.read(upgradesProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (upgrades) {
          final visible = upgrades.where((u) => !u.archived).toList()
            ..sort((a, b) {
              const order = {'active': 0, 'completed': 1, 'failed': 2};
              final cmp = (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
              if (cmp != 0) return cmp;
              return b.createdAt.compareTo(a.createdAt);
            });

          if (visible.isEmpty) return const _EmptyState();

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final upgrade = visible[index];
                  final score = ref.watch(liveUpgradeScoreProvider(upgrade.id));
                  final memberships = ref.watch(upgradeHabitsForUpgradeProvider(upgrade.id));
                  final activeCount = memberships.where((m) => m.leftDate == null).length;

                  return UpgradeCard(
                    upgrade: upgrade,
                    habitCount: activeCount,
                    liveScore: score,
                    onTap: () => context.go('/upgrades/${upgrade.id}'),
                  )
                      .animate()
                      .fadeIn(
                        duration: 250.ms,
                        delay: (50 * index).ms,
                      )
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 250.ms,
                        delay: (50 * index).ms,
                        curve: Curves.easeOutCubic,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogoIcon(
              size: 80,
              color: AppColors.blue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No upgrades yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create an upgrade to group your habits and\ntrack progress toward a bigger goal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 250.ms, curve: Curves.easeOutCubic);
  }
}
