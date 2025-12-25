import 'package:flutter_test/flutter_test.dart';

import 'package:cavedivemapf/services/rotation_detection/pca/phase_tracking.dart';

void main() {
  group('PhaseUnwrapper', () {
    test('does not produce premature negative counts', () {
      final unwrapper = PhaseUnwrapper();

      // Regression: using floor() would produce -1 for small negative phase.
      unwrapper.unwrap(0.0);
      unwrapper.unwrap(-0.1);
      expect(unwrapper.rotationCount, 0);
    });

    test('counts rotations across brief pauses', () {
      final unwrapper = PhaseUnwrapper();
      unwrapper.unwrap(0.0);

      // Simulate 1 rotation over samples with a pause (repeated wrapped phase).
      final samples = <double>[
        0.5,
        1.0,
        1.5,
        1.5, // pause
        1.5, // pause
        2.0,
        2.5,
        3.0,
        -3.0, // wrap
        -2.5,
        -2.0,
        -1.5,
        -1.0,
        -0.5,
        0.0,
      ];

      for (final p in samples) {
        unwrapper.unwrap(p);
      }

      expect(unwrapper.rotationCount, 1);
    });
  });
}
