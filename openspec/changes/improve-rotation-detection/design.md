# Technical Design: PCA-Based Phase Tracking for Rotation Detection

## Overview

This document details the PCA-based phase tracking algorithm for wheel rotation detection. The method measures the angular phase of the 3D magnetic field vector created by a rotating magnet, where each 2π phase advance corresponds to one wheel rotation.

## Core Concept

### Physical Model

- **Setup**: Magnet mounted on wheel, phone rigidly mounted to device
- **Signal**: 3D magnetic field vector **B** = (Bx, By, Bz) rotates as wheel turns
- **Measurement**: Track angular phase θ(t) of rotating field vector
- **Counting**: Each Δθ = 2π radians → one rotation

### Why This Works

1. **Geometry, not amplitude**: Phase is independent of field strength
2. **Orientation-independent**: PCA finds rotation plane regardless of phone orientation
3. **Drift-resistant**: Baseline subtraction removes Earth field and OS calibration effects
4. **Deterministic**: No ML training, no manual thresholds, provably correct

---

## Current System Analysis

### Existing Algorithms

- **Legacy threshold**: Still present for compatibility; uses magnitude thresholds but now fed with *uncalibrated* sensor data.
- **PCA phase tracking (default)**: Uncalibrated-only input, baseline removal, PCA plane locking, validity gating, phase unwrapping with accumulated emission gating.

---

## PCA Phase Tracking Algorithm

### Processing Pipeline

```
Raw Magnetometer (X, Y, Z)
    ↓
1. Baseline Removal (per-axis rolling mean)
    ↓
2. Sliding Window Buffer (1.0 second)
    ↓
3. PCA: Compute covariance matrix & eigenvectors
    ↓
4. Validity Gating (planarity, strength, frequency, coherence)
    ↓
5. Project to PCA plane → (u, v)
    ↓
6. Compute phase θ = atan2(v, u)
    ↓
7. Unwrap phase & count 2π cycles
    ↓
Distance = rotations × wheel_circumference
```

---

## Step-by-Step Implementation

### Step 1: Baseline Removal

**Purpose**: Remove Earth's magnetic field and drift. We now consume `TYPE_MAGNETIC_FIELD_UNCALIBRATED` on Android and own the baseline; calibrated feed is not used for PCA/threshold counting.

**Method**: Exponential Moving Average (EMA) per axis with a tuned alpha suitable for uncalibrated drift adaptation (value adjustable during beta)

```dart
class BaselineRemoval {
  double _baselineX = 0.0;
  double _baselineY = 0.0;
  double _baselineZ = 0.0;
  
  static const double alpha = 0.01; // Time constant ≈ 100 samples = 1 second
  
  Vector3 removeBa(double x, double y, double z) {
    // Update baselines with exponential moving average
    _baselineX = alpha * x + (1 - alpha) * _baselineX;
    _baselineY = alpha * y + (1 - alpha) * _baselineY;
    _baselineZ = alpha * z + (1 - alpha) * _baselineZ;
    
    // Return baseline-subtracted signal
    return Vector3(
      x - _baselineX,
      y - _baselineY,
      z - _baselineZ,
    );
  }
  
  void reset() {
    _baselineX = 0.0;
    _baselineY = 0.0;
    _baselineZ = 0.0;
  }
}
```

**Alternative**: Rolling mean with 1-2 second window (more aggressive baseline removal)

---

### Step 2: Sliding Window Buffer

**Purpose**: Accumulate data for PCA computation

**Window Size**: On the order of 1 second (50-150 samples depending on sampling rate), with early-start min-fill to reduce startup latency

```dart
class SlidingWindowBuffer {
  final Queue<Vector3> _buffer = Queue<Vector3>();
  final int _maxSize;
  
  SlidingWindowBuffer({int windowSizeSeconds = 1, int samplingRateHz = 100})
      : _maxSize = windowSizeSeconds * samplingRateHz;
  
  void add(Vector3 sample) {
    _buffer.addLast(sample);
    if (_buffer.length > _maxSize) {
      _buffer.removeFirst();
    }
  }
  
  bool get isFull => _buffer.length >= _maxSize;
  
  List<Vector3> get samples => _buffer.toList();
  
  void clear() => _buffer.clear();
}
```

---

### Step 3: PCA Computation

