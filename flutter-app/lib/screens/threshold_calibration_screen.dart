import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/threshold_calibration_service.dart';
import '../services/storage_service.dart';
import '../models/settings.dart';
import '../utils/theme_extensions.dart';

/// Screen for threshold auto-calibration
///
/// Guides user through two-step calibration process:
/// 1. Record maximum field (magnet far)
/// 2. Record minimum field (magnet close)
/// 3. Display and apply calculated thresholds
class ThresholdCalibrationScreen extends StatefulWidget {
  const ThresholdCalibrationScreen({super.key});

  @override
  State<ThresholdCalibrationScreen> createState() => _ThresholdCalibrationScreenState();
}

class _ThresholdCalibrationScreenState extends State<ThresholdCalibrationScreen> {

  @override
  void initState() {
    super.initState();
    // Reset calibration state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThresholdCalibrationService>().reset();
    });
  }

  Future<bool> _onWillPop() async {
    final calibService = context.read<ThresholdCalibrationService>();

    // If calibration is in progress, confirm before exiting
    if (calibService.state == CalibrationState.recordingFar ||
        calibService.state == CalibrationState.recordingClose) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text('Cancel Calibration?', style: AppTextStyles.body),
          content: Text(
            'Calibration is in progress. Are you sure you want to cancel?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Continue Calibrating', style: AppTextStyles.body),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cancel', style: AppTextStyles.body.copyWith(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        calibService.cancel();
        return true;
      }
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text('Threshold Calibration', style: AppTextStyles.body),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: Consumer<ThresholdCalibrationService>(
          builder: (context, calibService, child) {
            final state = calibService.state;

            if (state == CalibrationState.complete) {
              return _buildResultScreen(calibService);
            } else if (state == CalibrationState.error) {
              return _buildErrorScreen(calibService);
            } else {
              return _buildCalibrationScreen(calibService);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCalibrationScreen(ThresholdCalibrationService calibService) {
    final state = calibService.state;
    final isFarStep = state == CalibrationState.idle ||
                      state == CalibrationState.recordingFar ||
                      state == CalibrationState.farComplete;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              _buildStepIndicator(isFarStep),
              const SizedBox(height: 16),

              // Instructions
              _buildInstructions(state),
              const SizedBox(height: 20),

              // Magnitude display
              _buildMagnitudeDisplay(calibService),
              const SizedBox(height: 16),

              // Progress/countdown
              if (state == CalibrationState.recordingFar ||
                  state == CalibrationState.recordingClose)
                _buildCountdown(calibService),

              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(calibService, state),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isFarStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, true, isFarStep),
        Container(
          width: 60,
          height: 2,
          color: isFarStep ? Colors.grey : AppColors.actionSave,
        ),
        _buildStepCircle(2, !isFarStep, !isFarStep),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive, bool isComplete) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.actionSave
            : (isComplete ? AppColors.actionSave : Colors.grey),
        border: Border.all(
          color: isActive ? AppColors.actionSave : Colors.grey,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          'Step $step',
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(CalibrationState state) {
    String title;
    String instructions;
    IconData icon;

    if (state == CalibrationState.idle ||
        state == CalibrationState.recordingFar ||
        state == CalibrationState.farComplete) {
      title = 'Step 1: Far Position';
      instructions = 'Position the wheel with the magnet as FAR as possible from your phone.\n\n'
          'Then move your phone in a figure-8 motion.';
      icon = Icons.swap_horiz;
    } else {
      title = 'Step 2: Close Position';
      instructions = 'Position the wheel with the magnet as CLOSE as possible to your phone.\n\n'
          'Then move your phone in a figure-8 motion.';
      icon = Icons.close_fullscreen;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.actionSave),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: AppTextStyles.body.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMagnitudeDisplay(ThresholdCalibrationService calibService) {
    final magnitude = calibService.currentMagnitude;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Magnetic Field',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            magnitude.toStringAsFixed(1),
            style: AppTextStyles.body.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'μT',
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(ThresholdCalibrationService calibService) {
    final timeRemaining = calibService.recordingTimeRemaining;

    return Column(
      children: [
        LinearProgressIndicator(
          value: timeRemaining / ThresholdCalibrationService.recordingDuration,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.actionSave),
        ),
        const SizedBox(height: 12),
        Text(
          '$timeRemaining seconds',
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    ThresholdCalibrationService calibService,
    CalibrationState state,
  ) {
    if (state == CalibrationState.idle) {
      return ElevatedButton(
        onPressed: () => calibService.startFarCalibration(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionSave,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Start Recording', style: AppTextStyles.body.copyWith(fontSize: 18)),
      );
    } else if (state == CalibrationState.farComplete) {
      return ElevatedButton(
        onPressed: () => calibService.prepareCloseCalibration(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionSave,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Next', style: AppTextStyles.body.copyWith(fontSize: 18)),
      );
    } else if (state == CalibrationState.readyForClose) {
      return ElevatedButton(
        onPressed: () => calibService.startCloseCalibration(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionSave,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Start Recording', style: AppTextStyles.body.copyWith(fontSize: 18)),
      );
    } else if (state == CalibrationState.closeComplete) {
      return ElevatedButton(
        onPressed: () => calibService.calculateThresholds(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionSave,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Calculate', style: AppTextStyles.body.copyWith(fontSize: 18)),
      );
    } else if (state == CalibrationState.recordingFar ||
               state == CalibrationState.recordingClose) {
      return Text(
        'Recording...',
        style: AppTextStyles.body.copyWith(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultScreen(ThresholdCalibrationService calibService) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Calibration Complete',
                style: AppTextStyles.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Detected values
              _buildInfoCard(
                'Detected Values',
                [
                  'Far Position: ${calibService.recordedMinField.toStringAsFixed(1)} μT',
                  'Close Position: ${calibService.recordedMaxField.toStringAsFixed(1)} μT',
                ],
              ),
              const SizedBox(height: 12),

              // Calculated thresholds
              _buildInfoCard(
                'Calculated Thresholds',
                [
                  'Min Threshold: ${calibService.calculatedMinThreshold.toStringAsFixed(1)} μT',
                  'Max Threshold: ${calibService.calculatedMaxThreshold.toStringAsFixed(1)} μT',
                  '',
                  'Margin: ${(ThresholdCalibrationService.marginPercentage * 100).toStringAsFixed(0)}% of range',
                  'Separation: ${(calibService.calculatedMaxThreshold - calibService.calculatedMinThreshold).toStringAsFixed(1)} μT ✓',
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              ElevatedButton(
                onPressed: () => _applyThresholds(calibService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionSave,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Apply', style: AppTextStyles.body.copyWith(fontSize: 16)),
              ),
              const SizedBox(height: 10),

              // Retry button
              OutlinedButton(
                onPressed: () => calibService.retry(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.actionSave),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Retry', style: AppTextStyles.body.copyWith(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThresholdCalibrationService calibService) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Calibration Error',
                style: AppTextStyles.body.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  calibService.errorMessage ?? 'An unknown error occurred.',
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Retry button
              ElevatedButton(
                onPressed: () => calibService.retry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionSave,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Retry', style: AppTextStyles.body.copyWith(fontSize: 18)),
              ),
              const SizedBox(height: 12),

              // Cancel button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Cancel', style: AppTextStyles.body.copyWith(fontSize: 18)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              item,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _applyThresholds(ThresholdCalibrationService calibService) async {
    final settings = context.read<Settings>();
    final storageService = context.read<StorageService>();

    // Update settings
    settings.updateMinPeakThreshold(calibService.calculatedMinThreshold);
    settings.updateMaxPeakThreshold(calibService.calculatedMaxThreshold);

    // Save to storage
    await storageService.saveSettings(settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thresholds calibrated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
