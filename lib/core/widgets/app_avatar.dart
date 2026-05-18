import 'dart:io';
import 'package:flutter/material.dart';
import 'minimalist_avatar_display.dart';
import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final Map<String, int>? avatarData;
  final String? customAvatarPath;
  final String avatarType; // 'minimalist' or 'custom'
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const AppAvatar({
    super.key,
    this.avatarData,
    this.customAvatarPath,
    this.avatarType = 'minimalist',
    this.size = 40,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget avatarChild;
    if (avatarType == 'custom' && customAvatarPath != null && customAvatarPath!.isNotEmpty) {
      avatarChild = Image.file(
        File(customAvatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (avatarData != null) {
      avatarChild = MinimalistAvatarDisplay(
        avatarData: avatarData!,
        size: size,
      );
    } else {
      avatarChild = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.dividerColor.withValues(alpha: 0.1),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarChild,
          ),
          if (showEditIcon)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.1),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.blue,
      ),
    );
  }
}