**Purpose**: Find the dominant 2D plane of rotation

**Method**: Eigenvalue decomposition of covariance matrix with basis locking to avoid sign flips and drift; refresh basis only when quality improves or degrades past hysteresis.

```dart
import 'package:ml_linalg/matrix.dart';

class PCAComputer {
  PCAResult? computePCA(List<Vector3> samples) {
    if (samples.length < 10) return null;
    
    // 1. Center the data (mean = 0)
    final mean = _computeMean(samples);
    final centered = samples.map((s) => s - mean).toList();
    
    // 2. Compute 3×3 covariance matrix
    final cov = _computeCovarianceMatrix(centered);
    
    // 3. Eigenvalue decomposition: C = V * Λ * V^T
    final eigen = cov.eigen();
    
    // Sort eigenvalues descending: λ1 ≥ λ2 ≥ λ3
    final sorted = _sortEigenvalues(eigen);
    
    return PCAResult(
      eigenvalues: sorted.values,
      eigenvectors: sorted.vectors,
      explainedVariance: sorted.explainedVariance,
    );
  }
  
  Vector3 _computeMean(List<Vector3> samples) {
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final s in samples) {
      sumX += s.x;
      sumY += s.y;
      sumZ += s.z;
    }
    final n = samples.length;
    return Vector3(sumX / n, sumY / n, sumZ / n);
  }
  
  Matrix _computeCovarianceMatrix(List<Vector3> centered) {
    final n = centered.length;
    double c11 = 0, c12 = 0, c13 = 0;
    double c22 = 0, c23 = 0;
    double c33 = 0;
    
    for (final s in centered) {
      c11 += s.x * s.x;
      c12 += s.x * s.y;
      c13 += s.x * s.z;
      c22 += s.y * s.y;
      c23 += s.y * s.z;
      c33 += s.z * s.z;
    }
    
    // Symmetric matrix
    return Matrix.fromList([
      [c11 / n, c12 / n, c13 / n],
      [c12 / n, c22 / n, c23 / n],
      [c13 / n, c23 / n, c33 / n],
    ]);
  }
}

class PCAResult {
  final List<double> eigenvalues;      // [λ1, λ2, λ3] sorted descending
  final List<Vector3> eigenvectors;    // [v1, v2, v3] corresponding
  final List<double> explainedVariance; // [ratio1, ratio2, ratio3]
  
  PCAResult({
    required this.eigenvalues,
    required this.eigenvectors,
    required this.explainedVariance,
  });
  
  // Planarity measure: how 2D is the signal?
  double get planarity {
    final sum = eigenvalues[0] + eigenvalues[1] + eigenvalues[2];
    return eigenvalues[2] / sum; // Should be small (<0.1)
  }
  
  // Signal strength: radius in rotation plane
  double get signalStrength {
    return sqrt(eigenvalues[0] + eigenvalues[1]);
  }
}
```

**Math Reference**:
- Covariance matrix: `C[i,j] = (1/n) Σ(xi - x̄)(xj - x̄)`
- Eigenvalue equation: `C·v = λ·v`
- Explained variance: `λi / (λ1 + λ2 + λ3)`

---

### Step 4: Validity Gating

**Purpose**: Ensure signal is a valid rotation before counting

**Gates**:

```dart
class ValidityGates {
  static const double planarityThreshold = 0.1;  // λ3 / Σλ < 0.1
  static const double minSignalStrength = 10.0;  // μT (above noise)
  static const double maxRotationHz = 7.0;       // Max 7 rotations/second
  static const double minCoherence = 0.8;        // Phase direction stability
  
  bool isValidRotationSignal(PCAResult pca, double phaseSpeedRps) {
    // Gate 1: Planarity (data lies in 2D plane)
    if (pca.planarity > planarityThreshold) {
      return false; // Too 3D, not rotating in plane
    }
    
    // Gate 2: Signal strength (above noise floor)
    if (pca.signalStrength < minSignalStrength) {
      return false; // Signal too weak
    }
    
    // Gate 3: Frequency (rotation not too fast)
    if (phaseSpeedRps.abs() > maxRotationHz) {
      return false; // Unphysical rotation speed
    }
    
    // Gate 4: Coherence (phase direction consistent)
    // Computed from phase derivative stability over time
    final coherence = _computeCoherence();
    if (coherence < minCoherence) {
      return false; // Phase direction unstable
    }
    
    return true; // All gates passed
  }
  
  double _computeCoherence() {
    // Track phase derivative sign consistency
    // Implementation: count sign changes in recent phase derivatives
    // Return: fraction of samples with consistent direction
    // Details: see Phase Tracking section
    return 1.0; // Placeholder
  }
}
```

