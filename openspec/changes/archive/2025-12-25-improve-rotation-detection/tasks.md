# Implementation Tasks: PCA-Based Rotation Detection

## Current Status (January 2026)

**Core Implementation**: ✅ COMPLETE (uncalibrated-only PCA as beta; threshold algorithm remains default)
- PCA pipeline: uncalibrated magnetometer input, baseline alpha ~0.02, basis locking, long motion/coherence histories, emission gating
- Auto-start listening/recording on launch; restart after Settings
- UI: PCA signal quality in main, uncalibrated readout and unsupported error in Settings

**Recent Bug Fixes/Changes**:
- ✅ Uncalibrated EventChannel on Android and service integration; detection uses uncalibrated values only
- ✅ Basis locking and gated emission (no reset on gate failure)
- ✅ Planarity tolerance/hysteresis and long motion/coherence averaging tuned for slow/jerky rotation (values still adjustable during beta)
- ✅ Logging throttled/compact; stall warning when uncal stream stops

**Active Issues**:
- 🔄 Interruption handling after wheel removal/reattach (baseline/plane rebuild heuristics)
- 🛈 Uncalibrated magnetometer required; show error when unavailable

---

## Phase 1: Foundation & Utilities (Week 1)

### Research & Analysis
- [x] Review existing magnetometer data from test devices
- [x] Analyze current false positive/negative rates in different orientations
- [x] Document orientation-specific failure modes
- [x] Research Dart linear algebra libraries (implemented custom Jacobi solver)
- [x] Define success metrics and testing protocol

### Development Environment
- [x] Set up synthetic data generator for testing
- [x] Implement logging framework for magnetometer readings
- [x] Create test harness for accuracy measurement
- [ ] Set up CSV export for offline analysis

### Project Structure
- [x] Create `lib/services/rotation_detection/` directory
- [x] Create `lib/services/rotation_detection/pca/` subdirectory
- [x] Define core data structures (Vector3, Vector2, PCAResult)
- [x] Set up test directory structure
- [x] Add dependencies to `pubspec.yaml` (used sensors_plus 7.0.0)

### Utility Classes
- [x] Implement `Vector3` class (x, y, z) with dot product, magnitude
- [x] Implement `Vector2` class (u, v) for 2D projections
- [x] Implement `CircularBuffer<T>` with fixed size and efficient add/remove
- [ ] Write unit tests for utility classes

## Phase 2: Core Algorithm Components (Week 2)

### Baseline Removal
- [x] Create `BaselineRemoval` class
- [x] Implement EMA-based baseline tracking (per-axis)
- [x] Add configurable alpha parameter (time constant = 0.01)
- [x] Implement reset() method
- [ ] Write unit tests with synthetic drift data
- [x] Test on real device (verify Earth field removal)

### Sliding Window Buffer
- [x] Create `SlidingWindowBuffer` class
- [x] Implement fixed-size FIFO buffer using Queue
- [x] Add configurable window size (2s = 200 samples @ 100Hz)
- [x] Implement isFull property
- [ ] Write unit tests for buffer operations
- [x] Test memory efficiency

### PCA Computation
- [x] Create `PCAComputer` class
- [x] Implement data centering (mean subtraction)
- [x] Implement 3×3 covariance matrix computation
- [x] Integrate eigenvalue decomposition (custom Jacobi solver)
- [x] Implement eigenvalue/eigenvector sorting (descending)
- [x] Compute explained variance ratios
- [x] Add PCAResult data class with flatness and signalStrength getters
- [ ] Write unit tests with known synthetic data
- [x] Validate against known eigenvector solutions (via field testing)

### Projection & Phase
- [x] Create `PCAProjector` class
- [x] Implement projection to 2D PCA plane (dot products with PC1, PC2) **CORRECTED**
- [x] Create `PhaseComputer` class
- [x] Implement phase calculation using atan2(v, u)
- [ ] Write unit tests for phase computation
- [x] Test all quadrants (-π to π)

## Phase 3: Phase Tracking & Validation (Week 3)

### Phase Unwrapping
- [x] Create `PhaseUnwrapper` class
- [x] Implement phase difference calculation
- [x] Implement wrap detection at ±π boundaries
- [x] Implement cumulative phase tracking
- [x] Implement rotation counting (every 2π)
- [x] Add direction tracking (forward/backward)
- [x] Implement reset() method
- [ ] Write unit tests with synthetic wrapped phases
- [x] Test continuous rotation scenarios

