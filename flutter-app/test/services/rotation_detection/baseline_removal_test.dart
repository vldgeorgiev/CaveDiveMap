import 'package:flutter_test/flutter_test.dart';

import 'package:cavedivemapf/services/rotation_detection/pca/baseline_removal.dart';
import 'package:cavedivemapf/services/rotation_detection/vector3.dart';

void main() {
  test('BaselineRemoval supports alphaOverride (slower adaptation)', () {
    final baseline = BaselineRemoval(alpha: 0.5);

    // Initialize
    expect(baseline.removeBaseline(const Vector3(10, 0, 0)), Vector3.zero);

    // Fast adapt with alpha=0.5
    final fast = baseline.removeBaseline(const Vector3(20, 0, 0));
    // baseline moves toward 20 => corrected should be around +5
    expect(fast.x, closeTo(5.0, 1e-6));

    // Now hold reading constant but force very slow adaptation.
    final slow1 = baseline.removeBaseline(const Vector3(20, 0, 0), alphaOverride: 0.01);
    final slow2 = baseline.removeBaseline(const Vector3(20, 0, 0), alphaOverride: 0.01);

    // With a tiny alphaOverride, corrected should not collapse quickly to 0.
    expect(slow2.x.abs(), greaterThan(0.01));
    expect(slow2.x.abs(), lessThanOrEqualTo(slow1.x.abs()));
  });
}
