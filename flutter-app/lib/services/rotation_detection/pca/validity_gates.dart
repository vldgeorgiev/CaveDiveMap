import 'pca_result.dart';

/// Configuration for validity gate thresholds.
class ValidityGateConfig {
  /// Maximum flatness metric for valid rotation plane.
  ///
  /// Flatness = λ3 / (λ1 + λ2 + λ3)
  /// Range: [0, 0.33], LOWER = more planar (OPPOSITE of old metric!)
  /// - Close to 0.0: Strong planar signal (λ3 << λ1, λ2) - IDEAL
  /// - Close to 0.33: Spherical data (reject)
  ///
  /// Default: 0.30 - tolerant to imperfect alignment while staying planar
  final double maxFlatness;

  /// Hysteresis margin for flatness gate (prevents flickering).
  /// Gate passes at maxFlatness but doesn't fail until maxFlatness + margin.
  final double flatnessHysteresis;

  /// Minimum signal strength for valid magnet detection.
  ///
  /// Signal strength = λ1 (largest eigenvalue in μT²)
  /// Default: 5.0 μT² - lowered for weaker magnets
  final double minSignalStrength;

  /// Maximum signal strength to prevent sensor saturation.
  ///
  /// Signal strength = λ1 (variance in μT²)
  /// If variance is too high, magnetic field might be saturating sensor.
  /// Note: λ1 is variance, so √λ1 gives standard deviation in μT.
  /// Example: λ1=10000 μT² → σ=100 μT variation → likely saturated
  /// Default: 10000.0 μT² (σ≈100 μT) - above this indicates potential saturation
  final double maxSignalStrength;

  /// Maximum rotation frequency to prevent false positives.
  ///
  /// If phase changes faster than this, reject as noise.
  /// Note: Instantaneous frequency spikes are normal in noisy signals,
  /// so this threshold should be high enough to tolerate brief outliers.
  /// Default: 10.0 Hz (600 RPM) - allows brief spikes while rejecting sustained noise
  final double maxRotationFrequencyHz;

  /// Minimum phase change per sample to detect motion.
  ///
  /// If phase is too stable, might be stationary or drifting.
  /// Default: 0.000005 rad/sample - highly sensitive for very slow rotations
  final double minPhaseChangePerSample;

  /// Minimum coherence of signed phase motion.
  ///
  /// Coherence is computed over a recent window as:
  ///   coherence = |ΣΔθ| / Σ|Δθ|  in [0,1]
  ///
  /// - 1.0 means consistent direction
  /// - 0.0 means rapidly changing direction (e.g., figure-8 phone movement)
  ///
  /// Default: 0.40
  final double minCoherence;

  const ValidityGateConfig({
    this.maxFlatness = 0.30,
    this.flatnessHysteresis = 0.05,
    this.minSignalStrength = 5.0,
    this.maxSignalStrength = 10000.0,
    this.maxRotationFrequencyHz = 10.0,
    this.minPhaseChangePerSample = 0.000005,
    this.minCoherence = 0.40,
  });
}

/// Result of validity gate checks.
class ValidityGateResult {
  /// Overall validity: true if all gates pass.
  final bool isValid;

  /// Individual gate results.
  final bool isPlanar;
  final bool hasStrongSignal;
  final bool isWithinFrequencyLimit;
  final bool hasPhaseMotion;
  final bool hasCoherentMotion;

  /// Signal quality score [0.0, 1.0] for UI feedback.
  ///
  /// Computed as weighted average of gate metrics:
  /// - Planarity: 40%
  /// - Signal strength: 40%
  /// - Frequency validity: 20%
  final double qualityScore;

  const ValidityGateResult({
    required this.isValid,
    required this.isPlanar,
    required this.hasStrongSignal,
    required this.isWithinFrequencyLimit,
    required this.hasPhaseMotion,
    required this.hasCoherentMotion,
    required this.qualityScore,
  });

  @override
  String toString() => 'ValidityGateResult('
      'isValid: $isValid, '
      'isPlanar: $isPlanar, '
      'hasStrongSignal: $hasStrongSignal, '
      'withinFreqLimit: $isWithinFrequencyLimit, '
      'hasMotion: $hasPhaseMotion, '
      'coherent: $hasCoherentMotion, '
      'quality: ${(qualityScore * 100).toStringAsFixed(0)}%'
      ')';
}

/// Validates PCA results and phase measurements to prevent false positives.
///
/// Four validity gates:
/// 1. Planarity: Ensures data lies in 2D plane (not linear or spherical)
/// 2. Signal Strength: Ensures magnet is close enough to phone
/// 3. Frequency Limit: Rejects impossibly fast phase changes (noise)
/// 4. Phase Motion: Ensures phase is actually changing (not drift)
class ValidityGates {
  final ValidityGateConfig config;

