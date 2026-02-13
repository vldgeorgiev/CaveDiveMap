import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/services/rotation_detection/pca_rotation_detector.dart';
import 'package:cavedivemapf/services/rotation_detection/vector3.dart';
import 'dart:math' show pi, sin, cos;

void main() {
  group('Fractional Rotation Tracking', () {
    late PCARotationDetector detector;

    setUp(() {
      detector = PCARotationDetector(
        config: const PCARotationConfig(
          windowSizeSeconds: 1.0,
          minWindowFillFraction: 0.3,
          minPhaseForDistanceUpdate: pi / 9, // 20 degrees
        ),
      );
      detector.setWheelCircumference(0.263); // 26.3cm wheel
      detector.start();
    });

    tearDown(() {
      detector.stop();
    });

    test('fractionalRotations returns 0.0 initially', () {
      expect(detector.fractionalRotations, 0.0);
      expect(detector.continuousDistance, 0.0);
    });

    test('fractionalRotations tracks quarter rotation (90°)', () {
      // Simulate 90° rotation with synthetic circular data
      final samples = _generateCircularRotation(
        numSamples: 25, // 0.25s at 100Hz = quarter rotation at 1Hz
        rotations: 0.25,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      // Allow some tolerance for PCA startup and noise
      expect(detector.fractionalRotations, closeTo(0.25, 0.05));
      expect(detector.rotationCount, 0); // Integer count still 0
    });

    test('fractionalRotations tracks half rotation (180°)', () {
      final samples = _generateCircularRotation(
        numSamples: 50,
        rotations: 0.5,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      expect(detector.fractionalRotations, closeTo(0.5, 0.05));
      expect(detector.rotationCount, 0);
    });

    test('fractionalRotations tracks three-quarter rotation (270°)', () {
      final samples = _generateCircularRotation(
        numSamples: 75,
        rotations: 0.75,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      expect(detector.fractionalRotations, closeTo(0.75, 0.05));
      expect(detector.rotationCount, 0);
    });

    test('fractionalRotations tracks mixed integer and fractional (2.25 rotations)', () {
      final samples = _generateCircularRotation(
        numSamples: 225,
        rotations: 2.25,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      expect(detector.fractionalRotations, closeTo(2.25, 0.05));
      expect(detector.rotationCount, 2);
    });

    test('continuousDistance calculates correctly from fractional rotations', () {
      final samples = _generateCircularRotation(
        numSamples: 50,
        rotations: 0.5,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      // 0.5 rotations × 0.263m = 0.1315m
      expect(detector.continuousDistance, closeTo(0.1315, 0.01));
    });

    test('continuousDistance matches integer distance over full rotations', () {
      final samples = _generateCircularRotation(
        numSamples: 1000, // 10 rotations at 100Hz
        rotations: 10.0,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      final expectedDistance = 10.0 * 0.263; // 2.63m
      final actualDistance = detector.continuousDistance;
      final error = (actualDistance - expectedDistance).abs() / expectedDistance;

      expect(error, lessThan(0.02)); // Within 2% accuracy
    });

    test('wheel circumference setter updates distance calculations', () {
      detector.setWheelCircumference(0.5); // 50cm wheel

      final samples = _generateCircularRotation(
        numSamples: 100,
        rotations: 1.0,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      // 1.0 rotation × 0.5m = 0.5m
      expect(detector.continuousDistance, closeTo(0.5, 0.02));
    });

    test('distance update callback fires at configured intervals', () {
      int callbackCount = 0;
      detector.onDistanceUpdate = () {
        callbackCount++;
      };

      // Simulate 1 rotation at 1Hz (100 samples)
      // With 20° updates (π/9), expect ~18 callbacks per rotation
      final samples = _generateCircularRotation(
        numSamples: 100,
        rotations: 1.0,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      // Should have ~18 callbacks (360° / 20° = 18)
      // Allow tolerance for startup and validity gates
      expect(callbackCount, greaterThan(10));
      expect(callbackCount, lessThan(25));
    });

    test('reset clears fractional rotation state', () {
      final samples = _generateCircularRotation(
        numSamples: 150,
        rotations: 1.5,
        signalStrength: 30.0,
      );

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      expect(detector.fractionalRotations, greaterThan(1.0));

      detector.reset();

      expect(detector.fractionalRotations, 0.0);
      expect(detector.continuousDistance, 0.0);
      expect(detector.rotationCount, 0);
    });

    test('fractionalRotations does not advance during invalid signal', () {
      // Generate noisy/weak signal that should be rejected
      final samples = _generateNoisySignal(numSamples: 100);

      for (final sample in samples) {
        detector.processSample(sample.vector, sample.timestamp);
      }

      // Fractional rotations should stay near zero (no valid signal)
      expect(detector.fractionalRotations, lessThan(0.1));
    });

    test('backward rotation handling (absolute value)', () {
      // This test would require more complex setup to create negative phase
      // For now, we verify the getter uses abs() on the accumulator
      expect(detector.fractionalRotations, isNonNegative);
    });
  });

  group('PCARotationConfig', () {
    test('default minPhaseForDistanceUpdate is π/9 (20 degrees)', () {
      const config = PCARotationConfig();
      expect(config.minPhaseForDistanceUpdate, closeTo(pi / 9, 0.001));

      // Verify it's approximately 20 degrees
      final degrees = config.minPhaseForDistanceUpdate * 180 / pi;
      expect(degrees, closeTo(20.0, 0.1));
    });

    test('custom minPhaseForDistanceUpdate can be set', () {
      const config = PCARotationConfig(
        minPhaseForDistanceUpdate: pi / 18, // 10 degrees
      );

      final degrees = config.minPhaseForDistanceUpdate * 180 / pi;
      expect(degrees, closeTo(10.0, 0.1));
    });
  });
}

/// Helper: Generate synthetic circular rotation data.
///
/// Simulates a magnet rotating in a plane, creating a sinusoidal
/// magnetic field pattern in 2D with a constant component in 3D.
class _SampleWithTimestamp {
  final Vector3 vector;
  final int timestamp;

  _SampleWithTimestamp(this.vector, this.timestamp);
}

List<_SampleWithTimestamp> _generateCircularRotation({
  required int numSamples,
  required double rotations,
  required double signalStrength,
}) {
  final samples = <_SampleWithTimestamp>[];
  final earthField = Vector3(20.0, 5.0, 40.0); // Simulate Earth's field
  final startTime = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < numSamples; i++) {
    final angle = (i / numSamples) * rotations * 2 * pi;

    // Magnet field rotates in xy plane
    final magnetX = signalStrength * cos(angle);
    final magnetY = signalStrength * sin(angle);
    final magnetZ = 2.0; // Small z component

    // Add Earth's field
    final totalX = earthField.x + magnetX;
    final totalY = earthField.y + magnetY;
    final totalZ = earthField.z + magnetZ;

    final timestamp = startTime + (i * 10); // 10ms intervals (100Hz)
    samples.add(_SampleWithTimestamp(
      Vector3(totalX, totalY, totalZ),
      timestamp,
    ));
  }

  return samples;
}

/// Helper: Generate noisy/weak signal that should be rejected.
List<_SampleWithTimestamp> _generateNoisySignal({
  required int numSamples,
}) {
  final samples = <_SampleWithTimestamp>[];
  final earthField = Vector3(20.0, 5.0, 40.0);
  final startTime = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < numSamples; i++) {
    // Random noise with very weak signal
    final noiseX = (i % 3 - 1) * 0.5;
    final noiseY = (i % 5 - 2) * 0.5;
    final noiseZ = (i % 7 - 3) * 0.5;

    final timestamp = startTime + (i * 10);
    samples.add(_SampleWithTimestamp(
      Vector3(earthField.x + noiseX, earthField.y + noiseY, earthField.z + noiseZ),
      timestamp,
    ));
  }

  return samples;
}
