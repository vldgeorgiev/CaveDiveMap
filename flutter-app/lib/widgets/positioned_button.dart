import 'package:flutter/material.dart';
import '../models/button_config.dart';
import 'circular_action_button.dart';

/// Positions a circular action button using ButtonConfig offsets
///
/// Calculates absolute position from screen center with custom offsets,
/// matching Swift app's ZStack with .offset() behavior
class PositionedButton extends StatelessWidget {
  final ButtonConfig config;
  final Color color;
  final IconData? icon;
  final String? label; // Renamed from text for consistency
  final VoidCallback? onPressed; // Renamed from onTap for consistency
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;
  final bool showProgress;
  final double progressValue;

  const PositionedButton({
    super.key,
    required this.config,
    required this.color,
    this.icon,
    this.label,
    this.onPressed,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.showProgress = false,
    this.progressValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size from MediaQuery
    final screenSize = MediaQuery.of(context).size;

    // Calculate position: center + offset - half button size (to center the button)
    final left = (screenSize.width / 2) + config.offsetX - (config.size / 2);
    final top = (screenSize.height / 2) + config.offsetY - (config.size / 2);

    return Positioned(
      left: left,
      top: top,
      child: CircularActionButton(
        size: config.size,
        color: color,
        icon: icon,
        text: label,
        onTap: onPressed,
        onLongPress: onLongPress,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        showProgress: showProgress,
        progressValue: progressValue,
      ),
    );
  }
}
