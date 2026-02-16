import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../services/button_customization_service.dart';
import '../services/rotation_detection/rotation_algorithm.dart';
import '../models/settings.dart';
import '../widgets/underwater_action_button.dart';
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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _showCalibrationToast = false;
  bool _isResetting = false;
  bool _isHoldingReset = false;
  double _resetHoldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    print('[MAIN_SCREEN] initState called');
    // Start sensor services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[MAIN_SCREEN] PostFrameCallback executing');
      final magnetometerService = context.read<MagnetometerService>();
      final compassService = context.read<CompassService>();
      final settings = context.read<Settings>();

      // Sync algorithm selection from settings
      magnetometerService.setAlgorithm(settings.rotationAlgorithm);
      print('[MAIN_SCREEN] Algorithm set to: ${settings.rotationAlgorithm}');

      // Auto-start recording when on main screen (old behavior)
      magnetometerService.startRecording();
      print('[MAIN_SCREEN] Called startRecording()');
      compassService.startListening();

      // Update magnetometer heading whenever compass changes
      compassService.addListener(() {
        magnetometerService.updateHeading(compassService.heading);
      });
    });
  }

  @override
  void dispose() {
    // Stop sensors when leaving screen
    context.read<MagnetometerService>().stopListening();
    context.read<CompassService>().stopListening();
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
    final magnetometer = context.read<MagnetometerService>();
    final compass = context.read<CompassService>();
    final wasRecording = magnetometer.isRecording;

    // Pause sensors while in settings
    magnetometer.stopRecording();
    magnetometer.stopListening();
    compass.stopListening();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (!mounted) return;

    // Resume sensors after returning (regardless of OK/Cancel)
    magnetometer.startListening();
    if (wasRecording) {
      magnetometer.startRecording(
        initialDepth: magnetometer.currentDepth,
        initialHeading: compass.heading,
      );
    }
    compass.startListening();
  }

  void _onResetHoldProgress(double progress) {
    if (!mounted) return;
    setState(() {
      _resetHoldProgress = progress;
      _isHoldingReset = progress > 0.0;
    });
  }

  void _onResetHoldCancelled() {
    final didPartiallyHold =
        _isHoldingReset && _resetHoldProgress > 0.0 && _resetHoldProgress < 1.0;

    if (mounted) {
      setState(() {
        _isHoldingReset = false;
        _resetHoldProgress = 0.0;
      });
    }

    if (!_isResetting && didPartiallyHold && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hold for 6 seconds to reset'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _performReset() async {
    setState(() {
      _isResetting = true;
      _isHoldingReset = false;
      _resetHoldProgress = 0.0;
    });

    final storageService = context.read<StorageService>();
    final exportService = context.read<ExportService>();
    final magnetometerService = context.read<MagnetometerService>();

    // Get current survey data
    final surveyData = await storageService.getAllSurveyData();

    // Export data before reset if there is any
    String? exportedPath;
    if (surveyData.isNotEmpty) {
      try {
        final timestamp = DateTime.now();
        final fileName =
            'backup_'
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_'
            '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}'
            '.csv';

        final file = await exportService.exportToCSV(surveyData, fileName);
        exportedPath = file.path;
      } catch (e) {
        // Show error but continue with reset
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    // Clear all data
    await storageService.clearAllData();
    magnetometerService.reset();

    if (mounted) {
      final message = exportedPath != null
          ? 'Data exported and reset successfully\nBackup: $exportedPath'
          : surveyData.isEmpty
          ? 'No data to export - reset complete'
          : 'Data reset successfully (export failed)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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
      body:
          Consumer4<
            MagnetometerService,
            CompassService,
            ButtonCustomizationService,
            Settings
          >(
            builder:
                (
                  context,
                  magnetometer,
                  compass,
                  buttonService,
                  settings,
                  child,
                ) {
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
                              HeadingAccuracyIndicator(
                                accuracy: compass.accuracy,
                              ),
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
                                context
                                    .watch<StorageService>()
                                    .surveyPoints
                                    .length
                                    .toString(),
                                AppTextStyles.body,
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Magnetic strength indicator
                              _buildMagneticStrengthIndicator(
                                magnetometer.uncalibratedMagnitude,
                                settings.minPeakThreshold,
                                settings.maxPeakThreshold,
                                magnetometer.algorithm,
                                magnetometer.signalQuality,
                              ),

                              // Spacer to push buttons to bottom
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),

                      // Underwater action buttons positioned via ButtonConfig
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
                        onPressed: _performReset,
                        actionProfile: ButtonActionProfile.holdToConfirm,
                        holdDuration: const Duration(seconds: 6),
                        onHoldProgress: _onResetHoldProgress,
                        onHoldCancelled: _onResetHoldCancelled,
                        icon: Icons.refresh,
                        label: 'Reset',
                        color: AppColors.actionReset,
                        showProgress: _isHoldingReset,
                        progressValue: _resetHoldProgress,
                      ),

                      // Calibration toast overlay
                      if (_showCalibrationToast)
                        CalibrationToast(
                          message:
                              'Move device in figure-8 to calibrate compass',
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
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        MonospacedText(
          value,
          style: valueStyle.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMagneticStrengthIndicator(
    double strength,
    double minThreshold,
    double maxThreshold,
    RotationAlgorithm algorithm,
    double signalQuality,
  ) {
    // For PCA algorithm, show signal quality instead
    if (algorithm == RotationAlgorithm.pca) {
      return _buildPCASignalQuality(signalQuality);
    }

    // Legacy threshold algorithm display (using uncalibrated magnitude)
    // Calculate display range: 0 to maxThreshold + 20%
    final displayMax = maxThreshold * 1.2;
    final normalizedStrength = (strength / displayMax).clamp(0.0, 1.0);

    // Three-color scheme based on thresholds (avoiding red)
    Color strengthColor;
    if (strength < minThreshold) {
      // Below min: green (baseline)
      strengthColor = AppColors.statusGood;
    } else if (strength > maxThreshold) {
      // Above max: green (baseline)
      strengthColor = AppColors.statusGood;
    } else {
      // Between min and max: blue (good detection range)
      strengthColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Magnetic Field',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPCASignalQuality(double quality) {
    final percentage = (quality * 100).round();

    Color qualityColor;
    String qualityText;

    if (quality >= 0.7) {
      qualityColor = AppColors.statusGood;
      qualityText = 'Excellent';
    } else if (quality >= 0.5) {
      qualityColor = Colors.blue;
      qualityText = 'Good';
    } else if (quality >= 0.3) {
      qualityColor = Colors.orange;
      qualityText = 'Fair';
    } else {
      qualityColor = Colors.red;
      qualityText = 'Poor';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signal Quality',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: quality,
            backgroundColor: AppColors.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$qualityText ($percentage%)',
          style: AppTextStyles.caption.copyWith(
            color: qualityColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
