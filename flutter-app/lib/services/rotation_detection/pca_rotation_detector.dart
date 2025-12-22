import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'vector3.dart';
import 'vector2.dart';
import 'pca/baseline_removal.dart';
import 'pca/pca_computer.dart';
import 'pca/pca_result.dart';
import 'pca/phase_tracking.dart';
import 'pca/sliding_window_buffer.dart';
import 'pca/validity_gates.dart';

/// Configuration for PCA-based rotation detection.
class PCARotationConfig {
  /// Sampling rate of magnetometer in Hz.
  final double samplingRateHz;

  /// Sliding window size in seconds for PCA computation.
  final double windowSizeSeconds;

  /// Baseline removal alpha (EMA smoothing factor).
  final double baselineAlpha;

  /// Validity gate configuration.
  final ValidityGateConfig validityConfig;

  const PCARotationConfig({
    this.samplingRateHz = 100.0,
    this.windowSizeSeconds = 2.0,
    this.baselineAlpha = 0.01,
    this.validityConfig = const ValidityGateConfig(),
  });
}

/// PCA-based rotation detection algorithm.
///
/// Detects wheel rotations by measuring 2π phase advances in the
/// magnetometer signal. Each complete 2π cycle = one rotation.
///
/// Processing pipeline:
/// 1. Baseline Removal: Subtract Earth's magnetic field + drift
/// 2. Sliding Window: Maintain recent samples for PCA
/// 3. PCA Computation: Find rotation plane (PC2, PC3)
/// 4. Projection: Project to 2D rotation plane coordinates
/// 5. Phase Computation: θ(t) = atan2(v, u)
/// 6. Phase Unwrapping: Detect 2π cycles
/// 7. Validity Gating: Filter false positives
/// 8. Rotation Counting: Increment count on valid 2π advances
class PCARotationDetector extends ChangeNotifier {
  final PCARotationConfig config;

  // Pipeline components
  late final BaselineRemoval _baselineRemoval;
  late final SlidingWindowBuffer _slidingWindow;
  late final PCAComputer _pcaComputer;
  late final PCAProjector _projector;
  late final PhaseComputer _phaseComputer;
  late final PhaseUnwrapper _phaseUnwrapper;
  late final ValidityGates _validityGates;

  // State
  int _rotationCount = 0;
  int _maxAbsRotationCount = 0;  // Track max absolute count to prevent oscillation
  PCAResult? _latestPCA;
  ValidityGateResult? _latestValidity;
  double _lastPhase = 0.0;
  bool _isActive = false;
  int _debugSampleCount = 0; // For debug logging throttle
  Vector2 _lastProjected = const Vector2(0, 0); // For debug output

  PCARotationDetector({this.config = const PCARotationConfig()}) {
    _baselineRemoval = BaselineRemoval(alpha: config.baselineAlpha);
    _slidingWindow = SlidingWindowBuffer(
      windowSizeSeconds: config.windowSizeSeconds,
      samplingRateHz: config.samplingRateHz,
    );
    _pcaComputer = PCAComputer();
    _projector = PCAProjector();
    _phaseComputer = PhaseComputer();
    _phaseUnwrapper = PhaseUnwrapper();
    _validityGates = ValidityGates(
      config: config.validityConfig,
      samplingRateHz: config.samplingRateHz,
    );
  }

