import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Circular action button with customizable appearance
///
/// Matches Swift app's circular button design with:
/// - Circular shape
/// - Colored background
/// - White icon or text
/// - Shadow effect
/// - Proportional sizing
class CircularActionButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData? icon;
  final String? text;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;

  const CircularActionButton({
    super.key,
    required this.size,
    required this.color,
    this.icon,
    this.text,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  }) : assert(icon != null || text != null, 'Must provide either icon or text');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: AppShadows.buttonShadow,
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: Colors.white,
                  size: size * AppButtonSizes.iconScaleLarge,
                )
              : Text(
                  text!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * AppButtonSizes.textScaleMedium,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
