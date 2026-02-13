import 'dart:math' show sqrt, atan2;
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

  /// Minimum fraction of the sliding window that must be populated before PCA
  /// is computed. This reduces startup latency so early rotations aren't missed.
  ///
  /// Example: windowSizeSeconds=1.0 @ 100Hz => capacity≈100 samples.
  /// minWindowFillFraction=0.2 => start after ≈20 samples (~0.2s).
  /// Aggressive fill reduces startup delay from ~0.5s to ~0.2s.
  final double minWindowFillFraction;

  /// Baseline removal alpha (EMA smoothing factor).
  final double baselineAlpha;

  /// Baseline removal alpha to use when signal is strong but phase motion is low
  /// (brief stop/slowdown). Using a much smaller alpha prevents the baseline
  /// filter from absorbing the stationary magnet field and losing the signal
  /// when rotation resumes.
  final double pausedBaselineAlpha;

  /// How long (ms) we keep allowing counts after planarity briefly fails while
  /// signal remains strong. This improves counting when rotation is jerky.
  final int planarGraceMs;

  /// How long (ms) we keep allowing counts after inertial gate fails.
  /// Provides tolerance for gentle translation (e.g., phone moving forward with the wheel)
  /// while still rejecting sustained figure-8 or large handset motion.
  final int inertialGraceMs;

  /// Maximum allowable gyro magnitude (rad/s) before rejecting due to large
  /// handset motion (e.g., figure-8 swings).
  final double maxGyroRadPerSec;

  /// Maximum allowable accelerometer standard deviation (m/s^2) over the recent
  /// window before rejecting due to excessive linear motion.
  final double maxAccelStdDev;

  /// Minimum phase advance (radians) before emitting distance update callback.
  /// Examples:
  /// - π/18 ≈ 10° rotations (frequent updates)
  /// - π/9 ≈ 20° rotations (default - good balance)
  /// - π/6 ≈ 30° rotations (less frequent)
  final double minPhaseForDistanceUpdate;

  /// Validity gate configuration.
  final ValidityGateConfig validityConfig;

    const PCARotationConfig({
    this.samplingRateHz = 100.0,
    this.windowSizeSeconds = 1.0,
    this.minWindowFillFraction = 0.2,
    this.baselineAlpha = 0.02,
    this.pausedBaselineAlpha = 0.001,
    this.planarGraceMs = 1200,
    this.inertialGraceMs = 800,
    this.maxGyroRadPerSec = 6.0,
    this.maxAccelStdDev = 4.0,
    this.minPhaseForDistanceUpdate = 3.141592653589793 / 9, // π/9 ≈ 20°
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
  final List<double> _recentGyroMagnitudes = [];
  final List<double> _recentAccelMagnitudes = [];
  static const int _inertialHistorySize = 100; // ~1s at 100Hz

  // State
  int _rotationCount = 0; // emitted forward count (for consumers)
  int _forwardCount = 0;  // internal forward emissions
  double _forwardPhaseAccum = 0.0; // cumulative positive phase (rad) for forward counts only
  double _totalForwardPhase = 0.0; // continuous total phase (not reduced by 2π) for fractional tracking
  int _forwardSign = 0; // +1/-1 once direction is learned, 0 = unknown
  int _startTimestampMs = 0; // Track time since start for graduated quality threshold
  PCAResult? _latestPCA;
  PCAResult? _lockedPCA;
  ValidityGateResult? _latestValidity;
  double _lastPhase = 0.0;
  bool _isActive = false;
  int _debugSampleCount = 0; // For debug logging throttle
  Vector2 _lastProjected = const Vector2(0, 0); // For debug output
  double _lastEmittedPhase = 0.0; // Last phase value when distance update was emitted
  double _wheelCircumference = 0.263; // meters, default for typical measurement wheel

  /// Callback fired when distance advances by configured phase interval.
  /// Use this to update UI or trigger survey point creation at fractional rotations.
  Function()? onDistanceUpdate;

  int _lastPlanarStrongTimestampMs = 0;
  int _lastBasisUpdateMs = 0;
  double _lockedFlatness = 1.0;
  int _lastInertialOkMs = 0;

  // PCA basis stabilization (eigenvectors can flip sign and/or swap when
  // eigenvalues are close). Keeping a continuous basis is critical for stable
  // phase tracking, especially for slow or jerky motion.
  Vector3? _prevPc1;
  Vector3? _prevPc2;
  Vector3? _prevNormal;

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

  /// Update inertial buffers (gyro/accelerometer).
  void updateInertial(Vector3? accel, Vector3? gyro) {
    if (gyro != null) {
      _recentGyroMagnitudes.add(gyro.magnitude);
      if (_recentGyroMagnitudes.length > _inertialHistorySize) {
        _recentGyroMagnitudes.removeAt(0);
      }
    }

    if (accel != null) {
      _recentAccelMagnitudes.add(accel.magnitude);
      if (_recentAccelMagnitudes.length > _inertialHistorySize) {
        _recentAccelMagnitudes.removeAt(0);
      }
    }
  }

  bool get _inertialOk {
    if (_recentGyroMagnitudes.isEmpty && _recentAccelMagnitudes.isEmpty) {
      return true; // no data, skip gating
    }

    final gyroMax = _recentGyroMagnitudes.isNotEmpty
        ? _recentGyroMagnitudes.reduce((a, b) => a > b ? a : b)
        : 0.0;
    if (gyroMax > config.maxGyroRadPerSec) {
      return false;
    }

    if (_recentAccelMagnitudes.length >= 2) {
      final accelAvg = _recentAccelMagnitudes.reduce((a, b) => a + b) / _recentAccelMagnitudes.length;
      double variance = 0.0;
      for (final v in _recentAccelMagnitudes) {
        final d = v - accelAvg;
        variance += d * d;
      }
      variance /= _recentAccelMagnitudes.length;
      final stddev = sqrt(variance);
      if (stddev > config.maxAccelStdDev) {
        return false;
      }
    }

    return true;
  }

  /// Process new magnetometer reading.
  ///
  /// [reading]: Raw magnetometer reading (x, y, z) in μT
  /// [timestamp]: Sample timestamp in milliseconds
  void processSample(Vector3 reading, int timestamp) {
    if (!_isActive) return;

    // Track start time for graduated quality threshold
    if (_startTimestampMs == 0) {
      _startTimestampMs = timestamp;
    }

    // Step 1: Remove baseline (Earth's field + drift)
    // IMPORTANT: during brief pauses, the magnet field can become a constant
    // offset and a fast baseline filter (alpha≈0.01) will adapt to it within
    // ~1s, effectively erasing the magnet signal. Slow baseline adaptation
    // during these pauses to improve interrupted-rotation counting.
    final lastValidity = _latestValidity;
    final shouldSlowBaseline = lastValidity != null &&
        lastValidity.hasStrongSignal &&
        !lastValidity.hasPhaseMotion;
    final corrected = _baselineRemoval.removeBaseline(
      reading,
      alphaOverride: shouldSlowBaseline ? config.pausedBaselineAlpha : null,
    );

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

    // Wait until we have enough samples to compute a stable PCA.
    final capacity = (config.windowSizeSeconds * config.samplingRateHz).round();
    final minSamples = (capacity * config.minWindowFillFraction)
        .clamp(3, capacity)
        .round();
    if (_slidingWindow.length < minSamples) {
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

    // Stabilize eigenvector basis to avoid phase resets/jumps.
    _latestPCA = _stabilizePcaBasis(_latestPCA!);

    // Lock or refresh PCA basis for projection to avoid basis drift.
    final nowMs = timestamp;
    final shouldRelock = _lockedPCA == null ||
        _latestPCA!.flatness + config.validityConfig.flatnessHysteresis < _lockedFlatness ||
        (_lockedFlatness > config.validityConfig.maxFlatness + config.validityConfig.flatnessHysteresis &&
            nowMs - _lastBasisUpdateMs > 500);
    if (shouldRelock) {
      _lockedPCA = _latestPCA;
      _lockedFlatness = _latestPCA!.flatness;
      _lastBasisUpdateMs = nowMs;
      // Align sign with previous locked normal to keep continuity
      if (_prevNormal != null) {
        final newNormal = _cross(_lockedPCA!.pc1, _lockedPCA!.pc2);
        if (newNormal.dot(_prevNormal!) < 0) {
          _lockedPCA = PCAResult(
            eigenvalues: _lockedPCA!.eigenvalues,
            mean: _lockedPCA!.mean,
            eigenvectors: [
              _lockedPCA!.pc1 * -1,
              _lockedPCA!.pc2 * -1,
              _lockedPCA!.pc3 * -1,
            ],
          );
        }
      }
      _prevNormal = _cross(_lockedPCA!.pc1, _lockedPCA!.pc2);
      _prevPc1 = _lockedPCA!.pc1;
      _prevPc2 = _lockedPCA!.pc2;
    }

    final projectionBasis = _lockedPCA ?? _latestPCA!;

    // Step 4: Project latest sample to rotation plane
    final projected = _projector.project(corrected, projectionBasis);
    _lastProjected = projected;

    // Step 5: Compute phase angle
    final phase = _phaseComputer.computePhase(projected);

    // Step 6: Unwrap phase and detect rotations
    // Use wrap-corrected delta for gates (frequency/motion/coherence).
    double phaseChange = phase - _lastPhase;
    if (phaseChange > 3.141592653589793) {
      phaseChange -= 2 * 3.141592653589793;
    } else if (phaseChange < -3.141592653589793) {
      phaseChange += 2 * 3.141592653589793;
    }
    final unwrappedPhase = _phaseUnwrapper.advanceDelta(phaseChange);
    final rotCountBefore = _phaseUnwrapper.rotationCount;
    _lastPhase = phase;

    // Debug: Log phase evolution occasionally
    if (_debugSampleCount % 40 == 0) {
      print('[PCA-PHASE] phase=${(phase * 180 / 3.14159).toStringAsFixed(1)}° '
            'dphi=${(phaseChange * 180 / 3.14159).toStringAsFixed(1)}° '
            'unwrap=${(unwrappedPhase * 180 / 3.14159).toStringAsFixed(1)}° '
            'rot=${rotCountBefore}');
    }

    // Step 7: Validate signal quality
    _latestValidity = _validityGates.check(_latestPCA, phaseChange);

    if (_latestValidity!.isPlanar && _latestValidity!.hasStrongSignal) {
      _lastPlanarStrongTimestampMs = timestamp;
    }

    // Debug: Log PCA metrics every 50 samples
    if (_debugSampleCount % 80 == 0) {
      final eigenvalues = _latestPCA!.eigenvalues;
      final signalStdDev = sqrt(_latestPCA!.signalStrength);
      final lambda2Ratio = eigenvalues[1] / eigenvalues[0];
      final lambda3Ratio = eigenvalues[2] / eigenvalues[0];
      final baselineMag = sqrt(baseline.x * baseline.x + baseline.y * baseline.y + baseline.z * baseline.z);
      print('[PCA] q=${(signalQuality * 100).toStringAsFixed(1)}% '
            'flat=${_latestPCA!.flatness.toStringAsFixed(3)}(${_latestValidity!.isPlanar ? "P" : "NP"}) '
            'sig=${_latestPCA!.signalStrength.toStringAsFixed(1)}(σ=${signalStdDev.toStringAsFixed(1)}) '
            'freqOk=${_latestValidity!.isWithinFrequencyLimit ? "Y" : "N"} '
            'motion=${_latestValidity!.hasPhaseMotion ? "Y" : "N"} '
            'rot=$_rotationCount '
            'base=${baselineMag.toStringAsFixed(1)} '
            'win=${_slidingWindow.samples.length}/${(config.windowSizeSeconds * config.samplingRateHz).round()} '
            'λ=${eigenvalues[0].toStringAsFixed(0)},${eigenvalues[1].toStringAsFixed(0)},${eigenvalues[2].toStringAsFixed(0)} '
            'λr=${lambda2Ratio.toStringAsFixed(3)},${lambda3Ratio.toStringAsFixed(3)}');
    }

    // Step 8: Update rotation count based on phase progression.
    // Require planarity + coherence, allow short planarity dropouts, and reject
    // when inertial sensors show large device motion. Always accumulate phase;
    // emit when gates pass.
    final withinPlanarGrace = _lastPlanarStrongTimestampMs != 0 &&
        (timestamp - _lastPlanarStrongTimestampMs) <= config.planarGraceMs;
    final inertialOkNow = _inertialOk;
    if (inertialOkNow) {
      _lastInertialOkMs = timestamp;
    }
    final withinInertialGrace = _lastInertialOkMs != 0 &&
        (timestamp - _lastInertialOkMs) <= config.inertialGraceMs;

    // Graduated quality threshold: lower during first 2 seconds to catch early rotations
    final timeSinceStart = timestamp - _startTimestampMs;
    final qualityThreshold = (timeSinceStart < 2000) ? 0.45 : 0.60;

    final canEmit = _latestValidity!.qualityScore > qualityThreshold &&
        _latestValidity!.isWithinFrequencyLimit &&
        (_latestValidity!.isPlanar || withinPlanarGrace) &&
        _latestValidity!.hasPhaseMotion &&
        _latestValidity!.hasCoherentMotion &&
        _latestValidity!.hasStrongSignal &&
        (inertialOkNow || withinInertialGrace); // reject sustained figure-8 / large handset motion, allow gentle translation

    // Learn which direction is "forward" from the first stable motion (planar + coherent).
    // OPTIMIZATION: Don't reset accumulators - retroactively count initial rotations.
    if (_forwardSign == 0 &&
        _latestValidity != null &&
        _latestValidity!.hasPhaseMotion &&
        phaseChange.abs() > 0.02) {
      _forwardSign = phaseChange > 0 ? 1 : -1;
      // Don't reset accumulators - keep accumulated phase from initial motion
      // This allows counting rotations that occurred before direction was learned
    }

    // Accumulate only forward-directed phase (relative to learned sign).
    // CRITICAL: Only accumulate fractional phase when validity gates pass (canEmit).
    // This prevents distance accumulation from noise, invalid signals, or stationary phone.
    final signedPhaseChange =
        _forwardSign == 0 ? phaseChange : phaseChange * _forwardSign;
    if (signedPhaseChange > 0) {
      _forwardPhaseAccum += signedPhaseChange; // Always accumulate for integer count
      // Only accumulate fractional distance during valid signals
      if (canEmit) {
        _totalForwardPhase += signedPhaseChange;
      }
    }
    final twoPi = 2 * 3.141592653589793;
    int pendingForward = 0;
    if (canEmit) {
      pendingForward = (_forwardPhaseAccum / twoPi).floor();
    }

    // Debug: show why counts may be blocked
    if (_debugSampleCount % 100 == 0) {
      print('[PCA-EMIT] canEmit=$canEmit '
            'sign=$_forwardSign '
            'accum=${_forwardPhaseAccum.toStringAsFixed(2)}rad '
            'pending=$pendingForward '
            'q=${_latestValidity!.qualityScore.toStringAsFixed(2)} '
            'planar=${_latestValidity!.isPlanar} '
            'phaseMotion=${_latestValidity!.hasPhaseMotion} '
            'coherent=${_latestValidity!.hasCoherentMotion} '
            'strong=${_latestValidity!.hasStrongSignal} '
            'inertialOk=$inertialOkNow grace=$withinInertialGrace');
    }

    if (pendingForward > 0) {
      _forwardPhaseAccum -= pendingForward * twoPi;
      _forwardCount += pendingForward;
      _rotationCount = _forwardCount; // expose forward-only
      final phaseDeg = phase * 180 / 3.14159;
      final unwrappedDeg = _phaseUnwrapper.totalPhase * 180 / 3.14159;
      print('[PCA] 🎯 ROTATION DETECTED! ForwardCount: $_forwardCount (pending=+$pendingForward) ✓ | '
            'Phase: ${phaseDeg.toStringAsFixed(1)}° | '
            'Unwrapped: ${unwrappedDeg.toStringAsFixed(1)}° | '
            'Projected: (${_lastProjected.x.toStringAsFixed(2)}, ${_lastProjected.y.toStringAsFixed(2)})');
      notifyListeners();
    }

    // Step 9: Check for fractional distance update (partial rotation callback)
    if (canEmit) {
      final phaseAdvance = (_totalForwardPhase - _lastEmittedPhase).abs();
      if (phaseAdvance >= config.minPhaseForDistanceUpdate) {
        _lastEmittedPhase = _totalForwardPhase;
        onDistanceUpdate?.call();
        // Note: notifyListeners() already called above for rotation count
      }
    }
  }

  /// Current rotation count (integer rotations only).
  int get rotationCount => _rotationCount;

  /// Fractional rotations including partial rotations.
  ///
  /// Returns the total phase advance divided by 2π, representing
  /// complete + partial rotations. Examples:
  /// - 0.5 = half rotation (180°)
  /// - 1.25 = one and a quarter rotations (450°)
  /// - 2.0 = exactly two complete rotations
  ///
  /// This enables distance measurement at any point during rotation,
  /// not just at 2π boundaries. Respects all validity gates - only
  /// advances when signal is valid.
  double get fractionalRotations {
    return _totalForwardPhase.abs() / (2 * 3.141592653589793);
  }

  /// Continuous distance traveled (meters) including partial rotations.
  ///
  /// Computed as fractionalRotations × wheelCircumference.
  /// Updates smoothly during rotation rather than in discrete steps.
  /// Set wheel circumference via [setWheelCircumference].
  double get continuousDistance {
    return fractionalRotations * _wheelCircumference;
  }

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

  /// Set wheel circumference for distance calculations.
  ///
  /// [circumference]: Wheel circumference in meters
  void setWheelCircumference(double circumference) {
    _wheelCircumference = circumference;
  }

  /// Reset all state (rotation count, buffers, etc.).
  void reset() {
    _rotationCount = 0;
    _forwardCount = 0;
    _forwardPhaseAccum = 0.0;
    _totalForwardPhase = 0.0;
    _forwardSign = 0;
    _lastEmittedPhase = 0.0;
    _startTimestampMs = 0;
    _latestPCA = null;
    _lockedPCA = null;
    _latestValidity = null;
    _lastPhase = 0.0;
    _baselineRemoval.reset();
    _slidingWindow.clear();
    _phaseUnwrapper.reset();
    _validityGates.reset();
    _lastPlanarStrongTimestampMs = 0;
    _prevPc1 = null;
    _prevPc2 = null;
    _prevNormal = null;
    _lastBasisUpdateMs = 0;
    _lockedFlatness = 1.0;
    _lastInertialOkMs = 0;
    _recentGyroMagnitudes.clear();
    _recentAccelMagnitudes.clear();
    notifyListeners();
  }

  PCAResult _stabilizePcaBasis(PCAResult pca) {
    final prev1 = _prevPc1;
    final prev2 = _prevPc2;
    if (prev1 == null || prev2 == null) {
      _prevPc1 = pca.pc1;
      _prevPc2 = pca.pc2;
      _prevNormal = _cross(pca.pc1, pca.pc2);
      return pca;
    }

    final c1 = pca.pc1;
    final c2 = pca.pc2;

    // Candidates: (pc1,pc2) and swapped (pc2,pc1), each with independent sign flips.
    final candidates = <(Vector3, Vector3)>[];
    for (final (a, b) in <(Vector3, Vector3)>[(c1, c2), (c2, c1)]) {
      for (final sa in <double>[1.0, -1.0]) {
        for (final sb in <double>[1.0, -1.0]) {
          candidates.add((a * sa, b * sb));
        }
      }
    }

    double bestScore = double.negativeInfinity;
    (Vector3, Vector3) best = (c1, c2);
    for (final cand in candidates) {
      final a = cand.$1;
      final b = cand.$2;
      // Maximize signed alignment to keep directions continuous.
      final score = a.dot(prev1) + b.dot(prev2);
      if (score > bestScore) {
        bestScore = score;
        best = cand;
      }
    }

    var pc1 = best.$1;
    var pc2 = best.$2;

    // Keep plane normal direction consistent when possible.
    final normal = _cross(pc1, pc2);
    final prevNormal = _prevNormal;
    if (prevNormal != null && normal.dot(prevNormal) < 0) {
      pc2 = pc2 * -1.0;
    }

    _prevPc1 = pc1;
    _prevPc2 = pc2;
    _prevNormal = _cross(pc1, pc2);

    return PCAResult(
      eigenvalues: pca.eigenvalues,
      eigenvectors: [pc1, pc2, pca.pc3],
      mean: pca.mean,
    );
  }

  Vector3 _cross(Vector3 a, Vector3 b) {
    return Vector3(
      a.y * b.z - a.z * b.y,
      a.z * b.x - a.x * b.z,
      a.x * b.y - a.y * b.x,
    );
  }

  /// Get current Earth's magnetic field baseline (for diagnostics).
  Vector3 get baseline => _baselineRemoval.baseline;

  /// Get current window fill percentage [0.0, 1.0].
  double get windowFillPercentage {
    final capacity = (config.windowSizeSeconds * config.samplingRateHz).round();
    return _slidingWindow.samples.length / capacity;
  }
}
