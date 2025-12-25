import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/services/rotation_detection/pca/pca_result.dart';
import 'package:cavedivemapf/services/rotation_detection/pca/validity_gates.dart';
import 'package:cavedivemapf/services/rotation_detection/vector3.dart';

PCAResult _pcaResult({
  required double lambda1,
  required double lambda2,
  required double lambda3,
}) {
  return PCAResult(
    eigenvalues: [lambda1, lambda2, lambda3],
    eigenvectors: const [
      Vector3(1, 0, 0),
      Vector3(0, 1, 0),
      Vector3(0, 0, 1),
    ],
    mean: const Vector3(0, 0, 0),
  );
}

void main() {
  group('ValidityGates', () {
    test('passes with strong planar signal and coherent motion', () {
      final gates = ValidityGates(
        config: const ValidityGateConfig(
          minSignalStrength: 5.0,
          maxRotationFrequencyHz: 10.0,
          minCoherence: 0.4,
        ),
        samplingRateHz: 100.0,
      );

      final result = gates.check(_pcaResult(lambda1: 100, lambda2: 20, lambda3: 2), 0.1);

      expect(result.isValid, isTrue);
      expect(result.isPlanar, isTrue);
      expect(result.hasStrongSignal, isTrue);
      expect(result.isWithinFrequencyLimit, isTrue);
      expect(result.hasPhaseMotion, isTrue);
      expect(result.hasCoherentMotion, isTrue);
    });

    test('rejects when signal is below minimum', () {
      final gates = ValidityGates(
        config: const ValidityGateConfig(minSignalStrength: 5.0),
        samplingRateHz: 100.0,
      );

      final result = gates.check(_pcaResult(lambda1: 1, lambda2: 0.5, lambda3: 0.2), 0.05);

      expect(result.isValid, isFalse);
      expect(result.hasStrongSignal, isFalse);
    });

    test('rejects when coherence falls below threshold', () {
      final gates = ValidityGates(
        config: const ValidityGateConfig(minCoherence: 0.5),
        samplingRateHz: 100.0,
      );

      // Alternate signed deltas to drive coherence toward zero.
      gates.check(_pcaResult(lambda1: 50, lambda2: 10, lambda3: 1), 0.2);
      gates.check(_pcaResult(lambda1: 50, lambda2: 10, lambda3: 1), -0.2);
      final result = gates.check(_pcaResult(lambda1: 50, lambda2: 10, lambda3: 1), 0.2);

      expect(result.hasCoherentMotion, isFalse);
      expect(result.isValid, isFalse);
    });

    test('rejects when frequency exceeds limit', () {
      final gates = ValidityGates(
        config: const ValidityGateConfig(maxRotationFrequencyHz: 5.0),
        samplingRateHz: 100.0,
      );

      // Large phase change → very high instantaneous frequency.
      final result = gates.check(_pcaResult(lambda1: 50, lambda2: 10, lambda3: 1), 5.0);

      expect(result.isWithinFrequencyLimit, isFalse);
      expect(result.isValid, isFalse);
    });
  });
}