  /// Process new magnetometer reading.
  ///
  /// [reading]: Raw magnetometer reading (x, y, z) in μT
  /// [timestamp]: Sample timestamp in milliseconds
  void processSample(Vector3 reading, int timestamp) {
    if (!_isActive) return;

    // Step 1: Remove baseline (Earth's field + drift)
    final corrected = _baselineRemoval.removeBaseline(reading);

    // Debug: Log raw and corrected values occasionally
    _debugSampleCount++;
    if (_debugSampleCount % 100 == 0) {
      final rawMag = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      final corrMag = sqrt(corrected.x * corrected.x + corrected.y * corrected.y + corrected.z * corrected.z);
      print('[PCA-RAW] Raw: (${reading.x.toStringAsFixed(1)}, ${reading.y.toStringAsFixed(1)}, ${reading.z.toStringAsFixed(1)}) mag=${rawMag.toStringAsFixed(1)} μT | '
            'Corrected: (${corrected.x.toStringAsFixed(1)}, ${corrected.y.toStringAsFixed(1)}, ${corrected.z.toStringAsFixed(1)}) mag=${corrMag.toStringAsFixed(1)} μT');
    }

    // Step 2: Add to sliding window
    _slidingWindow.add(corrected, timestamp);

    // Wait until window is full
    if (!_slidingWindow.isFull) {
      return;
    }

    // Step 3: Compute PCA on windowed samples
    final samples = _slidingWindow.samples;
    _latestPCA = _pcaComputer.compute(samples);

    if (_latestPCA == null) {
      // PCA failed (degenerate data)
      _latestValidity = null;
      return;
    }

    // Step 4: Project latest sample to rotation plane
    final projected = _projector.project(corrected, _latestPCA!);
    _lastProjected = projected;

    // Step 5: Compute phase angle
    final phase = _phaseComputer.computePhase(projected);

    // Step 6: Unwrap phase and detect rotations
    final phaseChange = phase - _lastPhase;
    final unwrappedPhase = _phaseUnwrapper.unwrap(phase);
    final rotCountBefore = _phaseUnwrapper.rotationCount;
    _lastPhase = phase;

    // Debug: Log phase evolution every 20 samples
    if (_debugSampleCount % 20 == 0) {
      print('[PCA-PHASE] Phase: ${(phase * 180 / 3.14159).toStringAsFixed(1)}° | '
            'Change: ${(phaseChange * 180 / 3.14159).toStringAsFixed(1)}° | '
            'Unwrapped: ${(unwrappedPhase * 180 / 3.14159).toStringAsFixed(1)}° | '
            'RotCount: $rotCountBefore');
    }

    // Step 7: Validate signal quality
    _latestValidity = _validityGates.check(_latestPCA, phaseChange);

    // Debug: Log PCA metrics every 50 samples
    _debugSampleCount++;
    if (_debugSampleCount % 50 == 0) {
      final eigenvalues = _latestPCA!.eigenvalues;
      final isSaturated = _latestPCA!.signalStrength > 10000.0;
      final signalStdDev = sqrt(_latestPCA!.signalStrength);
      final lambda2Ratio = eigenvalues[1] / eigenvalues[0];
      final lambda3Ratio = eigenvalues[2] / eigenvalues[0];
      final baselineMag = sqrt(baseline.x * baseline.x + baseline.y * baseline.y + baseline.z * baseline.z);

      print('[PCA] Quality: ${(signalQuality * 100).toStringAsFixed(1)}% | '
            'Flatness: ${_latestPCA!.flatness.toStringAsFixed(3)} (${_latestValidity!.isPlanar ? "✓ planar" : "✗ spherical"}) | '
            'Signal: ${_latestPCA!.signalStrength.toStringAsFixed(2)} μT² (σ=${signalStdDev.toStringAsFixed(1)} μT) (${_latestValidity!.hasStrongSignal ? "✓" : "✗"})${isSaturated ? " [SAT!]" : ""} | '
            'Valid: ${_latestValidity!.isValid ? "✓" : "✗"} | '
            'Rotations: $_rotationCount');
      print('[PCA-EIGENVALUES] λ1=${eigenvalues[0].toStringAsFixed(2)} λ2=${eigenvalues[1].toStringAsFixed(2)} λ3=${eigenvalues[2].toStringAsFixed(2)} | '
            'λ2/λ1=${lambda2Ratio.toStringAsFixed(3)} λ3/λ1=${lambda3Ratio.toStringAsFixed(3)} | '
            'Baseline: ${baselineMag.toStringAsFixed(1)} μT | '
            'Window: ${(_slidingWindow.samples.length)}/${(config.windowSizeSeconds * config.samplingRateHz).round()} samples');
    }

    // Step 8: Update rotation count based on phase progression
    // Don't require perfect validity - allow counting during brief interruptions
    // as long as signal quality is decent (flatness OK + signal strong enough)
    final canCount = _latestValidity!.isPlanar && _latestValidity!.hasStrongSignal;

    if (canCount) {
      final newCount = _phaseUnwrapper.rotationCount;
      final absCount = newCount.abs();

      // Only notify if absolute count increased (prevents oscillation from triggering callbacks)
      if (absCount > _maxAbsRotationCount) {
        final phaseDeg = phase * 180 / 3.14159;
        final unwrappedDeg = _phaseUnwrapper.totalPhase * 180 / 3.14159;
        final phaseDelta = (phase - _lastPhase) * 180 / 3.14159;
        final validStr = _latestValidity!.isValid ? "✓" : "⚠️";
        print('[PCA] 🎯 ROTATION DETECTED! Count: $newCount (abs=$absCount, was ${_maxAbsRotationCount}) $validStr | '
              'Phase: ${phaseDeg.toStringAsFixed(1)}° (Δ=${phaseDelta.toStringAsFixed(1)}°) | '
              'Unwrapped: ${unwrappedDeg.toStringAsFixed(1)}° | '
              'Projected: (${_lastProjected.x.toStringAsFixed(2)}, ${_lastProjected.y.toStringAsFixed(2)})');
        _maxAbsRotationCount = absCount;
        _rotationCount = newCount;  // Keep raw count for reference
        notifyListeners();
      } else {
        // Update raw count but don't notify (oscillation)
        _rotationCount = newCount;
      }
    }
  }

  /// Current rotation count.
  int get rotationCount => _rotationCount;

  /// Latest PCA result (for debugging/diagnostics).
  PCAResult? get latestPCA => _latestPCA;

  /// Latest validity gate result (for UI feedback).
  ValidityGateResult? get latestValidity => _latestValidity;

  /// Signal quality score [0.0, 1.0] for UI indicators.
  double get signalQuality => _latestValidity?.qualityScore ?? 0.0;

  /// Whether detector is currently active.
  bool get isActive => _isActive;

  /// Start rotation detection.
  void start() {
    if (_isActive) return;
    _isActive = true;
    reset();
    notifyListeners();
  }

  /// Stop rotation detection.
  void stop() {
    if (!_isActive) return;
    _isActive = false;
    notifyListeners();
  }

  /// Reset all state (rotation count, buffers, etc.).
  void reset() {
    _rotationCount = 0;
    _latestPCA = null;
    _latestValidity = null;
    _lastPhase = 0.0;
    _baselineRemoval.reset();
    _slidingWindow.clear();
    _phaseUnwrapper.reset();
    _validityGates.reset();
    notifyListeners();
  }

  /// Get current Earth's magnetic field baseline (for diagnostics).
  Vector3 get baseline => _baselineRemoval.baseline;

  /// Get current window fill percentage [0.0, 1.0].
  double get windowFillPercentage {
    final capacity = (config.windowSizeSeconds * config.samplingRateHz).round();
    return _slidingWindow.samples.length / capacity;
  }
}
