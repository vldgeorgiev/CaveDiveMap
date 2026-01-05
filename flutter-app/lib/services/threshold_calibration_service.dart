import 'dart:async';
import 'package:flutter/foundation.dart';

/// Calibration state for the threshold calibration process
enum CalibrationState {
  /// Initial state, no calibration in progress
  idle,

  /// Recording far position (magnet far from phone)
  recordingFar,

  /// Far position recording complete
  farComplete,

  /// Ready to record close position (waiting for user to start)
  readyForClose,

  /// Recording close position (magnet close to phone)
  recordingClose,

  /// Close position recording complete
  closeComplete,

  /// Calculating thresholds
  calculating,

  /// Calibration complete with valid results
  complete,

  /// Error occurred during calibration
  error,
}

/// Service for threshold auto-calibration
///
/// Guides users through a two-step calibration process:
/// 1. Far position: Record MAX magnitude during figure-8 (baseline + noise)
/// 2. Close position: Record MIN magnitude during figure-8 (peak signal)
/// 3. Calculate optimal thresholds with safety margins
class ThresholdCalibrationService extends ChangeNotifier {
  CalibrationState _state = CalibrationState.idle;
  double _currentMagnitude = 0.0;
  double _recordedMaxField = 0.0;
  double _recordedMinField = 0.0;
  double _calculatedMinThreshold = 0.0;
  double _calculatedMaxThreshold = 0.0;
  int _recordingTimeRemaining = 0;
  String? _errorMessage;

  Timer? _recordingTimer;
  Timer? _countdownTimer;
  final List<double> _calibrationSamples = [];

  /// Low-end margin percentage (applied to min threshold, 20% of range)
  static const double lowMarginPercentage = 0.20;

  /// High-end margin percentage (applied to max threshold, 50% of range)
  /// Higher margin accounts for quick rotations where peak is reached briefly
  static const double highMarginPercentage = 0.50;

  /// Minimum required separation between far and close measurements
  static const double minSeparation = 20.0;

  /// Recording duration in seconds for each step
  static const int recordingDuration = 10;

  // Getters
  CalibrationState get state => _state;
  double get currentMagnitude => _currentMagnitude;
  double get recordedMaxField => _recordedMaxField;
  double get recordedMinField => _recordedMinField;
  double get calculatedMinThreshold => _calculatedMinThreshold;
  double get calculatedMaxThreshold => _calculatedMaxThreshold;
  int get recordingTimeRemaining => _recordingTimeRemaining;
  String? get errorMessage => _errorMessage;

  /// Update current magnitude (called by magnetometer service)
  void updateMagnitude(double magnitude) {
    _currentMagnitude = magnitude;

    // Record samples during active recording
    if (_state == CalibrationState.recordingFar ||
        _state == CalibrationState.recordingClose) {
      _calibrationSamples.add(magnitude);

      // Track MAX during far recording (highest value during fig-8)
      // This becomes the baseline threshold (recordedMinField)
      if (_state == CalibrationState.recordingFar) {
        if (magnitude > _recordedMinField) {
          _recordedMinField = magnitude;
        }
      }

      // Track MIN during close recording (lowest value during fig-8)
      // This becomes the peak threshold (recordedMaxField)
      if (_state == CalibrationState.recordingClose) {
        if (_recordedMaxField == 0.0 || magnitude < _recordedMaxField) {
          _recordedMaxField = magnitude;
        }
      }
    }

    notifyListeners();
  }

