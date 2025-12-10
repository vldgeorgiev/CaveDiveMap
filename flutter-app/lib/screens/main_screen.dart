import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';
import '../services/storage_service.dart';
import '../services/button_customization_service.dart';
import '../widgets/positioned_button.dart';
import '../widgets/monospaced_text.dart';
import '../widgets/heading_accuracy_indicator.dart';
import '../widgets/calibration_toast.dart';
import '../utils/theme_extensions.dart';
import 'save_data_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';

/// Main survey screen - displays real-time sensor data and controls
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showCalibrationToast = false;
  Timer? _resetHoldTimer;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    // Start sensor services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MagnetometerService>().startListening();
      context.read<CompassService>().startListening();
    });
  }

  @override
  void dispose() {
    // Stop sensors when leaving screen
    context.read<MagnetometerService>().stopListening();
    context.read<CompassService>().stopListening();
    _resetHoldTimer?.cancel();
    super.dispose();
  }

  void _navigateToSaveData() {
    final compass = context.read<CompassService>();

    // Check heading accuracy before allowing save
    if (compass.accuracy > 15) {
      setState(() => _showCalibrationToast = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _showCalibrationToast = false);
        }
      });
      return;
    }

    // Capture current heading to pass as static value
    final capturedHeading = compass.heading;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveDataScreen(capturedHeading: capturedHeading),
      ),
    );
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  Future<void> _navigateToSettings() async {
    // Stop sensors before navigating to settings
    context.read<MagnetometerService>().stopListening();
    context.read<CompassService>().stopListening();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    // Restart sensors after returning from settings
    if (mounted) {
      context.read<MagnetometerService>().startListening();
      context.read<CompassService>().startListening();
    }
  }

  void _onResetTapDown() {
    _resetHoldTimer = Timer(const Duration(seconds: 3), () {
      _confirmReset();
    });
  }

  void _onResetTapUp() {
    _resetHoldTimer?.cancel();
    _resetHoldTimer = null;

    if (!_isResetting) {
      // Show hint about long-press
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hold for 3 seconds to reset'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _onResetTapCancel() {
    _resetHoldTimer?.cancel();
    _resetHoldTimer = null;
  }

  Future<void> _confirmReset() async {
    _isResetting = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Survey'),
        content: const Text(
          'Are you sure you want to reset all survey data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final storageService = context.read<StorageService>();
      await storageService.clearAllData();
      context.read<MagnetometerService>().reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    _isResetting = false;
  }

  void _showCameraNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera feature not yet implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Cave Dive Map',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings, color: AppColors.textPrimary),
          onPressed: _navigateToSettings,
          tooltip: 'Settings',
        ),
      ),
      body: Consumer3<MagnetometerService, CompassService, ButtonCustomizationService>(
        builder: (context, magnetometer, compass, buttonService, child) {
          return Stack(
            children: [
              // Main sensor data display
              SafeArea(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading with large typography
                      _buildLargeDataRow(
                        'Heading',
                        '${compass.heading.toStringAsFixed(1)}°',
                        AppTextStyles.largeTitle,
                      ),
                      const SizedBox(height: 4),

                      // Heading accuracy indicator
                      HeadingAccuracyIndicator(accuracy: compass.accuracy),
                      const SizedBox(height: AppSpacing.small),

                      // Distance with large typography
                      _buildLargeDataRow(
                        'Distance',
                        '${magnetometer.totalDistance.toStringAsFixed(2)} m',
                        AppTextStyles.largeTitle,
                      ),
                      const SizedBox(height: AppSpacing.small),

                      // Point number (smaller text)
                      _buildLargeDataRow(
                        'Points',
                        magnetometer.currentPointNumber.toString(),
                        AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.small),

                      // Magnetic strength indicator
                      _buildMagneticStrengthIndicator(magnetometer.magneticStrength),

                      // Spacer to push buttons to bottom
                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // Circular action buttons positioned via ButtonConfig
              PositionedButton(
                config: buttonService.mainSaveButton,
                onPressed: _navigateToSaveData,
                icon: Icons.save,
                label: 'Save',
                color: AppColors.actionSave,
              ),

              PositionedButton(
                config: buttonService.mainMapButton,
                onPressed: _navigateToMap,
                icon: Icons.map,
                label: 'Map',
                color: AppColors.actionMap,
              ),

              PositionedButton(
                config: buttonService.mainResetButton,
                onTapDown: (_) => _onResetTapDown(),
                onTapUp: (_) => _onResetTapUp(),
                onTapCancel: _onResetTapCancel,
                icon: Icons.refresh,
                label: 'Reset',
                color: AppColors.actionReset,
              ),

              PositionedButton(
                config: buttonService.mainCameraButton,
                onPressed: _showCameraNotImplemented,
                icon: Icons.camera_alt,
                label: 'Photo',
                color: AppColors.actionSecondary,
              ),

              // Calibration toast overlay
              if (_showCalibrationToast)
                CalibrationToast(
                  message: 'Move device in figure-8 to calibrate compass',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLargeDataRow(String label, String value, TextStyle valueStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        MonospacedText(
          value,
          style: valueStyle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMagneticStrengthIndicator(double strength) {
    // Normalize strength to 0-100 range for display
    final normalizedStrength = (strength / 100.0).clamp(0.0, 1.0);

    Color strengthColor;
    if (normalizedStrength > 0.7) {
      strengthColor = AppColors.statusGood;
    } else if (normalizedStrength > 0.4) {
      strengthColor = AppColors.statusWarning;
    } else {
      strengthColor = AppColors.statusBad;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Magnetic Field',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: normalizedStrength,
            backgroundColor: AppColors.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${strength.toStringAsFixed(1)} μT',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
