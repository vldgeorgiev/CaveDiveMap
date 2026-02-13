import 'package:flutter/material.dart';
import '../models/button_config.dart';
import 'underwater_action_button.dart';

/// Positions an underwater action button using ButtonConfig offsets.
///
/// Calculates absolute position from screen center with custom offsets,
/// matching Swift app's ZStack with .offset() behavior
class PositionedButton extends StatelessWidget {
  final ButtonConfig config;
  final Color color;
  final IconData? icon;
  final String? label; // Renamed from text for consistency
  final VoidCallback? onPressed; // Renamed from onTap for consistency
  final ButtonActionProfile actionProfile;
  final Duration holdDuration;
  final Duration repeatInitialDelay;
  final Duration repeatInterval;
  final ValueChanged<double>? onHoldProgress;
  final VoidCallback? onHoldCancelled;
  final ValueChanged<bool>? onInteractionStateChanged;
  final bool showProgress;
  final double progressValue;

  const PositionedButton({
    super.key,
    required this.config,
    required this.color,
    this.icon,
    this.label,
    this.onPressed,
    this.actionProfile = ButtonActionProfile.singleTap,
    this.holdDuration = const Duration(seconds: 6),
    this.repeatInitialDelay = const Duration(milliseconds: 500),
    this.repeatInterval = const Duration(milliseconds: 120),
    this.onHoldProgress,
    this.onHoldCancelled,
    this.onInteractionStateChanged,
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
      child: UnderwaterActionButton(
        size: config.size,
        color: color,
        icon: icon,
        text: label,
        onTap: onPressed,
        actionProfile: actionProfile,
        holdDuration: holdDuration,
        repeatInitialDelay: repeatInitialDelay,
        repeatInterval: repeatInterval,
        onHoldProgress: onHoldProgress,
        onHoldCancelled: onHoldCancelled,
        onInteractionStateChanged: onInteractionStateChanged,
        showProgress: showProgress,
        progressValue: progressValue,
      ),
    );
  }
}
