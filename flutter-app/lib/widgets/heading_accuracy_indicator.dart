import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Heading accuracy indicator with color-coded circle
///
/// Displays heading error value with:
/// - Green circle if accuracy < 20 degrees (good)
/// - Red circle if accuracy >= 20 degrees (poor)
///
/// Matches Swift app's heading accuracy indicator
class HeadingAccuracyIndicator extends StatelessWidget {
  final double accuracy;

  const HeadingAccuracyIndicator({
    super.key,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = accuracy < 20;
    final color = isGood ? AppColors.statusGood : AppColors.statusBad;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Heading error: ${accuracy.toStringAsFixed(2)}',
          style: AppTextStyles.largeTitle.copyWith(
            fontSize: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }
}