---

### Step 5: Project to PCA Plane

**Purpose**: Convert 3D signal to 2D coordinates for phase computation

**Method**: Dot product with first two eigenvectors

```dart
class PCAProjector {
  Vector2 projectToPCAPlane(Vector3 signal, PCAResult pca) {
    // Project onto eigenvectors v1 and v2
    final v1 = pca.eigenvectors[0]; // 1st principal component
    final v2 = pca.eigenvectors[1]; // 2nd principal component
    
    final u = signal.dot(v1);
    final v = signal.dot(v2);
    
    return Vector2(u, v);
  }
}
```

**Visualization**:
```
3D space (Bx, By, Bz)
      ↓ PCA finds rotation plane
2D plane (u, v) where signal rotates
```

---

### Step 6: Phase Computation

**Purpose**: Convert (u, v) coordinates to angular phase θ

**Method**: `atan2(v, u)` gives angle in [-π, π]

```dart
class PhaseComputer {
  double computePhase(Vector2 projected) {
    // atan2 returns angle in radians: [-π, π]
    return atan2(projected.y, projected.x);
  }
}
```

**Note**: `atan2(v, u)` is preferred over `atan(v/u)` because:
- Handles all quadrants correctly
- No division by zero
- Returns signed angle with correct branch cuts

---

### Step 7: Phase Unwrapping & Rotation Counting

**Purpose**: Track continuous phase and count 2π cycles

**Method**: Detect phase wraps at ±π boundary and accumulate total phase; emission is gated separately by validity and quality to handle pauses and brief gate failures without losing accumulated phase.

```dart
class PhaseUnwrapper {
  double _previousPhase = 0.0;
  double _cumulativePhase = 0.0;
  int _rotationCount = 0;
  
  static const double pi = 3.141592653589793;
  static const double twoPi = 2 * pi;
  
  int updatePhase(double currentPhase) {
    // Compute phase difference
    double delta = currentPhase - _previousPhase;
    
    // Unwrap: detect jumps at ±π boundary
    if (delta > pi) {
      delta -= twoPi;  // Wrapped backward
    } else if (delta < -pi) {
      delta += twoPi;  // Wrapped forward
    }
    
    // Accumulate phase
    _cumulativePhase += delta;
    _previousPhase = currentPhase;
    
    // Count full rotations (every 2π)
    final newRotationCount = (_cumulativePhase.abs() / twoPi).floor();
    
    // Check if new rotation detected
    if (newRotationCount > _rotationCount) {
      _rotationCount = newRotationCount;
      return 1; // One new rotation detected
    }
    
    return 0; // No new rotation
  }
  
  void reset() {
    _previousPhase = 0.0;
    _cumulativePhase = 0.0;
    _rotationCount = 0;
  }
  
  // Get rotation direction (forward = positive, backward = negative)
  int get direction => _cumulativePhase >= 0 ? 1 : -1;
  
  // Get total rotations including direction
  int get signedRotationCount => (_cumulativePhase / twoPi).round();
}
```

**Phase Unwrapping Example**:
```
Raw phase:     -2.5  -2.0  -1.5  -1.0   3.0   2.5   2.0  1.5
                                      ↑ wrap detected
Unwrapped:     -2.5  -2.0  -1.5  -1.0  -3.1  -3.6  -4.1  -4.6
Cumulative:    -2.5  -2.5  -1.0  -1.0  -3.1  -3.6  -4.1  -4.6
Rotations:       0     0     0     0     0     0     0     0
```

After another -2.0 radians → cumulative = -6.3 → rotation count = 1

---

## Complete Algorithm Integration

### Main Detection Service

