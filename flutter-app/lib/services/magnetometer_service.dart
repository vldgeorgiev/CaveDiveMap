import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/survey_data.dart';
import 'storage_service.dart';

/// Service for magnetometer-based distance measurement.
///
/// Detects wheel rotations by identifying peaks in magnetic field strength
/// when a magnet passes the sensor. Uses dual-threshold peak detection to
/// avoid false triggers from noise.
///
/// Key features:
/// - Cumulative distance tracking across sessions
/// - Auto-point creation every 10 rotations (2.63m)
/// - Point counter syncs with persisted storage
/// - Distance persists across app restarts
class MagnetometerService extends ChangeNotifier {
  final StorageService _storageService;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // Measurement state
  bool _isRecording = false;
  double _currentDistance = 0.0;
  double _currentDepth = 0.0;
  double _currentHeading = 0.0;
  int _currentPointNumber = 0;
  double _magneticStrength = 0.0;

  // Raw magnetometer values
  double _magnetometerX = 0.0;
  double _magnetometerY = 0.0;
  double _magnetometerZ = 0.0;

  // Settings
  double _wheelCircumference = 0.263; // meters
  double _minPeakThreshold = 50.0; // μT - must drop below this to reset
  double _maxPeakThreshold = 100.0; // μT - must exceed this to trigger peak
  bool _isReadyForNewPeak = true; // State tracker for peak detection
  int _rotationCount = 0;

  // Performance optimization
  int _samplesSinceUIUpdate = 0;
  static const int _uiUpdateInterval = 5; // Update UI every 5 samples (~100ms)

  // Peak detection buffer - track recent max to catch fast peaks
  double _recentMaxMagnitude = 0.0;
  int _samplesSinceMax = 0;
  static const int _maxSampleWindow = 3; // Look back 3 samples (~60ms)

  // Statistics
  DateTime? _lastRotationTime;
  double _averageRotationInterval = 0.0;

  MagnetometerService(this._storageService) {
    // Initialize point counter from persisted data to maintain continuity
    _currentPointNumber = _storageService.surveyPoints.length;

    // Initialize distance from last saved point for cumulative tracking
    // This ensures distance continues from where it left off after app restart
    if (_storageService.surveyPoints.isNotEmpty) {
      _currentDistance = _storageService.surveyPoints.last.distance;
    }
  }

  // Getters
  bool get isRecording => _isRecording;
  double get currentDistance => _currentDistance;
  double get currentDepth => _currentDepth;
  double get totalDistance => _currentDistance;
  int get rotationCount => _rotationCount;
  int get currentPointNumber => _currentPointNumber;
  double get magneticStrength => _magneticStrength;
  double get averageRotationInterval => _averageRotationInterval;
  double get magnetometerX => _magnetometerX;
  double get magnetometerY => _magnetometerY;
  double get magnetometerZ => _magnetometerZ;

  /// Start magnetometer recording
  void startRecording({
    double initialDepth = 0.0,
    double initialHeading = 0.0,
  }) {
    if (_isRecording) return;

    _isRecording = true;
    // Don't reset _currentDistance - it should be cumulative
    _currentDepth = initialDepth;
    _currentHeading = initialHeading;
    _rotationCount = 0;
    _lastRotationTime = null;

    // Subscribe to magnetometer at ~100Hz for better fast rotation detection
    // Note: Actual rate may be limited by hardware capabilities
    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen(_onMagnetometerEvent);

    notifyListeners();
  }

  /// Stop magnetometer recording
  void stopRecording() {
    _isRecording = false;
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;

    notifyListeners();
  }

  /// Reset measurement state for new survey.
  ///
  /// Clears all distance, depth, and heading data.
  /// Resets point counter to 0 (should be called after storage is cleared).
  void reset() {
    stopRecording();
    _currentDistance = 0.0;
    _currentDepth = 0.0;
    _currentHeading = 0.0;
    _currentPointNumber = 0;
    _rotationCount = 0;
    _lastRotationTime = null;
    _averageRotationInterval = 0.0;

    notifyListeners();
  }

  /// Update current depth (manual adjustment)
  void updateDepth(double depth) {
    _currentDepth = depth;
    notifyListeners();
  }

