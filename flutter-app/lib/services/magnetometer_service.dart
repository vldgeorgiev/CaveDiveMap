import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/survey_data.dart';
import 'storage_service.dart';
import 'rotation_detection/rotation_algorithm.dart';
import 'rotation_detection/pca_rotation_detector.dart';
import 'rotation_detection/vector3.dart';
import 'uncalibrated_magnetometer.dart';

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
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<Map<String, double>>? _uncalibratedMagSubscription;

  // Measurement state
  bool _isListening = false; // Magnetometer active
  bool _isRecording = false; // Actively counting rotations
  double _currentDistance = 0.0;
  double _currentDepth = 0.0;
  double _currentHeading = 0.0;
  int _currentPointNumber = 0;
  double _magneticStrength = 0.0;

  // Raw magnetometer values
  double _magnetometerX = 0.0;
  double _magnetometerY = 0.0;
  double _magnetometerZ = 0.0;
  double _uncalibratedX = 0.0;
  double _uncalibratedY = 0.0;
  double _uncalibratedZ = 0.0;
  double _uncalibratedMagnitude = 0.0;

  // Settings
  double _wheelCircumference = 0.263; // meters
  double _minPeakThreshold = 50.0; // μT - must drop below this to reset
  double _maxPeakThreshold = 100.0; // μT - must exceed this to trigger peak
  bool _isReadyForNewPeak = true; // State tracker for peak detection
  int _rotationCount = 0;

  // Algorithm selection
  RotationAlgorithm _algorithm = RotationAlgorithm.threshold;
  PCARotationDetector? _pcaDetector;
  bool _uncalibratedActive = false;
  bool _uncalibratedSupported = true;
  String? _uncalibratedError;
  int _lastUncalibratedMs = 0;

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

    // Auto-start listening and recording since the app has no manual start
    // control. This ensures rotation detection begins immediately on launch.
    startListening();
    startRecording();
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
  double get uncalibratedX => _uncalibratedX;
  double get uncalibratedY => _uncalibratedY;
  double get uncalibratedZ => _uncalibratedZ;
  double get uncalibratedMagnitude => _uncalibratedMagnitude;
  bool get uncalibratedSupported => _uncalibratedSupported;
  String? get uncalibratedError => _uncalibratedError;
  RotationAlgorithm get algorithm => _algorithm;
  PCARotationDetector? get pcaDetector => _pcaDetector;

  /// Signal quality [0.0, 1.0] for PCA algorithm (0.0 for threshold).
  double get signalQuality {
    return _algorithm == RotationAlgorithm.pca
        ? (_pcaDetector?.signalQuality ?? 0.0)
        : 0.0;
  }

  /// Fractional rotations (includes partial rotations) for PCA algorithm.
  /// Returns 0.0 for threshold algorithm.
  double get fractionalRotations {
    return _algorithm == RotationAlgorithm.pca
        ? (_pcaDetector?.fractionalRotations ?? 0.0)
        : _rotationCount.toDouble();
  }

  /// Continuous distance including fractional rotations (meters).
  /// For PCA mode: uses fractional rotations for smooth updates.
  /// For threshold mode: uses integer rotation count only.
  double get fractionalDistance {
    if (_algorithm == RotationAlgorithm.pca && _pcaDetector != null) {
      return _currentDistance - (_rotationCount * _wheelCircumference) + _pcaDetector!.continuousDistance;
    }
    // Threshold mode: same as currentDistance (integer rotations only)
    return _currentDistance;
  }

  /// Start magnetometer recording
  void startRecording({
    double initialDepth = 0.0,
    double initialHeading = 0.0,
  }) {
    print('[MAG] startRecording() called | _isRecording=$_isRecording | _isListening=$_isListening');
    if (_isRecording) {
      print('[MAG] Already recording, returning early');
      return;
    }

    // Start listening if not already
    if (!_isListening) {
      print('[MAG] Not listening, calling startListening()');
      startListening();
    }

    _isRecording = true;
    print('[MAG] 🔴 Started recording | Algorithm: $_algorithm | Initial distance: $_currentDistance m');
    // Don't reset _currentDistance - it should be cumulative
    _currentDepth = initialDepth;
    _currentHeading = initialHeading;
    _rotationCount = 0;
    _lastRotationTime = null;

    // Reset PCA detector for fresh rotation counting
    if (_algorithm == RotationAlgorithm.pca && _pcaDetector != null) {
      _pcaDetector!.reset();
      print('[MAG] 🔄 PCA detector reset');
    } else if (_algorithm == RotationAlgorithm.pca) {
      print('[MAG] ⚠️ PCA algorithm selected but detector is null!');
    }

    notifyListeners();
    print('[MAG] startRecording() complete | _isRecording=$_isRecording');
  }

  /// Stop magnetometer recording (but keep listening for quality feedback)
  void stopRecording() {
    _isRecording = false;
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

    // Update PCA detector wheel circumference if active
    if (_pcaDetector != null) {
      _pcaDetector!.setWheelCircumference(wheelCircumference);
    }

    notifyListeners();
  }

  /// Start listening to sensors (for quality feedback without recording)
  void startListening() {
    if (_isListening) return;

    _isListening = true;
    print('[MAG] 🎧 Started listening | Algorithm: $_algorithm');

    // Initialize PCA detector if using PCA algorithm
    if (_algorithm == RotationAlgorithm.pca && _pcaDetector == null) {
      _pcaDetector = PCARotationDetector();
      _pcaDetector!.setWheelCircumference(_wheelCircumference);
      _pcaDetector!.addListener(_onPCARotationCountChanged);
      _pcaDetector!.start();
      print('[MAG] 🔧 PCA detector initialized and started');
    }

    // Subscribe to magnetometer at ~100Hz
    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen(_onMagnetometerEvent);

    // Uncalibrated magnetometer (Android only; falls back silently elsewhere)
    _uncalibratedMagSubscription = UncalibratedMagnetometer.events.listen(
      _onUncalibratedMagnetometerEvent,
      onError: (e) {
        _uncalibratedSupported = false;
        _uncalibratedError = 'Uncalibrated magnetometer not available: $e';
        print('[MAG] ❌ $_uncalibratedError');
        notifyListeners();
      },
    );

    // Inertial sensors for figure-8 rejection (gyro/accel)
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen((event) {
      _pcaDetector?.updateInertial(null, Vector3(event.x, event.y, event.z));
    });
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen((event) {
      _pcaDetector?.updateInertial(Vector3(event.x, event.y, event.z), null);
    });

    notifyListeners();
  }

  /// Stop listening to sensors completely
  void stopListening() {
    _isListening = false;
    _isRecording = false;
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;
    _uncalibratedMagSubscription?.cancel();
    _uncalibratedMagSubscription = null;
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    // Stop PCA detector if active
    if (_pcaDetector != null) {
      _pcaDetector!.removeListener(_onPCARotationCountChanged);
      _pcaDetector!.stop();
    _pcaDetector = null;
    _uncalibratedActive = false;
    _lastUncalibratedMs = 0;
    }

    notifyListeners();
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

  /// Set rotation detection algorithm
  void setAlgorithm(RotationAlgorithm algorithm) {
    if (_algorithm == algorithm) return;

    final wasListening = _isListening;
    final wasRecording = _isRecording;

    // Stop everything
    if (wasListening) {
      stopListening();
    }

    _algorithm = algorithm;

    // Restart if was listening
    if (wasListening) {
      startListening();
      if (wasRecording) {
        startRecording(
          initialDepth: _currentDepth,
          initialHeading: _currentHeading,
        );
      }
    }

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

    // Throttle UI updates to avoid overwhelming the UI thread
    // Only notify listeners every N samples instead of on every reading
    _samplesSinceUIUpdate++;
    if (_samplesSinceUIUpdate >= _uiUpdateInterval) {
      _samplesSinceUIUpdate = 0;
      notifyListeners();
    }
  }

  void _onUncalibratedMagnetometerEvent(Map<String, double> data) {
    final x = data['x'] ?? 0.0;
    final y = data['y'] ?? 0.0;
    final z = data['z'] ?? 0.0;
    _uncalibratedX = x;
    _uncalibratedY = y;
    _uncalibratedZ = z;
    _uncalibratedMagnitude = sqrt(x * x + y * y + z * z);
    _uncalibratedActive = true;
    _lastUncalibratedMs = DateTime.now().millisecondsSinceEpoch;

    // Feed detectors with uncalibrated data when selected
    if (_algorithm == RotationAlgorithm.pca && _pcaDetector != null) {
      _processPCAAlgorithm(x, y, z);
    } else if (_algorithm == RotationAlgorithm.threshold) {
      _processThresholdAlgorithm(_uncalibratedMagnitude);
    }
  }

  /// Process sample with PCA algorithm
  void _processPCAAlgorithm(double x, double y, double z) {
    if (_pcaDetector == null) return;

    final vector = Vector3(x, y, z);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _pcaDetector!.processSample(vector, timestamp);
  }

  /// Process sample with threshold algorithm
  void _processThresholdAlgorithm(double magnitude) {
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
      // Peak detected - count rotation (only if recording)
      if (_isRecording) {
        _rotationCount++;
        _onRotationDetected();
      }
      _isReadyForNewPeak = false;
      _recentMaxMagnitude = 0.0; // Reset buffer after detection
    } else if (!_isReadyForNewPeak && magnitude < _minPeakThreshold) {
      // Magnitude dropped below minimum - ready for next peak
      _isReadyForNewPeak = true;
      _recentMaxMagnitude = magnitude;
    }
  }

  /// Handle PCA detector rotation count changes
  void _onPCARotationCountChanged() {
    if (_pcaDetector == null) {
      print('[MAG] ⚠️ PCA rotation callback but detector is null');
      return;
    }

    if (!_isRecording) {
      print('[MAG] ⚠️ PCA rotation detected but not recording (listening only)');
      return;
    }

    // Use absolute rotation count since we only care about distance traveled
    final newCount = _pcaDetector!.rotationCount.abs();
    if (newCount > _rotationCount) {
      final rotationsToAdd = newCount - _rotationCount;
      print('[MAG] 🎯 Adding $rotationsToAdd rotation(s): $_rotationCount -> $newCount | Distance: $_currentDistance -> ${_currentDistance + (rotationsToAdd * _wheelCircumference)} m');
      _rotationCount = newCount;

      // Call _onRotationDetected for each new rotation
      for (int i = 0; i < rotationsToAdd; i++) {
        _onRotationDetected();
      }
    }
  }

  /// Handle rotation detection
  void _onRotationDetected() {
    // Note: _rotationCount already incremented by caller

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
