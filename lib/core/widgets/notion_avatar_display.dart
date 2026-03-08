import 'package:flutter/material.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar_controller.dart';

class NotionAvatarDisplay extends StatefulWidget {
  final Map<String, int> avatarData;
  final double size;

  const NotionAvatarDisplay({
    super.key,
    required this.avatarData,
    this.size = 80,
  });

  @override
  State<NotionAvatarDisplay> createState() => _NotionAvatarDisplayState();
}

class _NotionAvatarDisplayState extends State<NotionAvatarDisplay> {
  NotionAvatarController? _controller;

  @override
  void didUpdateWidget(covariant NotionAvatarDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarData != widget.avatarData) {
      _applyConfig();
    }
  }

  void _applyConfig() {
    final c = _controller;
    if (c == null) return;
    final d = widget.avatarData;
    c.setFace(d['face'] ?? 0);
    c.setNose(d['nose'] ?? 0);
    c.setMouth(d['mouth'] ?? 0);
    c.setEyes(d['eyes'] ?? 0);
    c.setEyebrows(d['eyebrows'] ?? 0);
    c.setGlasses(d['glasses'] ?? 0);
    c.setHair(d['hair'] ?? 0);
    c.setAccessories(d['accessories'] ?? 0);
    c.setDetails(d['details'] ?? 0);
    c.setBeard(d['beard'] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: NotionAvatar(
        onCreated: (controller) {
          _controller = controller;
          _applyConfig();
        },
      ),
    );
  }
}
