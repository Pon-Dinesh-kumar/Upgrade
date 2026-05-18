import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/card_shell.dart';
import '../../core/widgets/minimalist_avatar_display.dart';
import '../../data/providers.dart';
import '../../domain/entities/user_profile.dart';
import 'avatar_editor_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const ProfileSettingsScreen({super.key, required this.profile});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late TextEditingController _usernameController;
  UserProfile? _localProfile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _localProfile = widget.profile;
    
    _usernameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool _hasChanges(UserProfile currentProfile) {
    if (_localProfile == null) return false;
    
    final usernameChanged = _usernameController.text.trim() != currentProfile.username;
    final avatarTypeChanged = _localProfile!.avatarType != currentProfile.avatarType;
    final customAvatarChanged = _localProfile!.customAvatarPath != currentProfile.customAvatarPath;
    final avatarDataChanged = _localProfile!.avatarData != currentProfile.avatarData;

    return usernameChanged || avatarTypeChanged || customAvatarChanged || avatarDataChanged;
  }

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: result.files.single.path!,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: surfaceColor,
              toolbarWidgetColor: onSurfaceColor,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final file = File(croppedFile.path);
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'pfp_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
          final savedImage = await file.copy(path.join(directory.path, fileName));
          
          setState(() {
            _localProfile = _localProfile!.copyWith(
              customAvatarPath: savedImage.path,
              avatarType: 'custom',
            );
          });
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error cropping image: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveAll() async {
    if (_localProfile == null) return;
    
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final finalProfile = _localProfile!.copyWith(username: newUsername);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(userProfileProvider.notifier).save(finalProfile);
    
    if (mounted) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileFromProvider = ref.watch(userProfileProvider).valueOrNull ?? widget.profile;
    
    // Sync local profile if provider changes and we haven't touched it yet
    // Or just always use local profile for display and only update it from provider
    // if it was null (first load) or if we want to reset.
    // Actually, if the user goes to AvatarEditor and back, the provider changes.
    // We should probably update _localProfile if it matches the OLD provider value.
    
    final displayProfile = _localProfile ?? profileFromProvider;
    final hasChanges = _hasChanges(profileFromProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        automaticallyImplyLeading: false,
        leading: null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CardShell(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Minimalist Avatar Preview
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _localProfile = displayProfile.copyWith(avatarType: 'minimalist');
                              });
                            },
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: displayProfile.avatarType == 'minimalist'
                                            ? Border.all(color: theme.colorScheme.primary, width: 4)
                                            : Border.all(color: theme.dividerColor.withValues(alpha: 0.1), width: 1),
                                      ),
                                    ),
                                    Container(
                                      width: 74,
                                      height: 74,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.dividerColor.withValues(alpha: 0.1),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: MinimalistAvatarDisplay(avatarData: displayProfile.avatarData, size: 74),
                                    ),
                                    if (displayProfile.avatarType == 'minimalist')
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Minimalist',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: displayProfile.avatarType == 'minimalist' ? FontWeight.bold : FontWeight.normal,
                                    color: displayProfile.avatarType == 'minimalist' ? theme.colorScheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Vertical Divider
                          Container(
                            height: 60,
                            width: 1,
                            color: theme.dividerColor.withValues(alpha: 0.2),
                          ),
                          // Custom Photo Preview
                          GestureDetector(
                            onTap: () {
                              if (displayProfile.customAvatarPath != null) {
                                setState(() {
                                  _localProfile = displayProfile.copyWith(avatarType: 'custom');
                                });
                              } else {
                                _pickImage();
                              }
                            },
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: displayProfile.avatarType == 'custom'
                                            ? Border.all(color: theme.colorScheme.primary, width: 4)
                                            : Border.all(color: theme.dividerColor.withValues(alpha: 0.1), width: 1),
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          width: 74,
                                          height: 74,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.dividerColor.withValues(alpha: 0.1),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: displayProfile.customAvatarPath != null
                                              ? Image.file(File(displayProfile.customAvatarPath!), fit: BoxFit.cover)
                                              : const Icon(Icons.person, size: 36),
                                        ),
                                        if (displayProfile.customAvatarPath == null)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (displayProfile.avatarType == 'custom')
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Custom',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: displayProfile.avatarType == 'custom' ? FontWeight.bold : FontWeight.normal,
                                    color: displayProfile.avatarType == 'custom' ? theme.colorScheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push<UserProfile>(
                              MaterialPageRoute(
                                builder: (context) => AvatarEditorScreen(profile: displayProfile),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _localProfile = result;
                              });
                            }
                          },
                          child: const Text('Customize Minimalist Avatar'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload New Photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload_rounded, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Select from Gallery',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (displayProfile.customAvatarPath != null)
                        TextButton(
                          onPressed: () {
                            final oldPath = displayProfile.customAvatarPath;
                            setState(() {
                              _localProfile = displayProfile.copyWith(
                                clearCustomAvatar: true,
                                avatarType: 'minimalist',
                              );
                            });
                            
                            // Physically delete the file if it exists
                            if (oldPath != null) {
                              try {
                                final file = File(oldPath);
                                if (file.existsSync()) {
                                  file.deleteSync();
                                }
                              } catch (e) {
                                debugPrint('Error deleting old profile photo: $e');
                              }
                            }
                          },
                          child: const Text('Remove Custom Photo', style: TextStyle(color: AppColors.red, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CardShell(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter username',
                          suffixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasChanges)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveAll,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