### Validity Gating
- [x] Create `ValidityGates` class
- [x] Implement flatness gate (current: 0.30 with 0.05 hysteresis)
- [x] Implement signal strength gate (5.0 < λ1 < 10000.0 μT²)
- [x] Implement frequency gate (< 10Hz with debouncing)
- [x] Implement motion gate (current: 0.000005 rad/sample, 2s averaging)
- [x] Add configurable threshold parameters
- [x] Write unit tests for each gate independently
- [x] Test combined gating logic

### Noise Floor Calibration
- [ ] Implement automatic noise floor detection
- [ ] Collect baseline samples with wheel stationary
- [ ] Compute standard deviation of baseline-removed signal
- [ ] Set minSignalStrength = 3 × std_dev
- [ ] Save calibrated value to preferences
- [ ] Add manual recalibration option in settings

## Phase 4: Main Detector Integration (Week 4)

### PCA Rotation Detector
- [x] Create `PCARotationDetector` class extending ChangeNotifier
- [x] Integrate all component classes
- [x] Implement onMagnetometerEvent() pipeline
- [x] Add configurable PCA computation frequency (every sample)
- [x] Implement signal quality computation (0-100%)
- [x] Implement rotation speed estimation (dθ/dt)
- [x] Add rotation detection callback with max absolute count tracking **FIXED**
- [x] Implement reset() method
- [x] Add wheel circumference setter
- [ ] Write integration tests

### Performance Optimization
- [x] Profile PCA computation cost
- [x] Optimize eigenvalue decomposition (custom Jacobi for 3×3 symmetric)
- [x] Reduce PCA frequency if needed (computed every sample, acceptable performance)
- [x] Implement efficient covariance computation
- [x] Add performance metrics logging
- [x] Test on real devices (acceptable performance at 100Hz)

### Legacy Threshold Detector
- [x] Extract existing threshold logic to separate implementation
- [x] Ensure identical behavior to current implementation
- [ ] Add unit tests validating backward compatibility

## Phase 5: Service Integration (Week 5)

### MagnetometerService Updates
- [x] Add `PCARotationDetector` instance to `MagnetometerService`
- [x] Add `ThresholdDetector` for default threshold mode
- [x] Implement algorithm selection logic
- [x] Add `useLegacyDetection` flag
- [x] Update `_onMagnetometerEvent()` to route to active detector
- [x] Delegate getters to active detector
- [x] Implement detector initialization on service start
- [x] Add rotation count callback with absolute value tracking **FIXED**
- [ ] Add noise floor calibration on first launch
- [x] Test switching between PCA and threshold modes
- [x] Use uncalibrated magnetometer EventChannel (Android) and error when unsupported
- [x] Auto-start listening/recording and restart after Settings

### Settings Model Updates
- [x] Add `useLegacyDetection` setting (default: false = PCA)
- [x] Add `pcaWindowSize` setting (default: 2.0 seconds)
- [x] Add `showDebugInfo` setting
- [x] Persist settings across app restarts
- [x] Add migration logic for existing threshold settings

### UI Updates - Settings Screen
- [x] Add "Detection Algorithm" section
- [x] Add toggle for PCA vs Legacy detection
- [x] Add signal quality display (flatness-based percentage)
- [x] Add individual gate status indicators
- [x] Add debug info panel (expandable)
- [x] Show rotation count and phase information
- [x] Add "Advanced" section for PCA parameters
- [ ] Test UI responsiveness during high-frequency updates
- [X] Show signal quality indicator (progress bar, 0-100%)
- [ ] Add debug panel (collapsible):
  - Planarity value
  - Signal strength
  - Current phase
  - Cumulative phase
- [X] Keep threshold sliders (only show when threshold mode ON)
- [ ] Add algorithm information dialog
- [ ] Update help text

### UI Updates - Main Screen
- [x] Signal quality indicator for PCA
- [x] Magnetic field bar (uncalibrated)
- [ ] Add visual feedback for rotation detection (flash/animation)
- [ ] Add algorithm name display (debug mode only)

## Phase 6: Testing & Validation (Week 6-7) — Not started

### Unit Tests
- [ ] Test BaselineRemoval with synthetic drift
- [ ] Test SlidingWindowBuffer edge cases
- [ ] Test PCAComputer with known covariance matrices
- [ ] Test PhaseUnwrapper with continuous rotations
- [x] Test ValidityGates with borderline cases
- [ ] Test full PCARotationDetector with synthetic rotations
- [ ] Achieve >90% code coverage

### Synthetic Data Tests
- [ ] Generate perfect circular rotation (1 Hz, 2 seconds) → expect 2 rotations
- [ ] Generate noisy circular rotation → verify noise rejection
- [ ] Generate figure-8 movement → expect 0 rotations
- [ ] Generate random 3D noise → expect 0 rotations
- [ ] Generate very slow rotation (0.2 Hz) → verify detection
- [ ] Generate fast rotation (5 Hz) → verify detection
- [ ] Generate rotation with baseline drift → verify drift compensation