```dart
class PCARotationDetector extends ChangeNotifier {
  final BaselineRemoval _baselineRemoval = BaselineRemoval();
  final SlidingWindowBuffer _buffer = SlidingWindowBuffer();
  final PCAComputer _pcaComputer = PCAComputer();
  final ValidityGates _validityGates = ValidityGates();
  final PCAProjector _projector = PCAProjector();
  final PhaseComputer _phaseComputer = PhaseComputer();
  final PhaseUnwrapper _phaseUnwrapper = PhaseUnwrapper();
  
  // State
  int _totalRotations = 0;
  double _wheelCircumference = 0.263; // meters
  double _signalQuality = 0.0; // 0-100%
  double _rotationSpeedRps = 0.0;
  
  // Getters
  int get totalRotations => _totalRotations;
  double get distance => _totalRotations * _wheelCircumference;
  double get signalQuality => _signalQuality;
  double get rotationSpeedRps => _rotationSpeedRps;
  
  void onMagnetometerEvent(MagnetometerEvent event) {
    // Step 1: Baseline removal
    final baselineRemoved = _baselineRemoval.removeBaseline(
      event.x, event.y, event.z
    );
    
    // Step 2: Add to sliding window
    _buffer.add(baselineRemoved);
    
    if (!_buffer.isFull) return;
    
    // Step 3: Compute PCA every N samples (e.g., every 10 samples)
    // Not needed every single sample for efficiency
    if (_buffer.samples.length % 10 != 0) return;
    
    final pca = _pcaComputer.computePCA(_buffer.samples);
    if (pca == null) return;
    
    // Step 4: Compute phase speed (derivative) for gating
    // Uses recent phase history
    _rotationSpeedRps = _estimateRotationSpeed();
    
    // Step 5: Validity gating
    if (!_validityGates.isValidRotationSignal(pca, _rotationSpeedRps)) {
      _signalQuality = 0.0;
      return;
    }
    
    // Step 6: Project latest sample to PCA plane
    final latestSample = _buffer.samples.last;
    final projected = _projector.projectToPCAPlane(latestSample, pca);
    
    // Step 7: Compute phase
    final phase = _phaseComputer.computePhase(projected);
    
    // Step 8: Unwrap and count rotations
    final newRotations = _phaseUnwrapper.updatePhase(phase);
    
    if (newRotations > 0) {
      _totalRotations += newRotations;
      _onRotationDetected();
      notifyListeners();
    }
    
    // Update signal quality (0-100%)
    _signalQuality = _computeSignalQuality(pca);
    notifyListeners();
  }
  
  double _estimateRotationSpeed() {
    // Compute from phase derivative: dθ/dt
    // Implementation: finite difference over recent phase samples
    // Return: rotations per second
    return 0.0; // Placeholder
  }
  
  double _computeSignalQuality(PCAResult pca) {
    // Combine multiple factors:
    // - Planarity (1 - λ3/Σλ)
    // - Signal strength normalized
    // - Coherence
    final planarityScore = (1.0 - pca.planarity) * 100;
    final strengthScore = min(pca.signalStrength / 50.0, 1.0) * 100;
    return (planarityScore + strengthScore) / 2.0;
  }
  
  void _onRotationDetected() {
    // Trigger callbacks, save survey point, etc.
    print('Rotation detected! Total: $_totalRotations');
  }
  
  void reset() {
    _totalRotations = 0;
    _baselineRemoval.reset();
    _buffer.clear();
    _phaseUnwrapper.reset();
    notifyListeners();
  }
  
  void setWheelCircumference(double circumference) {
    _wheelCircumference = circumference;
    notifyListeners();
  }
}
```

---

## Performance Optimization

### Computational Cost

**Per Sample** (100 Hz = 100 times/second):
- Baseline removal: 3 multiplies + 3 adds = **~10 ops**
- Buffer update: **O(1)**

**Per PCA Window** (every 10 samples = 10 Hz):
- Covariance matrix: 6 sums over N samples = **O(N)** where N ≈ 100
- Eigenvalue decomposition: 3×3 matrix = **~200 ops** (small, fast)
- Projection + phase: **~20 ops**
- Total per PCA: **~500 ops**

**Total**: ~100 ops/sec (baseline) + 5000 ops/sec (PCA) = **5100 ops/sec**

**Comparison**: Current magnitude algorithm ≈ 100 ops/sec

**Verdict**: ~50x more computation, but still negligible on modern phones (<0.1% CPU)

### Memory Footprint

