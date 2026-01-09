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
/// - Glove-friendly tap detection with movement tolerance
class CircularActionButton extends StatefulWidget {
  final double size;
  final Color color;
  final IconData? icon;
  final String? text;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;
  final bool showProgress;
  final double progressValue;

  /// Movement tolerance in pixels before tap is canceled (default: 30.0 for glove-friendly use)
  final double slopTolerance;

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
    this.showProgress = false,
    this.progressValue = 0.0,
    this.slopTolerance = 30.0, // Increased tolerance for underwater glove use
  }) : assert(icon != null || text != null, 'Must provide either icon or text');

  @override
  State<CircularActionButton> createState() => _CircularActionButtonState();
}

class _CircularActionButtonState extends State<CircularActionButton> {
  Offset? _tapDownPosition;
  bool _isPotentialTap = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapDownPosition = details.localPosition;
      _isPotentialTap = true;
    });
    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    // Check if finger moved within tolerance
    if (_isPotentialTap && _tapDownPosition != null) {
      final distance = (details.localPosition - _tapDownPosition!).distance;
      if (distance <= widget.slopTolerance) {
        // Movement within tolerance - treat as valid tap
        widget.onTapUp?.call(details);
      } else {
        // Movement exceeded tolerance - cancel tap
        widget.onTapCancel?.call();
      }
    }

    setState(() {
      _tapDownPosition = null;
      _isPotentialTap = false;
    });
  }

  void _handleTapCancel() {
    // Only cancel if we're actually tracking a tap
    if (_isPotentialTap) {
      widget.onTapCancel?.call();
    }

    setState(() {
      _tapDownPosition = null;
      _isPotentialTap = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure minimum tap target of 48x48 for accessibility and glove use
    const minTapTarget = 48.0;
    final tapTargetSize = widget.size < minTapTarget ? minTapTarget : widget.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Capture all touches in tap target area
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.onTapDown != null || widget.onTapUp != null ? _handleTapDown : null,
      onTapUp: widget.onTapUp != null ? _handleTapUp : null,
      onTapCancel: widget.onTapCancel != null ? _handleTapCancel : null,
      child: Container(
        // Expanded tap target for better touch detection
        width: tapTargetSize,
        height: tapTargetSize,
        alignment: Alignment.center,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Main button
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: AppShadows.buttonShadow,
                ),
                child: Center(
                  child: widget.icon != null
                      ? Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.size * AppButtonSizes.iconScaleLarge,
                        )
                      : Text(
                          widget.text!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.size * AppButtonSizes.textScaleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
              // Progress indicator overlay
              if (widget.showProgress)
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: widget.progressValue,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
