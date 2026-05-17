import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../data/providers.dart';
import 'widgets/upgrade_card.dart';

class UpgradesScreen extends ConsumerStatefulWidget {
  const UpgradesScreen({super.key});

  @override
  ConsumerState<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends ConsumerState<UpgradesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final upgradesAsync = ref.watch(upgradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.upgradesTab),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/upgrades/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newUpgrade),
      ),
      body: AsyncValueWidget(
        value: upgradesAsync,
        data: (upgrades) {
          final visible = upgrades.where((u) => !u.archived).toList()
            ..sort((a, b) {
              const order = {'active': 0, 'completed': 1, 'failed': 2};
              final cmp = (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
              if (cmp != 0) return cmp;
              return b.createdAt.compareTo(a.createdAt);
            });

          if (visible.isEmpty) {
            return const AppEmptyState(
              useAppLogo: true,
              title: AppStrings.noUpgradesTitle,
              subtitle: AppStrings.noUpgradesSubtitle,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final upgrade = visible[index];
              final score = ref.watch(liveUpgradeScoreProvider(upgrade.id));
              final memberships = ref.watch(upgradeHabitsForUpgradeProvider(upgrade.id));
              final activeCount = memberships.where((m) => m.leftDate == null).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: UpgradeCard(
                  upgrade: upgrade,
                  habitCount: activeCount,
                  liveScore: score,
                  onTap: () => context.go('/upgrades/${upgrade.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