  /// Start far position calibration (Step 1)
  void startFarCalibration() {
    if (_state != CalibrationState.idle && _state != CalibrationState.farComplete) {
      return;
    }

    _state = CalibrationState.recordingFar;
    _recordedMinField = 0.0;  // Will track MAX value during far position
    _calibrationSamples.clear();
    _recordingTimeRemaining = recordingDuration;
    _errorMessage = null;

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingTimeRemaining--;
      notifyListeners();

      if (_recordingTimeRemaining <= 0) {
        _stopFarRecording();
      }
    });

    notifyListeners();
    print('[CALIBRATION] Started far position recording (${recordingDuration}s)');
  }

  void _stopFarRecording() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = CalibrationState.farComplete;
    notifyListeners();
    print('[CALIBRATION] Far recording complete. Max field: $_recordedMinField μT');
  }

  /// Move to ready for close position (Step 2 preparation)
  void prepareCloseCalibration() {
    if (_state != CalibrationState.farComplete) {
      return;
    }

    _state = CalibrationState.readyForClose;
    notifyListeners();
    print('[CALIBRATION] Ready for close position calibration');
  }

  /// Start close position calibration (Step 2)
  void startCloseCalibration() {
    if (_state != CalibrationState.readyForClose) {
      return;
    }

    _state = CalibrationState.recordingClose;
    _recordedMaxField = 0.0;  // Will track MIN value during close position
    _calibrationSamples.clear();
    _recordingTimeRemaining = recordingDuration;

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingTimeRemaining--;
      notifyListeners();

      if (_recordingTimeRemaining <= 0) {
        _stopCloseRecording();
      }
    });

    notifyListeners();
    print('[CALIBRATION] Started close position recording (${recordingDuration}s)');
  }

  void _stopCloseRecording() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = CalibrationState.closeComplete;
    notifyListeners();
    print('[CALIBRATION] Close recording complete. Min field: $_recordedMaxField μT');
  }

  /// Calculate thresholds from recorded values
  void calculateThresholds() {
    if (_state != CalibrationState.closeComplete) {
      return;
    }

    _state = CalibrationState.calculating;
    notifyListeners();

    // recordedMinField is from FAR position (baseline, LOWER value ~70 μT)
    // recordedMaxField is from CLOSE position (peak signal, HIGHER value ~800 μT)
    // Calculate separate margins for low and high ends
    final range = _recordedMaxField - _recordedMinField;
    final lowMargin = range * lowMarginPercentage;
    final highMargin = range * highMarginPercentage;

    // Apply asymmetric percentage-based margins
    // Low margin (20%) for min threshold
    // High margin (40%) for max threshold to catch brief peaks
    _calculatedMinThreshold = _recordedMinField + lowMargin;
    _calculatedMaxThreshold = _recordedMaxField - highMargin;

    // Validate separation
    final separation = _calculatedMaxThreshold - _calculatedMinThreshold;

    if (separation < minSeparation) {
      _state = CalibrationState.error;
      _errorMessage = 'Insufficient separation between far and close positions.\n\n'
          'Detected: ${_recordedMinField.toStringAsFixed(1)} μT (far) - ${_recordedMaxField.toStringAsFixed(1)} μT (close)\n'
          'Range: ${range.toStringAsFixed(1)} μT\n'
          'Required separation: ${minSeparation.toStringAsFixed(0)} μT\n'
          'Current separation: ${separation.toStringAsFixed(1)} μT\n\n'
          'Please retry with greater distance difference.';
      print('[CALIBRATION] ERROR: Insufficient separation: $separation μT < $minSeparation μT');
      notifyListeners();
      return;
    }

    // Check for inverted values (close field should be higher than far field)
    if (_recordedMaxField < _recordedMinField) {
      _state = CalibrationState.error;
      _errorMessage = 'Far position field is higher than close position.\n\n'
          'This usually means the steps were done in wrong order.\n\n'
          'Please retry the calibration.';
      print('[CALIBRATION] ERROR: Inverted values (far > close)');
      notifyListeners();
      return;
    }

    _state = CalibrationState.complete;
    notifyListeners();
    print('[CALIBRATION] Calculation complete. Range: ${range.toStringAsFixed(1)} μT, Low Margin: ${lowMargin.toStringAsFixed(1)} μT (${(lowMarginPercentage * 100).toStringAsFixed(0)}%), High Margin: ${highMargin.toStringAsFixed(1)} μT (${(highMarginPercentage * 100).toStringAsFixed(0)}%), Thresholds: ${_calculatedMinThreshold.toStringAsFixed(1)} - ${_calculatedMaxThreshold.toStringAsFixed(1)} μT');
  }

  /// Cancel calibration and reset to idle
  void cancel() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _countdownTimer = null;
    _recordingTimer = null;

    reset();
    print('[CALIBRATION] Calibration cancelled');
  }

  /// Reset all calibration data
  void reset() {
    _state = CalibrationState.idle;
    _currentMagnitude = 0.0;
    _recordedMaxField = 0.0;
    _recordedMinField = 0.0;
    _calculatedMinThreshold = 0.0;
    _calculatedMaxThreshold = 0.0;
    _recordingTimeRemaining = 0;
    _errorMessage = null;
    _calibrationSamples.clear();
    notifyListeners();
  }

  /// Retry after error
  void retry() {
    if (_state == CalibrationState.error) {
      reset();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }
}