- Baseline: 3 doubles = 24 bytes
- Window buffer: 100 samples × 3 axes × 8 bytes = 2400 bytes
- PCA result: ~200 bytes
- **Total: <3 KB additional memory**

### Battery Impact

Magnetometer sampling already dominates (hardware cost). Additional processing:
- CPU: <0.1% → negligible battery impact
- **Estimated increase: <1% of app battery usage**

---

## Tuning Parameters

### Critical Parameters

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| Window size | 1.0 s | 0.5-2.0 s | Longer = more stable, higher latency |
| Baseline alpha | 0.01 | 0.001-0.1 | Lower = slower baseline tracking |
| Planarity threshold | 0.1 | 0.05-0.2 | Lower = stricter 2D requirement |
| Min signal strength | 10 μT | 5-20 μT | Device-dependent noise floor |
| Max rotation speed | 7 Hz | 5-10 Hz | Physical limit of wheel |

### Auto-Tuning Strategy

**Noise Floor Calibration** (on first launch):
1. Record 5 seconds of data with wheel NOT rotating
2. Compute std dev of baseline-removed signal
3. Set `minSignalStrength = 3 × std_dev`

**Adaptive Planarity**:
- If signal quality consistently low, relax planarity threshold slightly
- Monitor false positive rate to prevent over-relaxation

---

## Edge Cases & Failure Modes

### Case 1: Very Slow Rotation (<0.2 Hz)

**Problem**: Phase barely changes, hard to distinguish from noise

**Solution**: 
- Increase window size to 2-3 seconds
- Require multiple consecutive samples with consistent phase derivative
- Display "Moving too slowly" warning if phase speed < threshold

### Case 2: Phone Movement During Measurement

**Problem**: Figure-8 or random phone rotation adds 3D component

**Solution**:
- Planarity gate rejects non-planar signals
- Coherence gate rejects inconsistent phase direction
- Valid rotation requires sustained planar rotation pattern

### Case 3: Sudden Baseline Shift (Metal Object Nearby)

**Problem**: Large DC offset in magnetic field

**Solution**:
- Baseline removal adapts within 1-2 seconds (100-200 samples)
- During adaptation, signal quality drops → no false counts
- Display "Recalibrating..." during adaptation period

### Case 4: Zero Rotation (Stationary)

**Problem**: Random noise might cause spurious phase changes

**Solution**:
- Signal strength gate requires amplitude above noise floor
- Phase unwrapper only counts full 2π cycles
- Small random phase jitter (<π) doesn't trigger counts

### Case 5: Extremely Fast Rotation (>7 Hz)

**Problem**: Nyquist limit at 100 Hz sampling = 50 Hz max frequency

**Solution**:
- Frequency gate rejects phase speeds above physical maximum
- In practice, human-powered wheel unlikely to exceed 5 Hz
- If detected, display "Rotating too fast" warning

---

## Integration with Existing System

### Service Layer Changes

**File**: `flutter-app/lib/services/magnetometer_service.dart`

```dart
class MagnetometerService extends ChangeNotifier {
  final StorageService _storageService;
  
  // New: PCA detector (replaces threshold logic)
  late PCARotationDetector _detector;
  
  // Legacy support
  bool _useLegacyDetection = false;
  late ThresholdDetector _legacyDetector;
  
  MagnetometerService(this._storageService) {
    _detector = PCARotationDetector();
    _legacyDetector = ThresholdDetector(); // Original algorithm
    _initializeDetector();
  }
  
  Future<void> _initializeDetector() async {
    // Auto-calibrate noise floor on first launch
    await _detector.calibrateNoiseFloor();
    notifyListeners();
  }
  
  void _onMagnetometerEvent(MagnetometerEvent event) {
    if (_useLegacyDetection) {
      // Use original magnitude-based algorithm
      _legacyDetector.onMagnetometerEvent(event);
    } else {
      // Use new PCA phase tracking
      _detector.onMagnetometerEvent(event);
    }
    
    // Update UI
    _samplesSinceUIUpdate++;
    if (_samplesSinceUIUpdate >= _uiUpdateInterval) {
      _samplesSinceUIUpdate = 0;
      notifyListeners();
    }
  }
  
  // Getters delegate to active detector
  int get totalRotations => _useLegacyDetection 
      ? _legacyDetector.rotationCount 
      : _detector.totalRotations;
  
  double get signalQuality => _useLegacyDetection 
      ? 0.0 // Legacy mode doesn't have quality metric
      : _detector.signalQuality;
}
```

