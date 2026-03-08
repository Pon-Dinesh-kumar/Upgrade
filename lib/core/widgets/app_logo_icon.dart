import 'package:flutter/material.dart';

/// App logo icon (UPGRADE). Use [color] to tint for theme (e.g. nav bar).
/// Omit [color] for the default white icon on transparent background (e.g. on blue circle).
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/icon_no_bg.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      errorBuilder: (_, __, ___) => Icon(
        Icons.rocket_launch_rounded,
        size: size,
        color: color ?? Colors.white,
      ),
    );
  }
}
