import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Rounded info card container
///
/// Used for grouping related information with consistent styling
/// Matches Swift app's card design with grey background and border
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const InfoCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
