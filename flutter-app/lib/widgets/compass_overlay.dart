import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Compass overlay for map view
///
/// Displays a north-pointing arrow that rotates inversely to map rotation
/// Always indicates true north direction regardless of map orientation
class CompassOverlay extends StatelessWidget {
  final double mapRotation; // Map rotation in radians

  const CompassOverlay({super.key, required this.mapRotation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.medium,
      right: AppSpacing.medium,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.overlaySemiTransparent,
        ),
        child: Center(
          child: Transform.rotate(
            angle: -mapRotation, // Rotate opposite to map
            child: const Icon(Icons.navigation, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
