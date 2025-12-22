import 'dart:math';
import '../vector3.dart';
import 'pca_result.dart';

/// Computes Principal Component Analysis on 3D magnetometer samples.
///
/// PCA identifies the dominant axes of variation in the magnetic field:
/// - PC1 (largest eigenvalue): Perpendicular to rotation plane
/// - PC2, PC3 (smaller eigenvalues): Span the rotation plane
///
/// Algorithm:
/// 1. Center data by subtracting mean
/// 2. Compute 3×3 covariance matrix
/// 3. Eigenvalue decomposition (Jacobi method for symmetric 3×3)
/// 4. Sort eigenvalues/eigenvectors descending
class PCAComputer {
  /// Compute PCA decomposition on magnetometer samples.
  ///
  /// [samples] must contain at least 3 samples for valid covariance matrix.
  /// Returns null if input is degenerate (all samples identical).
  PCAResult? compute(List<Vector3> samples) {
    if (samples.length < 3) {
      return null;
    }

    // Step 1: Compute mean
    final mean = _computeMean(samples);

    // Step 2: Center data
    final centeredSamples = samples
        .map((s) => s - mean)
        .toList();

    // Step 3: Compute 3×3 covariance matrix
    final covMatrix = _computeCovarianceMatrix(centeredSamples);

    // Step 4: Eigenvalue decomposition (Jacobi method)
    final decomposition = _eigenDecomposition3x3(covMatrix);

    if (decomposition == null) {
      return null;
    }

    final (eigenvalues, eigenvectors) = decomposition;

    // Step 5: Sort by eigenvalue descending
    final sorted = _sortByEigenvalue(eigenvalues, eigenvectors);

    // Check for degenerate case (all eigenvalues near zero)
    if (sorted.$1[0] < 1e-9) {
      return null;
    }

    return PCAResult(
      eigenvalues: sorted.$1,
      eigenvectors: sorted.$2,
      mean: mean,
    );
  }

  /// Compute mean of samples.
  Vector3 _computeMean(List<Vector3> samples) {
    double sumX = 0.0;
    double sumY = 0.0;
    double sumZ = 0.0;

    for (final sample in samples) {
      sumX += sample.x;
      sumY += sample.y;
      sumZ += sample.z;
    }

    final n = samples.length.toDouble();
    return Vector3(sumX / n, sumY / n, sumZ / n);
  }

  /// Compute 3×3 covariance matrix from centered samples.
  ///
  /// Returns [covXX, covXY, covXZ, covYY, covYZ, covZZ]
  /// (symmetric matrix, only upper triangle stored)
  List<double> _computeCovarianceMatrix(List<Vector3> centeredSamples) {
    final n = centeredSamples.length.toDouble();

    // Initialize covariance matrix elements
    double covXX = 0.0, covXY = 0.0, covXZ = 0.0;
    double covYY = 0.0, covYZ = 0.0;
    double covZZ = 0.0;

    // Accumulate covariances
    for (final sample in centeredSamples) {
      covXX += sample.x * sample.x;
      covXY += sample.x * sample.y;
      covXZ += sample.x * sample.z;
      covYY += sample.y * sample.y;
      covYZ += sample.y * sample.z;
      covZZ += sample.z * sample.z;
    }

    // Normalize by n
    covXX /= n;
    covXY /= n;
    covXZ /= n;
    covYY /= n;
    covYZ /= n;
    covZZ /= n;

    return [covXX, covXY, covXZ, covYY, covYZ, covZZ];
  }

