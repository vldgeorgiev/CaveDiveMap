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

  /// Remove baseline from raw magnetometer reading
  /// Returns baseline-subtracted signal
  Vector3 removeBaseline(Vector3 reading) {
    if (!_initialized) {
      // Initialize baseline to first reading
      _baselineX = reading.x;
      _baselineY = reading.y;
      _baselineZ = reading.z;
      _initialized = true;
      return Vector3.zero; // First sample returns zero
    }

    // Update baseline with exponential moving average
    _baselineX = alpha * reading.x + (1 - alpha) * _baselineX;
    _baselineY = alpha * reading.y + (1 - alpha) * _baselineY;
    _baselineZ = alpha * reading.z + (1 - alpha) * _baselineZ;

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