## Phase 7: Documentation & Polish (Week 7) — Not started

### User Documentation
- [ ] Update README with PCA algorithm description
- [ ] Create "How It Works" section explaining phase tracking
- [ ] Add troubleshooting guide for poor signal quality
- [ ] Document when to use threshold vs PCA mode
- [ ] Create video tutorial for advanced settings
- [ ] Update screenshots with new UI

## Milestone Checklist

### Milestone 1: Core Algorithm Complete (End of Week 3)
- [ ] All PCA components implemented
- [ ] Unit tests passing
- [ ] Works on synthetic data

### Milestone 2: Integration Complete (End of Week 5)
- [ ] Integrated into MagnetometerService
- [ ] UI updates complete
- [ ] Legacy mode working

### Milestone 3: Validation Complete (End of Week 7)
- [ ] Real-world testing done
- [ ] Success criteria met (>95% accuracy)
- [ ] Performance targets met (<5% battery)

### Milestone 4: Released (End of Week 8)
- [ ] Beta testing complete
- [ ] Production release submitted
- [ ] Monitoring active

## Success Validation Checklist

Before considering this change complete, verify:

- [ ] **Orientation Independence**: >95% accuracy in all 6 orientations
- [ ] **Auto-Calibration Resistance**: >90% accuracy after 5 minutes
- [ ] **False Positive Rate**: <2% during figure-8 movements
- [ ] **Detection Latency**: <200ms average (PCA runs every 10 samples)
- [ ] **User Satisfaction**: Beta testers rate 4+/5 stars
- [ ] **Battery Impact**: <5% additional drain
- [ ] **Cross-Device**: Works on all tested devices
- [ ] **No Regressions**: Legacy mode still works perfectly
- [ ] **Documentation**: Complete and accurate
- [ ] **Production Ready**: Passes all quality gates

## Risk Mitigation Tasks

### If Eigenvalue Decomposition Too Slow
- [ ] Profile and optimize covariance computation
- [ ] Reduce PCA frequency (every 20 samples instead of 10)
- [ ] Use faster symmetric eigenvalue solver
- [ ] Consider custom 3×3 analytical solver

### If Accuracy Lower Than Legacy in Some Cases
- [ ] Identify failure modes via telemetry
- [x] Tune validity gate thresholds
- [ ] Adjust window size per use case
- [ ] Keep threshold mode as permanent option

### If Battery Impact Too High
- [ ] Reduce PCA computation frequency
- [ ] Optimize matrix operations
- [ ] Add "Power Saving Mode" (larger window, less frequent PCA)
- [ ] Profile and optimize hot paths

### If Cross-Device Consistency Poor
- [ ] Implement per-device noise floor calibration
- [ ] Add device-specific tuning profiles
- [ ] Collect more diverse test data
- [ ] Document known device limitations

## Notes

- Uncalibrated magnetometer input is required for reliable detection
- Real-world testing is essential - synthetic data validates logic, not physics
- Keep threshold mode as the default option (uncalibrated feed)
- Signal quality indicator is key UX feature - make it prominent
- Document all tuning parameters for future optimization


- [ ] Test end-to-end rotation detection flow
- [ ] Validate distance calculation accuracy

## Phase 5: UI/UX Updates (Week 5)

### Settings Screen
- [X] Add "Detection Algorithm" section
- [X] Add toggle for "Use Advanced Detection"
- [X] Show current active algorithm
- [X] Update threshold sliders (threshold mode only)

## Success Validation Checklist

Before considering this change complete, verify:

- [ ] **Orientation Independence**: >95% accuracy in all 6 orientations
- [ ] **Auto-Calibration Resistance**: >90% accuracy after 5 minutes
- [ ] **False Positive Rate**: <2% during figure-8 movements
- [ ] **Detection Latency**: <100ms average
- [ ] **User Satisfaction**: Beta testers rate 4+/5 stars
- [ ] **Battery Impact**: <5% additional drain
- [ ] **Cross-Device**: Works on all tested devices
- [ ] **No Regressions**: Legacy mode still works perfectly
- [ ] **Documentation**: Complete and accurate
- [ ] **Production Ready**: Passes all quality gates

## Notes

- Maintain threshold mode indefinitely as default/baseline
- Real-world testing is critical - synthetic data only validates logic, not physics
- Consider adding "Calibration Wizard" to guide users through optimal setup
