import '../vector3.dart';

/// Result of PCA decomposition on magnetometer samples.
///
/// Contains eigenvalues, eigenvectors, and quality metrics for rotation
/// plane identification.
///
/// CRITICAL: Eigenvalues are sorted DESCENDING (λ1 ≥ λ2 ≥ λ3).
/// This means:
///   eigenvectors[0] = PC1 → λ1 (largest) → IN rotation plane (major axis)
///   eigenvectors[1] = PC2 → λ2 (medium) → IN rotation plane (minor axis)
///   eigenvectors[2] = PC3 → λ3 (smallest) → PERPENDICULAR to plane (normal)
class PCAResult {
  /// Eigenvalues in descending order (λ1 ≥ λ2 ≥ λ3).
  final List<double> eigenvalues;

  /// Eigenvectors corresponding to eigenvalues.
  /// eigenvectors[0] = PC1 (major axis IN rotation plane)
  /// eigenvectors[1] = PC2 (minor axis IN rotation plane)
  /// eigenvectors[2] = PC3 (plane normal, perpendicular to rotation)
  final List<Vector3> eigenvectors;

  /// Mean of the input samples (used for centering).
  final Vector3 mean;

  const PCAResult({
    required this.eigenvalues,
    required this.eigenvectors,
    required this.mean,
  });

  /// Flatness metric: λ3 / (λ1 + λ2 + λ3)
  ///
  /// Measures how much variance is perpendicular to the rotation plane.
  /// LOW values indicate planar data (good for rotation detection):
  /// - Close to 0.0: Strong planar signal (λ3 << λ1, λ2) - IDEAL
  /// - Close to 0.33: Spherical data (λ1 ≈ λ2 ≈ λ3) - REJECT
  ///
  /// Typical threshold: < 0.10 for valid rotation plane.
  /// Note: This is the OPPOSITE of the old incorrect metric!
  double get flatness {
    final sum = eigenvalues[0] + eigenvalues[1] + eigenvalues[2];
    if (sum < 1e-9) return 1.0;
    return eigenvalues[2] / sum;
  }

  /// Legacy planarity metric for backward compatibility.
  @Deprecated('Use flatness instead - lower is better')
  double get planarity => 1.0 - 3.0 * flatness;

  /// Signal strength: λ1
  ///
  /// Measures the magnitude of variation in the magnetometer signal.
  /// Stronger signals indicate larger magnetic field changes (closer magnet).
  ///
  /// Typical threshold: > 10.0 μT² for valid signal.
  double get signalStrength => eigenvalues[0];

  /// First principal component (major axis IN rotation plane).
  Vector3 get pc1 => eigenvectors[0];

  /// Second principal component (minor axis IN rotation plane).
  Vector3 get pc2 => eigenvectors[1];

  /// Third principal component (plane normal, PERPENDICULAR to rotation).
  Vector3 get pc3 => eigenvectors[2];

  @override
  String toString() => 'PCAResult('
      'eigenvalues: [${eigenvalues[0].toStringAsFixed(2)}, '
      '${eigenvalues[1].toStringAsFixed(2)}, '
      '${eigenvalues[2].toStringAsFixed(2)}], '
      'flatness: ${flatness.toStringAsFixed(3)} (lower=planar), '
      'signalStrength: ${signalStrength.toStringAsFixed(2)}'
      ')';
}
