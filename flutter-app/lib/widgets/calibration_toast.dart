import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Toast overlay for calibration warning
///
/// Displays "Move to calibrate" message when heading accuracy is poor
/// Auto-dismisses after a short duration
class CalibrationToast extends StatelessWidget {
  final String? message;

  const CalibrationToast({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xLarge,
            vertical: AppSpacing.medium,
          ),
          decoration: BoxDecoration(
            color: AppColors.overlayDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message ?? 'Move to calibrate',
            style: AppTextStyles.largeTitle.copyWith(
              color: AppColors.statusBad,
            ),
          ),
        ),
      ),
    );
  }
}