### Settings UI Changes

Add signal quality indicator and algorithm toggle:

```dart
// In SettingsScreen
Column(
  children: [
    // Algorithm selection
    SwitchListTile(
      title: Text('Use PCA Detection (Recommended)'),
      subtitle: Text('Automatic, no configuration needed'),
      value: !settings.useLegacyDetection,
      onChanged: (value) => settings.setUseLegacyDetection(!value),
    ),
    
    if (!settings.useLegacyDetection) ...[
      // Signal quality display
      Consumer<MagnetometerService>(
        builder: (context, mag, _) {
          return LinearProgressIndicator(
            value: mag.signalQuality / 100.0,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              mag.signalQuality > 80 ? Colors.green :
              mag.signalQuality > 50 ? Colors.orange : Colors.red,
            ),
          );
        },
      ),
      Text('Signal Quality: ${mag.signalQuality.toInt()}%'),
      
      // Debug info
      if (settings.showDebugInfo) ...[
        Text('Rotation Speed: ${mag.rotationSpeedRps.toStringAsFixed(2)} Hz'),
        Text('Planarity: ${mag.planarity.toStringAsFixed(3)}'),
      ],
    ] else ...[
      // Show legacy threshold controls
      _buildThresholdSliders(),
    ],
  ],
)
```

---

## Testing Strategy

### Unit Tests (Synthetic Data)

```dart
void main() {
  group('PCARotationDetector', () {
    test('detects perfect circular rotation', () {
      final detector = PCARotationDetector();
      
      // Generate 2 rotations at 1 Hz over 2 seconds
      final samples = generateCircularRotation(
        frequency: 1.0, // Hz
        amplitude: 50.0, // μT
        duration: Duration(seconds: 2),
        samplingRate: 100, // Hz
        orientation: Vector3(0, 0, 0), // Any orientation
      );
      
      int detectedRotations = 0;
      for (final sample in samples) {
        detector.onMagnetometerEvent(
          MagnetometerEvent(sample.x, sample.y, sample.z, sample.timestamp)
        );
        if (detector.totalRotations > detectedRotations) {
          detectedRotations = detector.totalRotations;
        }
      }
      
      expect(detectedRotations, equals(2));
    });
    
    test('rejects random noise', () {
      final detector = PCARotationDetector();
      
      // Generate random noise (no rotation)
      final samples = generateRandomNoise(
        duration: Duration(seconds: 2),
        noiseLevel: 10.0,
      );
      
      for (final sample in samples) {
        detector.onMagnetometerEvent(
          MagnetometerEvent(sample.x, sample.y, sample.z, sample.timestamp)
        );
      }
      
      expect(detector.totalRotations, equals(0));
    });
    
    test('rejects figure-8 phone movement', () {
      final detector = PCARotationDetector();
      
      // Generate figure-8 pattern (3D, non-planar)
      final samples = generateFigure8Movement(
        duration: Duration(seconds: 2),
      );
      
      for (final sample in samples) {
        detector.onMagnetometerEvent(
          MagnetometerEvent(sample.x, sample.y, sample.z, sample.timestamp)
        );
      }
      
      expect(detector.totalRotations, lessThan(1)); // At most 1 false positive
    });
  });
}
```

### Real-World Testing Protocol

**Test Matrix**: 6 orientations × 3 speeds × 3 devices = 54 test cases

| Orientation | Speed | Expected Accuracy |
|-------------|-------|-------------------|
| Portrait, face up | 1 Hz | >95% |
| Portrait, face down | 1 Hz | >95% |
| Landscape, face up | 1 Hz | >95% |
| Landscape, face down | 1 Hz | >95% |
| Edge up | 1 Hz | >95% |
| Edge down | 1 Hz | >95% |

Repeat for speeds: 0.5 Hz (slow), 2 Hz (normal), 5 Hz (fast)