  /// Adjust depth by delta (for +/- buttons)
  void adjustDepth(double delta) {
    _currentDepth = (_currentDepth + delta).clamp(0.0, 200.0);
    notifyListeners();
  }

  /// Increment point number (after manual point save)
  void incrementPointNumber() {
    _currentPointNumber++;
    notifyListeners();
  }

  /// Update settings from Settings model
  void updateSettings({
    required double wheelCircumference,
    required double minPeakThreshold,
    required double maxPeakThreshold,
  }) {
    _wheelCircumference =
        wheelCircumference; // Circumference passed in (pre-calculated)
    _minPeakThreshold = minPeakThreshold;
    _maxPeakThreshold = maxPeakThreshold;
    notifyListeners();
  }

  /// Start listening to sensors
  void startListening() {
    startRecording();
  }

  /// Stop listening to sensors
  void stopListening() {
    stopRecording();
  }

  /// Update current heading (from compass service)
  void updateHeading(double heading) {
    _currentHeading = heading;
    notifyListeners();
  }

  /// Set min peak threshold
  void setMinPeakThreshold(double threshold) {
    _minPeakThreshold = threshold;
    notifyListeners();
  }

  /// Set max peak threshold
  void setMaxPeakThreshold(double threshold) {
    _maxPeakThreshold = threshold;
    notifyListeners();
  }

  /// Process magnetometer event for peak detection
  void _onMagnetometerEvent(MagnetometerEvent event) {
    // Store raw values
    _magnetometerX = event.x;
    _magnetometerY = event.y;
    _magnetometerZ = event.z;

    // Calculate magnetic field magnitude
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    _magneticStrength = magnitude;

    // Track recent maximum to catch fast peaks
    if (magnitude > _recentMaxMagnitude) {
      _recentMaxMagnitude = magnitude;
      _samplesSinceMax = 0;
    } else {
      _samplesSinceMax++;
      // Reset recent max after window expires
      if (_samplesSinceMax > _maxSampleWindow) {
        _recentMaxMagnitude = magnitude;
        _samplesSinceMax = 0;
      }
    }

    // Peak detection algorithm with buffered max
    // A full rotation is counted when magnitude:
    // 1. Goes ABOVE maxPeakThreshold (use recent max for fast peaks)
    // 2. Then drops BELOW minPeakThreshold (ready for next peak)
    if (_isReadyForNewPeak && _recentMaxMagnitude > _maxPeakThreshold) {
      // Peak detected - count rotation
      _onRotationDetected();
      _isReadyForNewPeak = false;
      _recentMaxMagnitude = 0.0; // Reset buffer after detection
    } else if (!_isReadyForNewPeak && magnitude < _minPeakThreshold) {
      // Magnitude dropped below minimum - ready for next peak
      _isReadyForNewPeak = true;
      _recentMaxMagnitude = magnitude;
    }

    // Throttle UI updates to avoid overwhelming the UI thread
    // Only notify listeners every N samples instead of on every reading
    _samplesSinceUIUpdate++;
    if (_samplesSinceUIUpdate >= _uiUpdateInterval) {
      _samplesSinceUIUpdate = 0;
      notifyListeners();
    }
  }

  /// Handle rotation detection
  void _onRotationDetected() {
    _rotationCount++;

    // Update rotation timing statistics
    final now = DateTime.now();
    if (_lastRotationTime != null) {
      final interval =
          now.difference(_lastRotationTime!).inMilliseconds / 1000.0;

      // Exponential moving average for smoother interval
      if (_averageRotationInterval == 0.0) {
        _averageRotationInterval = interval;
      } else {
        _averageRotationInterval =
            0.7 * _averageRotationInterval + 0.3 * interval;
      }
    }
    _lastRotationTime = now;

    // Calculate new distance (add to existing distance)
    _currentDistance += _wheelCircumference;
    _currentPointNumber++;

    // Auto-save survey point
    _autoSaveSurveyPoint();

    notifyListeners();
  }

  /// Automatically save survey point on each rotation
  Future<void> _autoSaveSurveyPoint() async {
    final point = SurveyData(
      recordNumber: _storageService.nextPointNumber,
      distance: _currentDistance,
      heading: _currentHeading,
      depth: _currentDepth,
      rtype: 'auto',
      timestamp: DateTime.now(),
    );

    await _storageService.addSurveyPoint(point);
  }

  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }
}
