import 'dart:math';
import '../vector2.dart';
import '../vector3.dart';
import 'pca_result.dart';

/// Projects 3D magnetometer vectors onto 2D rotation plane.
///
/// Uses PCA eigenvectors PC1 and PC2 to define the rotation plane basis.
/// CRITICAL: Eigenvalues sorted descending means PC1 and PC2 are IN the plane!
///
/// Projection formula:
///   u = (B - μ) · PC1  (major axis)
///   v = (B - μ) · PC2  (minor axis)
///
/// Where:
/// - B: Magnetometer reading
/// - μ: Mean of samples (from PCA)
/// - PC1, PC2: Eigenvectors spanning rotation plane (λ1, λ2 >> λ3)
class PCAProjector {
  /// Project magnetometer reading onto rotation plane.
  ///
  /// [reading]: Current 3D magnetometer vector
  /// [pca]: PCA result containing mean and eigenvectors
  ///
  /// Returns 2D coordinates (u, v) in rotation plane basis.
  Vector2 project(Vector3 reading, PCAResult pca) {
    // Center the reading
    final centered = reading - pca.mean;

    // Project onto rotation plane basis (PC1 = major axis, PC2 = minor axis)
    final u = centered.dot(pca.pc1);
    final v = centered.dot(pca.pc2);

    return Vector2(u, v);
  }

  /// Project multiple readings onto rotation plane.
  List<Vector2> projectAll(List<Vector3> readings, PCAResult pca) {
    return readings.map((r) => project(r, pca)).toList();
  }
}

/// Computes phase angle θ(t) of 2D projected magnetometer vector.
///
/// Phase represents the angular position of the magnet around the wheel:
///   θ(t) = atan2(v(t), u(t))
///
/// Returns angle in radians [-π, π].
class PhaseComputer {
  /// Compute phase angle of projected 2D vector.
  ///
  /// [projected]: 2D coordinates in rotation plane
  ///
  /// Returns phase angle θ in radians [-π, π].
  double computePhase(Vector2 projected) {
    return atan2(projected.y, projected.x);
  }

  /// Compute phases for multiple projected samples.
  List<double> computePhases(List<Vector2> projectedSamples) {
    return projectedSamples.map(computePhase).toList();
  }
}

/// Unwraps phase angles to detect 2π cycles (full rotations).
///
/// Phase from atan2() wraps at ±π boundaries:
///   ..., -π → π, ...
///
/// Unwrapping detects these discontinuities and accumulates total phase:
///   If Δθ > π: subtract 2π (counter-clockwise wrap)
///   If Δθ < -π: add 2π (clockwise wrap)
///
/// Each 2π advance in unwrapped phase = one wheel rotation.
class PhaseUnwrapper {
  /// Last wrapped phase value (for detecting discontinuities).
  double _lastWrappedPhase = 0.0;

  /// Total accumulated phase (can exceed ±2π).
  double _totalPhase = 0.0;

  /// Number of complete 2π rotations detected.
  int _rotationCount = 0;

  /// Whether this is the first sample.
  bool _isFirstSample = true;

  /// Process new wrapped phase and update unwrapped phase.
  ///
  /// [wrappedPhase]: Phase angle in [-π, π] from atan2()
  ///
  /// Returns unwrapped phase (continuously increasing/decreasing).
  double unwrap(double wrappedPhase) {
    if (_isFirstSample) {
      _isFirstSample = false;
      _lastWrappedPhase = wrappedPhase;
      _totalPhase = wrappedPhase;
      return _totalPhase;
    }

    // Compute phase difference
    double delta = wrappedPhase - _lastWrappedPhase;

    // Detect and correct discontinuities
    if (delta > pi) {
      delta -= 2 * pi; // Counter-clockwise wrap
    } else if (delta < -pi) {
      delta += 2 * pi; // Clockwise wrap
    }

    // Update accumulated phase
    _totalPhase += delta;
    _lastWrappedPhase = wrappedPhase;

    // Count complete rotations (remove abs() to preserve direction)
    _rotationCount = (_totalPhase / (2 * pi)).floor();

    return _totalPhase;
  }

  /// Get current total unwrapped phase.
  double get totalPhase => _totalPhase;

  /// Get number of complete rotations detected.
  int get rotationCount => _rotationCount;

  /// Reset unwrapper state.
  void reset() {
    _lastWrappedPhase = 0.0;
    _totalPhase = 0.0;
    _rotationCount = 0;
    _isFirstSample = true;
  }
}
