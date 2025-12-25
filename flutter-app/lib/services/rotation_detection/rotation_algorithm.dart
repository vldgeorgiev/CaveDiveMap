/// Rotation detection algorithm selection.
enum RotationAlgorithm {
  /// Legacy magnitude-based threshold detection.
  ///
  /// Uses dual thresholds on magnetic field magnitude:
  /// - Peak when magnitude > maxThreshold
  /// - Reset when magnitude < minThreshold
  ///
  /// Limitations:
  /// - Orientation dependent (2× magnitude variation)
  /// - Affected by OS auto-calibration
  /// - Requires manual threshold tuning
  threshold,

  /// PCA-based phase tracking detection.
  ///
  /// Measures 2π phase advances in rotation plane:
  /// - Finds rotation plane via PCA
  /// - Tracks angular phase θ(t)
  /// - Counts 2π cycles
  ///
  /// Advantages:
  /// - Orientation independent
  /// - Robust to OS calibration
  /// - Zero configuration (no manual thresholds)
  /// - Superior false positive rejection
  pca,
}
