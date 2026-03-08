import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/notion_avatar_display.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/constants/app_constants.dart';

class AvatarEditorScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const AvatarEditorScreen({super.key, required this.profile});

  @override
  ConsumerState<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> {
  late Map<String, int> _avatarData;

  @override
  void initState() {
    super.initState();
    _avatarData = Map.from(widget.profile.avatarData);
  }

  void _randomize() {
    setState(() {
      _avatarData = UserProfile.randomAvatarData();
    });
  }

  Future<void> _save() async {
    await ref.read(userProfileProvider.notifier).save(
          widget.profile.copyWith(avatarData: Map<String, int>.from(_avatarData)),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranges = UserProfile.avatarPartRanges;
    final partOrder = AppConstants.avatarParts
        .where((p) => ranges.containsKey(p))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change avatar'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CardShell(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  NotionAvatarDisplay(
                    avatarData: _avatarData,
                    size: 120,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _randomize,
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text('Randomize'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Customize',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...partOrder.map((part) {
            final max = ranges[part] ?? 1;
            final value = _avatarData[part] ?? 0;
            final label = AppConstants.avatarPartLabels[part] ?? part;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardShell(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: theme.textTheme.bodyMedium),
                        Text(
                          '${value + 1} / $max',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: (max - 1).toDouble(),
                      divisions: max > 1 ? max - 1 : 1,
                      onChanged: (v) {
                        setState(() {
                          _avatarData = Map.from(_avatarData);
                          _avatarData[part] = v.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
