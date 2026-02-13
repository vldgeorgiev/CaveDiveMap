import 'package:flutter/material.dart';
import '../models/button_config.dart';
import '../utils/theme_extensions.dart';
import 'underwater_action_button.dart';

/// A draggable button wrapper for customization interface.
class DraggableButtonCustomizer extends StatefulWidget {
  final ButtonConfig config;
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<ButtonConfig> onConfigChanged;
  final VoidCallback onTap;
  final Size screenSize;
  final double topBarHeight;
  final ButtonConfig Function(ButtonConfig proposed)? resolveConstraints;

  const DraggableButtonCustomizer({
    super.key,
    required this.config,
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onConfigChanged,
    required this.onTap,
    required this.screenSize,
    this.topBarHeight = 0.0,
    this.resolveConstraints,
  });

  @override
  State<DraggableButtonCustomizer> createState() =>
      _DraggableButtonCustomizerState();
}

class _DraggableButtonCustomizerState extends State<DraggableButtonCustomizer> {
  late Offset _currentPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _updatePositionFromConfig();
  }

  @override
  void didUpdateWidget(DraggableButtonCustomizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config ||
        oldWidget.screenSize != widget.screenSize) {
      _updatePositionFromConfig();
    }
  }

  void _updatePositionFromConfig() {
    final availableHeight = widget.screenSize.height - widget.topBarHeight;
    final centerX = widget.screenSize.width / 2;
    final centerY = widget.topBarHeight + (availableHeight / 2);
    _currentPosition = Offset(
      centerX + widget.config.offsetX,
      centerY + widget.config.offsetY,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPosition += details.delta;
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final availableHeight = widget.screenSize.height - widget.topBarHeight;
    final centerX = widget.screenSize.width / 2;
    final centerY = widget.topBarHeight + (availableHeight / 2);
    final newOffsetX = _currentPosition.dx - centerX;
    final newOffsetY = _currentPosition.dy - centerY;

    final clampedOffsetX = newOffsetX.clamp(
      -centerX + widget.config.size / 2,
      centerX - widget.config.size / 2,
    );
    final clampedOffsetY = newOffsetY.clamp(
      -(availableHeight / 2) + widget.config.size / 2,
      (availableHeight / 2) - widget.config.size / 2,
    );

    var updated = widget.config.copyWith(
      offsetX: clampedOffsetX,
      offsetY: clampedOffsetY,
    );
    if (widget.resolveConstraints != null) {
      updated = widget.resolveConstraints!(updated);
    }
    widget.onConfigChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.config.size * 0.24);

    return Positioned(
      left: _currentPosition.dx - widget.config.size / 2,
      top: _currentPosition.dy - widget.config.size / 2,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.config.size,
                height: widget.config.size,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: widget.isSelected
                      ? Border.all(color: AppColors.dataPrimary, width: 3)
                      : null,
                  boxShadow: [
                    if (_isDragging)
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: IgnorePointer(
                  // Outer GestureDetector owns select/drag interactions.
                  // Ignoring inner button pointer handling prevents double-tap
                  // toggles (select then immediately deselect).
                  child: UnderwaterActionButton(
                    color: widget.color,
                    icon: widget.icon,
                    size: widget.config.size,
                  ),
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  bottom: -25,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dataPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.backgroundPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