  /// Sampling rate in Hz (for frequency calculations).
  final double samplingRateHz;

  /// Recent phase change measurements for motion detection.
  final List<double> _recentPhaseChanges = [];
  static const int _phaseChangeHistorySize = 200;  // 2.0s at 100Hz - better for slow rotations

  // Frequency gate debouncing: track recent frequency measurements
  final List<double> _recentFrequencies = [];
  static const int _frequencyHistorySize = 10;  // ~0.1s at 100Hz

  // Coherence gate: track signed phase deltas
  final List<double> _recentSignedPhaseDeltas = [];
  static const int _coherenceHistorySize = 200; // 2.0s at 100Hz
  static const double _coherenceEpsilon = 1e-4;

  // Debug state tracking
  int _qualityCheckCount = 0;
  bool _lastPlanarState = false;
  bool _lastSignalState = false;
  bool _lastFreqState = true;
  bool _lastMotionState = false;
  bool _lastCoherenceState = false;
  bool _lastValidState = false;

  ValidityGates({
    this.config = const ValidityGateConfig(),
    this.samplingRateHz = 100.0,
  });

  /// Check validity of PCA result and phase change.
  ///
  /// [pca]: PCA decomposition result
  /// [phaseChange]: Change in phase since last sample (radians)
  ///
  /// Returns validity result with individual gate outcomes and quality score.
  ValidityGateResult check(PCAResult? pca, double phaseChange) {
    // If PCA failed, reject immediately
    if (pca == null) {
      return const ValidityGateResult(
        isValid: false,
        isPlanar: false,
        hasStrongSignal: false,
        isWithinFrequencyLimit: false,
        hasPhaseMotion: false,
        hasCoherentMotion: false,
        qualityScore: 0.0,
      );
    }

    // Gate 1: Check flatness with hysteresis (LOWER is better!)
    // Use stricter threshold when transitioning to PASS, looser when staying PASS
    final flatnessThreshold = _lastPlanarState
        ? config.maxFlatness + config.flatnessHysteresis  // Looser: stay PASS
        : config.maxFlatness;                              // Stricter: become PASS
    final isPlanar = pca.flatness <= flatnessThreshold;
    if (isPlanar != _lastPlanarState) {
      _lastPlanarState = isPlanar;
      print('[GATE-PLANAR] Changed to ${isPlanar ? "PASS" : "FAIL"} | '
            'flatness=${pca.flatness.toStringAsFixed(3)} (threshold=${flatnessThreshold.toStringAsFixed(3)}, lower=planar)');
    }

    // Gate 2: Check signal strength (both min and max)
    final hasStrongSignal = pca.signalStrength >= config.minSignalStrength &&
                           pca.signalStrength <= config.maxSignalStrength;
    if (hasStrongSignal != _lastSignalState) {
      _lastSignalState = hasStrongSignal;
      print('[GATE-SIGNAL] Changed to ${hasStrongSignal ? "PASS" : "FAIL"} | '
            'strength=${pca.signalStrength.toStringAsFixed(1)} (range=${config.minSignalStrength}-${config.maxSignalStrength})');
    }

    // Gate 3: Check frequency limit (use average to debounce)
    final instantFrequencyHz = phaseChange.abs() * samplingRateHz / (2 * 3.14159);
    _recentFrequencies.add(instantFrequencyHz);
    if (_recentFrequencies.length > _frequencyHistorySize) {
      _recentFrequencies.removeAt(0);
    }
    final avgFrequencyHz = _recentFrequencies.isNotEmpty
        ? _recentFrequencies.reduce((a, b) => a + b) / _recentFrequencies.length
        : instantFrequencyHz;
    final isWithinFrequencyLimit = avgFrequencyHz <= config.maxRotationFrequencyHz;
    if (isWithinFrequencyLimit != _lastFreqState) {
      _lastFreqState = isWithinFrequencyLimit;
      print('[GATE-FREQ] Changed to ${isWithinFrequencyLimit ? "PASS" : "FAIL"} | '
            'avgFreq=${avgFrequencyHz.toStringAsFixed(2)}Hz (instant=${instantFrequencyHz.toStringAsFixed(2)}Hz, max=${config.maxRotationFrequencyHz}Hz)');
    }

    // Gate 4: Check phase motion
    _recentPhaseChanges.add(phaseChange.abs());
    if (_recentPhaseChanges.length > _phaseChangeHistorySize) {
      _recentPhaseChanges.removeAt(0);
    }
    final avgPhaseChange = _recentPhaseChanges.isNotEmpty
        ? _recentPhaseChanges.reduce((a, b) => a + b) / _recentPhaseChanges.length
        : 0.0;
    final hasPhaseMotion = avgPhaseChange >= config.minPhaseChangePerSample;
    if (hasPhaseMotion != _lastMotionState) {
      _lastMotionState = hasPhaseMotion;
      print('[GATE-MOTION] Changed to ${hasPhaseMotion ? "PASS" : "FAIL"} | '
            'avgChange=${avgPhaseChange.toStringAsFixed(5)} (min=${config.minPhaseChangePerSample})');
    }

    // Gate 5: Coherence of signed motion (reject direction-flipping patterns)
    _recentSignedPhaseDeltas.add(phaseChange);
    if (_recentSignedPhaseDeltas.length > _coherenceHistorySize) {
      _recentSignedPhaseDeltas.removeAt(0);
    }
    double sum = 0.0;
    double sumAbs = 0.0;
    for (final d in _recentSignedPhaseDeltas) {
      if (d.abs() < _coherenceEpsilon) continue;
      sum += d;
      sumAbs += d.abs();
    }
    final coherence = sumAbs > 0 ? (sum.abs() / sumAbs).clamp(0.0, 1.0) : 0.0;
    final hasCoherentMotion = coherence >= config.minCoherence;
    if (hasCoherentMotion != _lastCoherenceState) {
      _lastCoherenceState = hasCoherentMotion;
      print('[GATE-COHERENCE] Changed to ${hasCoherentMotion ? "PASS" : "FAIL"} | '
            'coherence=${coherence.toStringAsFixed(2)} (min=${config.minCoherence.toStringAsFixed(2)})');
    }

    // Compute quality score [0.0, 1.0]
    // Flatness: lower is better, so invert it (1.0 - flatness/0.33)
    final planarityScore = (1.0 - pca.flatness / 0.33).clamp(0.0, 1.0);
    final signalScore = (pca.signalStrength / 100.0).clamp(0.0, 1.0);
    final frequencyScore = isWithinFrequencyLimit ? 1.0 : 0.0;
    final coherenceScore = coherence;

    final qualityScore = 0.30 * planarityScore +
               0.40 * signalScore +
               0.20 * coherenceScore +
               0.10 * frequencyScore;

    // Debug: Log quality breakdown occasionally
    _qualityCheckCount++;
    if (_qualityCheckCount % 50 == 0) {
      print('[QUALITY] Flatness=${planarityScore.toStringAsFixed(3)}(${pca.flatness.toStringAsFixed(3)}) '
            'Signal=${signalScore.toStringAsFixed(3)}(${pca.signalStrength.toStringAsFixed(1)}) '
            'Freq=${frequencyScore.toStringAsFixed(1)}(${avgFrequencyHz.toStringAsFixed(2)}Hz) '
            '→ Total=${qualityScore.toStringAsFixed(3)} (${(qualityScore * 100).toStringAsFixed(0)}%)');
    }

    // Overall validity: all gates must pass
    final isValid = isPlanar &&
             hasStrongSignal &&
             isWithinFrequencyLimit &&
             hasPhaseMotion &&
             hasCoherentMotion;

    final result = ValidityGateResult(
      isValid: isValid,
      isPlanar: isPlanar,
      hasStrongSignal: hasStrongSignal,
      isWithinFrequencyLimit: isWithinFrequencyLimit,
      hasPhaseMotion: hasPhaseMotion,
      hasCoherentMotion: hasCoherentMotion,
      qualityScore: qualityScore,
    );

    // Debug: Log detailed gate info when validity changes
    if (isValid != _lastValidState) {
      _lastValidState = isValid;
      print('[VALIDITY] Gates: Planar=${isPlanar}(flatness=${pca.flatness.toStringAsFixed(3)}) '
            'Signal=${hasStrongSignal}(${pca.signalStrength.toStringAsFixed(1)}) '
            'Freq=${isWithinFrequencyLimit}(${avgFrequencyHz.toStringAsFixed(2)}Hz) '
        'Motion=${hasPhaseMotion}(${avgPhaseChange.toStringAsFixed(4)}) '
        'Coherence=${hasCoherentMotion}(${coherence.toStringAsFixed(2)}) '
            '→ Valid=${isValid}');
    }

    return result;
  }

  /// Reset phase motion history.
  void reset() {
    _recentPhaseChanges.clear();
    _recentFrequencies.clear();
    _recentSignedPhaseDeltas.clear();
    _lastValidState = false;
    _qualityCheckCount = 0;
    _lastPlanarState = false;
    _lastSignalState = false;
    _lastFreqState = true;
    _lastMotionState = false;
    _lastCoherenceState = false;
  }
}
