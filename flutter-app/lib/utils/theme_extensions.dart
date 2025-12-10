import 'package:flutter/material.dart';

/// Color palette matching Swift iOS app's semantic color scheme
class AppColors {
  // Action colors (semantic button colors)
  static const actionSave = Colors.green;
  static const actionConfirm = Colors.green;
  static const actionMap = Colors.blue;
  static final actionMapDark = Colors.blue[700]!;
  static const actionNavigate = Colors.blue;
  static const actionCycle = Colors.blue;
  static const actionIncrement = Colors.orange;
  static const actionDecrement = Colors.orange;
  static const actionWarning = Colors.orange;
  static const actionReset = Colors.red;
  static final actionResetDark = Colors.red[700]!;
  static const actionDelete = Colors.red;
  static const actionCancel = Colors.red;
  static const actionExportCSV = Colors.purple;
  static const actionExportTherion = Colors.grey;
  static final actionSecondary = Colors.grey[700]!;

  // Background colors
  static const backgroundPrimary = Colors.black;
  static const backgroundMain = Colors.black;
  static final backgroundCard = Colors.grey[900]!;
  static final backgroundSecondary = Colors.grey[800]!;
  static final backgroundCardLight = Colors.grey[850]!;

  // Text colors
  static const textPrimary = Colors.white;
  static final textSecondary = Colors.grey[400]!;
  static final textHint = Colors.grey[600]!;

  // Data display colors
  static const dataPrimary = Colors.cyan;
  static const dataSecondary = Colors.orange;
  static const dataDepth = Colors.lightBlue;

  // Status colors
  static const statusGood = Colors.green;
  static const statusBad = Colors.red;
  static const statusWarning = Colors.orange;

  // Overlay colors
  static Color overlayDark = Colors.black.withOpacity(0.7);
  static Color overlaySemiTransparent = Colors.black.withOpacity(0.6);

  AppColors._(); // Private constructor to prevent instantiation
}

/// Typography scale matching Swift iOS app's font sizes and weights
class AppTextStyles {
  // Large displays (primary sensor data)
  static final largeTitle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  // Medium displays (secondary sensor data)
  static final title = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  // Headlines (section titles, parameter names)
  static final headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900, // black weight
    color: AppColors.textPrimary,
  );

  static final headlineMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body text (labels, general text)
  static final body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static final bodySemibold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Caption text (hints, secondary info)
  static final caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static final captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Labels (above data values)
  static final label = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );

  static final labelLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );

  // Monospaced text helper (for numeric values)
  static TextStyle monospaced({
    double fontSize = 36,
    FontWeight fontWeight = FontWeight.bold,
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }

  AppTextStyles._(); // Private constructor to prevent instantiation
}

/// Button sizing constants
class AppButtonSizes {
  // Icon scaling factors
  static const double iconScaleLarge = 0.35; // 35% of button size for icons
  static const double iconScaleMedium = 0.4; // 40% of button size for icons
  static const double textScaleSmall = 0.2; // 20% of button size for text labels
  static const double textScaleMedium = 0.26; // 26% of button size for text labels

  // Default button sizes
  static const double mainScreenDefault = 75.0;
  static const double saveDataScreenDefault = 70.0;

  // Button size constraints
  static const double minSize = 40.0;
  static const double maxSize = 150.0;

  // Position offset constraints
  static const double minOffset = -200.0;
  static const double maxOffset = 200.0;

  AppButtonSizes._(); // Private constructor to prevent instantiation
}

/// Spacing and layout constants
class AppSpacing {
  static const double xxSmall = 4.0;
  static const double xSmall = 8.0;
  static const double small = 12.0;
  static const double medium = 16.0;
  static const double large = 20.0;
  static const double xLarge = 30.0;
  static const double xxLarge = 40.0;

  // Screen and Card styling
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const double cardRadius = 12.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 26.0;

  AppSpacing._(); // Private constructor to prevent instantiation
}

/// Shadow definitions
class AppShadows {
  static const buttonShadow = [
    BoxShadow(
      color: Color(0x40000000), // Black with 25% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const cardShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Black with 10% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  AppShadows._(); // Private constructor to prevent instantiation
}