**Data Collection**:
```dart
// Test harness
class RotationTestHarness {
  void runTest({
    required String testName,
    required int expectedRotations,
  }) {
    final detector = PCARotationDetector();
    
    // Record actual rotations manually (video with frame counter)
    final actualRotations = promptUserForActualCount();
    
    // Compare
    final accuracy = detector.totalRotations / actualRotations;
    final error = (detector.totalRotations - actualRotations).abs();
    
    print('Test: $testName');
    print('Expected: $expectedRotations');
    print('Detected: ${detector.totalRotations}');
    print('Actual: $actualRotations');
    print('Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');
    print('Error: $error rotations');
    
    // Log to CSV for analysis
    logTestResult(testName, expectedRotations, detector.totalRotations, actualRotations);
  }
}
```

---

## Dependencies

### Required Dart/Flutter Packages

```yaml
# pubspec.yaml
dependencies:
  sensors_plus: ^7.0.0      # Magnetometer access (already in project)
  ml_linalg: ^13.0.0        # Matrix operations & eigenvalue decomposition
  vector_math: ^2.1.4       # Vector operations
```

**Alternative**: Implement custom 3×3 eigenvalue solver (avoids dependency)

### Platform Requirements

- **iOS**: 12.0+ (CoreMotion magnetometer API)
- **Android**: API 26+ (Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED for primary pipeline)
- **Sampling Rate**: 50-150 Hz (device-dependent)

---

## Migration Plan

### Phase 1: Side-by-Side Implementation (Week 1-2)
- Implement PCA detector alongside existing threshold detector
- Add toggle in settings: "Use PCA Detection (Beta)"
- Default: OFF (use existing threshold algorithm)
- Collect user feedback

### Phase 2: Beta Testing (Week 3-4)
- Enable PCA by default for beta users
- Monitor accuracy reports via telemetry
- Compare PCA vs threshold performance
- Iterate on tuning parameters

### Phase 3: Production Release (Week 5-6)
- Enable PCA by default for all users
- Keep threshold mode as "Classic Detection" option
- Display migration notice: "Now using improved detection"
- Provide rollback instructions in help docs

### Phase 4: Deprecation (3-6 months later)
- If PCA proves superior, remove threshold code
- Or keep both permanently if some users prefer threshold mode

---

## Debug & Diagnostics

### Debug Display Panel

```dart
// In SettingsScreen or dedicated debug screen
class DebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MagnetometerService>(
      builder: (context, mag, _) {
        final detector = mag.detector;
        return Column(
          children: [
            Text('Algorithm: PCA Phase Tracking'),
            Text('Signal Quality: ${detector.signalQuality.toInt()}%'),
            Text('Rotation Speed: ${detector.rotationSpeedRps.toStringAsFixed(2)} Hz'),
            Text('Planarity: ${detector.planarity.toStringAsFixed(3)}'),
            Text('Signal Strength: ${detector.signalStrength.toStringAsFixed(1)} μT'),
            Text('Phase: ${detector.currentPhase.toStringAsFixed(2)} rad'),
            Text('Cumulative Phase: ${detector.cumulativePhase.toStringAsFixed(2)} rad'),
            Text('Rotations: ${detector.totalRotations}'),
            Text('Distance: ${detector.distance.toStringAsFixed(2)} m'),
          ],
        );
      },
    );
  }
}
```

### Logging for Analysis

```dart
// Optional: log raw data for post-processing
class DataLogger {
  final List<LogEntry> _log = [];
  
  void logSample({
    required Vector3 raw,
    required Vector3 baselineRemoved,
    required PCAResult? pca,
    required double phase,
    required bool valid,
  }) {
    _log.add(LogEntry(
      timestamp: DateTime.now(),
      raw: raw,
      baselineRemoved: baselineRemoved,
      pca: pca,
      phase: phase,
      valid: valid,
    ));
  }
  
  Future<void> exportToCSV(String filePath) async {
    // Export for offline analysis in Python/MATLAB
    final csv = _log.map((entry) => entry.toCSV()).join('\n');
    await File(filePath).writeAsString(csv);
  }
}
```

---

## Summary

The PCA-based phase tracking algorithm provides:

✅ **Orientation-independent** rotation detection  
✅ **Auto-calibration resistant** via baseline removal  
✅ **No manual configuration** required  
✅ **Fail-safe** with validity gating  
✅ **Low computational cost** (~5000 ops/sec)  
✅ **Deterministic** and mathematically rigorous  
✅ **Backward compatible** with legacy threshold mode  

**Next Steps**: Proceed to implementation tasks in `tasks.md`
