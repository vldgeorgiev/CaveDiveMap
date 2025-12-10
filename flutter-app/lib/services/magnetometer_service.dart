import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/survey_data.dart';
import 'storage_service.dart';

/// Service for magnetometer-based distance measurement
/// Detects wheel rotations by identifying peaks in magnetic field strength
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
  double _minPeakThreshold = 50.0;    // μT - must drop below this to reset
  double _maxPeakThreshold = 100.0;   // μT - must exceed this to trigger peak
  bool _isReadyForNewPeak = true;     // State tracker for peak detection
  int _rotationCount = 0;

  // Statistics
  DateTime? _lastRotationTime;
  double _averageRotationInterval = 0.0;

  MagnetometerService(this._storageService);

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
  void startRecording({double initialDepth = 0.0, double initialHeading = 0.0}) {
    if (_isRecording) return;

    _isRecording = true;
    _currentDistance = 0.0;
    _currentDepth = initialDepth;
    _currentHeading = initialHeading;
    _rotationCount = 0;
    _lastRotationTime = null;

    // Subscribe to magnetometer at ~50Hz
    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
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

  /// Reset measurement (new survey)
  void reset() {
    stopRecording();
    _currentDistance = 0.0;
    _currentDepth = 0.0;
    _currentHeading = 0.0;
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
    _wheelCircumference = wheelCircumference; // Circumference passed in (pre-calculated)
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
      event.x * event.x +
      event.y * event.y +
      event.z * event.z
    );

    _magneticStrength = magnitude;

    // Notify listeners to update UI with live sensor values
    notifyListeners();

    // Peak detection algorithm
    // A full rotation is counted when magnitude:
    // 1. Goes ABOVE maxPeakThreshold (peak detected)
    // 2. Then drops BELOW minPeakThreshold (ready for next peak)
    if (_isReadyForNewPeak && magnitude > _maxPeakThreshold) {
      // Peak detected - count rotation
      _onRotationDetected();
      _isReadyForNewPeak = false;
    } else if (!_isReadyForNewPeak && magnitude < _minPeakThreshold) {
      // Magnitude dropped below minimum - ready for next peak
      _isReadyForNewPeak = true;
    }
  }

  /// Handle rotation detection
  void _onRotationDetected() {
    _rotationCount++;

    // Update rotation timing statistics
    final now = DateTime.now();
    if (_lastRotationTime != null) {
      final interval = now.difference(_lastRotationTime!).inMilliseconds / 1000.0;

      // Exponential moving average for smoother interval
      if (_averageRotationInterval == 0.0) {
        _averageRotationInterval = interval;
      } else {
        _averageRotationInterval = 0.7 * _averageRotationInterval + 0.3 * interval;
      }
    }
    _lastRotationTime = now;

    // Calculate new distance
    _currentDistance = _rotationCount * _wheelCircumference;
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
