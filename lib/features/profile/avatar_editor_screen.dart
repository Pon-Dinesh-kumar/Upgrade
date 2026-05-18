import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/minimalist_avatar_display.dart';
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

  void _save() {
    final updatedProfile = widget.profile.copyWith(
      avatarData: Map<String, int>.from(_avatarData),
      avatarType: 'minimalist',
    );
    Navigator.of(context).pop(updatedProfile);
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
        title: const Text('Customize Minimalist Avatar'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fixed Preview Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Center(
              child: Column(
                children: [
                  MinimalistAvatarDisplay(
                    avatarData: _avatarData,
                    size: 160,
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

          // Scrollable Customization Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Customize',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...partOrder.map((part) {
                  final max = ranges[part] ?? 1;
                  final label = AppConstants.avatarPartLabels[part] ?? part;
                  return _buildSlider(label, part, max);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, String key, int max) {
    final theme = Theme.of(context);
    final value = _avatarData[key] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardShell(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
              Text(
                '${value + 1} / $max',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
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
                _avatarData[key] = v.round();
              });},
             ),
           ],
         ),
       ),
     );
   }
 }