  /// Eigenvalue decomposition of symmetric 3×3 matrix using Jacobi method.
  ///
  /// Returns (eigenvalues, eigenvectors) or null if fails.
  (List<double>, List<Vector3>)? _eigenDecomposition3x3(List<double> cov) {
    // Extract matrix elements
    double a00 = cov[0]; // XX
    double a01 = cov[1]; // XY
    double a02 = cov[2]; // XZ
    double a11 = cov[3]; // YY
    double a12 = cov[4]; // YZ
    double a22 = cov[5]; // ZZ

    // Initialize eigenvectors as identity
    double v00 = 1.0, v01 = 0.0, v02 = 0.0;
    double v10 = 0.0, v11 = 1.0, v12 = 0.0;
    double v20 = 0.0, v21 = 0.0, v22 = 1.0;

    // Jacobi iteration (max 50 iterations)
    const maxIterations = 50;
    const tolerance = 1e-10;

    for (int iter = 0; iter < maxIterations; iter++) {
      // Find largest off-diagonal element
      double maxOffDiag = a01.abs();
      int p = 0, q = 1;

      if (a02.abs() > maxOffDiag) {
        maxOffDiag = a02.abs();
        p = 0;
        q = 2;
      }

      if (a12.abs() > maxOffDiag) {
        maxOffDiag = a12.abs();
        p = 1;
        q = 2;
      }

      // Check convergence
      if (maxOffDiag < tolerance) {
        break;
      }

      // Compute rotation angle
      double aPP = (p == 0) ? a00 : (p == 1 ? a11 : a22);
      double aQQ = (q == 1) ? a11 : a22;
      double aPQ = (p == 0 && q == 1) ? a01 : (p == 0 && q == 2 ? a02 : a12);

      double theta = 0.5 * atan2(2.0 * aPQ, aPP - aQQ);
      double c = cos(theta);
      double s = sin(theta);

      // Apply rotation to matrix
      double newAPP = c * c * aPP + s * s * aQQ - 2.0 * s * c * aPQ;
      double newAQQ = s * s * aPP + c * c * aQQ + 2.0 * s * c * aPQ;
      double newAPQ = 0.0; // Zeroed out

      if (p == 0 && q == 1) {
        double newA02 = c * a02 - s * a12;
        double newA12 = s * a02 + c * a12;
        a00 = newAPP;
        a11 = newAQQ;
        a01 = newAPQ;
        a02 = newA02;
        a12 = newA12;
      } else if (p == 0 && q == 2) {
        double newA01 = c * a01 - s * a12;
        double newA12 = s * a01 + c * a12;
        a00 = newAPP;
        a22 = newAQQ;
        a02 = newAPQ;
        a01 = newA01;
        a12 = newA12;
      } else { // p == 1, q == 2
        double newA01 = c * a01 - s * a02;
        double newA02 = s * a01 + c * a02;
        a11 = newAPP;
        a22 = newAQQ;
        a12 = newAPQ;
        a01 = newA01;
        a02 = newA02;
      }

      // Apply rotation to eigenvectors
      if (p == 0 && q == 1) {
        double newV00 = c * v00 - s * v10;
        double newV10 = s * v00 + c * v10;
        double newV01 = c * v01 - s * v11;
        double newV11 = s * v01 + c * v11;
        double newV02 = c * v02 - s * v12;
        double newV12 = s * v02 + c * v12;
        v00 = newV00; v10 = newV10;
        v01 = newV01; v11 = newV11;
        v02 = newV02; v12 = newV12;
      } else if (p == 0 && q == 2) {
        double newV00 = c * v00 - s * v20;
        double newV20 = s * v00 + c * v20;
        double newV01 = c * v01 - s * v21;
        double newV21 = s * v01 + c * v21;
        double newV02 = c * v02 - s * v22;
        double newV22 = s * v02 + c * v22;
        v00 = newV00; v20 = newV20;
        v01 = newV01; v21 = newV21;
        v02 = newV02; v22 = newV22;
      } else { // p == 1, q == 2
        double newV10 = c * v10 - s * v20;
        double newV20 = s * v10 + c * v20;
        double newV11 = c * v11 - s * v21;
        double newV21 = s * v11 + c * v21;
        double newV12 = c * v12 - s * v22;
        double newV22 = s * v12 + c * v22;
        v10 = newV10; v20 = newV20;
        v11 = newV11; v21 = newV21;
        v12 = newV12; v22 = newV22;
      }
    }

    // Extract eigenvalues (diagonal elements)
    final eigenvalues = [a00, a11, a22];

    // Extract eigenvectors (columns of V)
    final eigenvectors = [
      Vector3(v00, v10, v20),
      Vector3(v01, v11, v21),
      Vector3(v02, v12, v22),
    ];

    return (eigenvalues, eigenvectors);
  }

  /// Sort eigenvalues and eigenvectors in descending order.
  ///
  /// Returns (sorted eigenvalues, sorted eigenvectors).
  (List<double>, List<Vector3>) _sortByEigenvalue(
    List<double> eigenvalues,
    List<Vector3> eigenvectors,
  ) {
    // Create list of (eigenvalue, eigenvector) pairs
    final pairs = <(double, Vector3)>[];
    for (int i = 0; i < 3; i++) {
      pairs.add((eigenvalues[i], eigenvectors[i]));
    }

    // Sort by eigenvalue descending
    pairs.sort((a, b) => b.$1.compareTo(a.$1));

    // Extract sorted lists
    final sortedEigenvalues = pairs.map((p) => p.$1).toList();
    final sortedEigenvectors = pairs.map((p) => p.$2).toList();

    return (sortedEigenvalues, sortedEigenvectors);
  }
}
