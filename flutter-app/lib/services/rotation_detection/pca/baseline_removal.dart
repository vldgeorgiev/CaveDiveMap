import '../vector3.dart';

/// Removes baseline magnetic field (Earth's field + drift) using
/// Exponential Moving Average (EMA) per axis
class BaselineRemoval {
  double _baselineX = 0.0;
  double _baselineY = 0.0;
  double _baselineZ = 0.0;
  bool _initialized = false;

  /// EMA smoothing factor (0 < alpha < 1)
  /// alpha = dt / (dt + tau) where tau is time constant
  /// With dt = 0.01s (100Hz) and tau = 1s: alpha ≈ 0.01
  /// Smaller alpha = slower baseline tracking (more filtering)
  final double alpha;

  BaselineRemoval({this.alpha = 0.01});

  /// Remove baseline from raw magnetometer reading.
  ///
  /// By default, updates the baseline using the configured EMA [alpha].
  ///
  /// When the wheel/magnet is stationary for a short period, the raw field can
  /// become a near-constant offset. If we keep adapting the baseline at the
  /// normal rate, the baseline will quickly absorb that offset and erase the
  /// magnet signal, which can cause missed counts when rotation resumes.
  ///
  /// Use [freezeBaseline] (or a much smaller [alphaOverride]) during brief
  /// pauses to preserve the magnet signal geometry.
  Vector3 removeBaseline(
    Vector3 reading, {
    bool freezeBaseline = false,
    double? alphaOverride,
  }) {
    if (!_initialized) {
      // Initialize baseline to first reading
      _baselineX = reading.x;
      _baselineY = reading.y;
      _baselineZ = reading.z;
      _initialized = true;
      return Vector3.zero; // First sample returns zero
    }

    if (!freezeBaseline) {
      final effectiveAlpha = alphaOverride ?? alpha;

      // Update baseline with exponential moving average
      _baselineX = effectiveAlpha * reading.x + (1 - effectiveAlpha) * _baselineX;
      _baselineY = effectiveAlpha * reading.y + (1 - effectiveAlpha) * _baselineY;
      _baselineZ = effectiveAlpha * reading.z + (1 - effectiveAlpha) * _baselineZ;
    }

    // Return baseline-subtracted signal
    return Vector3(
      reading.x - _baselineX,
      reading.y - _baselineY,
      reading.z - _baselineZ,
    );
  }

  /// Reset baseline tracking
  void reset() {
    _baselineX = 0.0;
    _baselineY = 0.0;
    _baselineZ = 0.0;
    _initialized = false;
  }

  /// Get current baseline values
  Vector3 get baseline => Vector3(_baselineX, _baselineY, _baselineZ);

  /// Check if baseline is initialized
  bool get isInitialized => _initialized;
}
