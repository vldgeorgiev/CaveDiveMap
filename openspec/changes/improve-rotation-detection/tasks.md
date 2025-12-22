# Implementation Tasks: PCA-Based Rotation Detection

## Current Status (December 22, 2025)

**Core Implementation**: ✅ COMPLETE
- PCA-based rotation detection fully implemented
- Custom Jacobi eigenvalue solver (no external dependencies)
- All pipeline components working
- UI integration complete
- Settings persistence working

**Recent Bug Fixes** (see issues.md for details):
- ✅ Fixed eigenvector interpretation (PC1/PC2 in plane, not PC2/PC3)
- ✅ Replaced planarity metric with flatness (λ3/sum)
- ✅ Fixed negative rotation count handling
- ✅ Added flatness gate hysteresis (0.20±0.05)
- ✅ Added frequency gate debouncing (10-sample average)
- ✅ Lowered motion threshold (0.001→0.0001)
- ✅ Relaxed counting requirements (planar + strong signal only)
- ✅ Increased motion gate averaging (10→50 samples)
- ✅ Fixed rotation count oscillation (track max absolute count)

**Active Issues**:
- 🔄 Testing interruption handling in field conditions

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
- [x] Implement flatness gate (λ3 / Σλ < 0.20 with 0.05 hysteresis) **CORRECTED**
- [x] Implement signal strength gate (5.0 < λ1 < 10000.0 μT²)
- [x] Implement frequency gate (< 10Hz with 10-sample debouncing)
- [x] Implement motion gate (> 0.0001 rad/sample with 50-sample averaging)
- [x] Add configurable threshold parameters
- [ ] Write unit tests for each gate independently
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
- [x] Add `ThresholdDetector` for legacy mode
- [x] Implement algorithm selection logic
- [x] Add `useLegacyDetection` flag
- [x] Update `_onMagnetometerEvent()` to route to active detector
- [x] Delegate getters to active detector
- [x] Implement detector initialization on service start
- [x] Add rotation count callback with absolute value tracking **FIXED**
- [ ] Add noise floor calibration on first launch
- [x] Test switching between PCA and legacy modes

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
- [ ] Add toggle: "Use PCA Detection (Recommended)"
- [ ] Show signal quality indicator (progress bar, 0-100%)
- [ ] Show rotation speed display (Hz)
- [ ] Add debug panel (collapsible):
  - Planarity value
  - Signal strength
  - Current phase
  - Cumulative phase
- [ ] Keep legacy threshold sliders (only show when legacy mode ON)
- [ ] Add algorithm information dialog
- [ ] Update help text

### UI Updates - Main Screen
- [ ] Add signal quality badge/indicator
- [ ] Update magnetometer readout to show X, Y, Z values
- [ ] Add visual feedback for rotation detection (flash/animation)
- [ ] Add algorithm name display (debug mode only)

## Phase 6: Testing & Validation (Week 6-7)

### Unit Tests
- [ ] Test BaselineRemoval with synthetic drift
- [ ] Test SlidingWindowBuffer edge cases
- [ ] Test PCAComputer with known covariance matrices
- [ ] Test PhaseUnwrapper with continuous rotations
- [ ] Test ValidityGates with borderline cases
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

### Real-World Testing - Orientation Independence
- [ ] Test portrait, face up (10 rotations)
- [ ] Test portrait, face down (10 rotations)
- [ ] Test landscape, face up (10 rotations)
- [ ] Test landscape, face down (10 rotations)
- [ ] Test edge up (10 rotations)
- [ ] Test edge down (10 rotations)
- [ ] Compare detected vs manual count for each
- [ ] Calculate accuracy percentage
- [ ] Target: >95% accuracy in all orientations

### Real-World Testing - Speed Variation
- [ ] Test very slow rotation (0.5 Hz, 30 seconds)
- [ ] Test normal rotation (1-2 Hz, 30 seconds)
- [ ] Test fast rotation (5 Hz, 10 seconds)
- [ ] Measure false negative rate
- [ ] Target: <5% missed rotations

### Real-World Testing - False Positive Resistance
- [ ] Perform figure-8 phone movements (30 seconds)
- [ ] Walk with phone while recording (2 minutes)
- [ ] Rotate phone 360° without wheel rotation
- [ ] Shake phone randomly
- [ ] Count false positive rotations
- [ ] Target: <1 false positive per test

### Real-World Testing - Long Session Stability
- [ ] Run continuous 5-minute session
- [ ] Compare measured distance to known distance
- [ ] Calculate drift percentage
- [ ] Test on iPhone 15/16
- [ ] Test on Samsung S21/S23
- [ ] Target: <10% drift over 5 minutes

### Real-World Testing - Multi-Device
- [ ] Test on iPhone 15
- [ ] Test on iPhone 16
- [ ] Test on Samsung S21
- [ ] Test on Samsung S23
- [ ] Test on 2-3 additional Android devices
- [ ] Compare accuracy across devices
- [ ] Document device-specific quirks

### Performance Benchmarking
- [ ] Measure per-sample processing time (baseline removal)
- [ ] Measure PCA computation time
- [ ] Measure total CPU usage during recording
- [ ] Measure memory footprint
- [ ] Measure battery drain over 60-minute session
- [ ] Compare to legacy threshold algorithm
- [ ] Target: <5% additional battery drain

## Phase 7: Documentation & Polish (Week 7)

### Code Documentation
- [ ] Add comprehensive dartdoc comments to all public APIs
- [ ] Document algorithm parameters and tuning guidelines
- [ ] Add inline comments for complex math operations
- [ ] Create algorithm flowchart diagram
- [ ] Document edge cases and failure modes

### User Documentation
- [ ] Update README with PCA algorithm description
- [ ] Create "How It Works" section explaining phase tracking
- [ ] Add troubleshooting guide for poor signal quality
- [ ] Document when to use legacy vs PCA mode
- [ ] Create video tutorial for advanced settings
- [ ] Update screenshots with new UI

### Migration Guide
- [ ] Write guide for users with existing threshold calibrations
- [ ] Explain benefits of new algorithm
- [ ] Provide comparison table (old vs new)
- [ ] Document rollback procedure (switch to legacy mode)

### Code Quality
- [ ] Run `dart analyze` and fix all warnings
- [ ] Run `dart format` on all modified files
- [ ] Review code for magic numbers → extract to constants
- [ ] Refactor duplicated code
- [ ] Add error handling for edge cases
- [ ] Security review (none expected for this change)

## Phase 8: Beta Testing & Release

### Beta Preparation
- [ ] Create feature flag for gradual rollout
- [ ] Set up A/B testing framework (if needed)
- [ ] Define rollout plan: beta → 25% → 50% → 100%
- [ ] Create rollback procedure
- [ ] Set up telemetry for signal quality tracking
- [ ] Set up crash reporting

### Beta Testing
- [ ] Recruit 10-20 beta testers
- [ ] Provide beta build via TestFlight (iOS)
- [ ] Provide beta build via Play Console Internal Testing (Android)
- [ ] Collect feedback survey results
- [ ] Monitor crash reports
- [ ] Track detection accuracy reports
- [ ] Iterate on issues found

### Production Release
- [ ] Merge to main branch
- [ ] Tag release version (e.g., v2.0.0)
- [ ] Build production artifacts
- [ ] Update version number in pubspec.yaml
- [ ] Write release notes highlighting new algorithm
- [ ] Submit to App Store (iOS)
- [ ] Submit to Play Store (Android)
- [ ] Monitor first 48 hours for critical issues

### Post-Release Monitoring
- [ ] Monitor crash rates (target: no increase)
- [ ] Monitor user reviews and ratings
- [ ] Track signal quality telemetry
- [ ] Analyze detection accuracy metrics
- [ ] Respond to user feedback
- [ ] Prepare hotfix if critical issues found

## Optional Enhancements (Future)

### Advanced Features
- [ ] Add rotation direction display (forward/backward)
- [ ] Implement adaptive window size based on rotation speed
- [ ] Add "net distance" vs "absolute distance" modes
- [ ] Implement rotation history visualization
- [ ] Add audio feedback on rotation detection

### ML Enhancement (Optional Gate, Not Counter)
- [ ] Train ML classifier to validate PCA output
- [ ] Use ML as additional quality gate (not primary counter)
- [ ] Collect user feedback data for model training
- [ ] Deploy model update mechanism

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
- [ ] Tune validity gate thresholds
- [ ] Adjust window size per use case
- [ ] Keep legacy mode as permanent option

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

- Focus on PCA algorithm only - ignore ML/FFT approaches from original spec
- Eigenvalue decomposition is critical - test ml_linalg library early
- Real-world testing is essential - synthetic data validates logic, not physics
- Keep legacy threshold mode as permanent fallback option
- Signal quality indicator is key UX feature - make it prominent
- Document all tuning parameters for future optimization


### Research & Analysis
- [ ] Review existing magnetometer data from test devices
- [ ] Analyze current false positive/negative rates
- [ ] Document orientation-specific failure modes
- [ ] Research TensorFlow Lite vs ONNX Runtime for Flutter
- [ ] Evaluate FFT library options for frequency analysis
- [ ] Define success metrics and testing protocol

### Development Environment
- [ ] Set up data collection infrastructure
- [ ] Create synthetic data generator for testing
- [ ] Implement logging framework for magnetometer readings
- [ ] Set up Python environment for model training
- [ ] Configure TensorFlow/Keras for model development

### Project Structure
- [ ] Create `lib/services/rotation_detection/` directory
- [ ] Define interface `IRotationDetector`
- [ ] Create base classes for detector implementations
- [ ] Set up test directory structure
- [ ] Add dependencies to `pubspec.yaml`:
  - `tflite_flutter` or `onnxruntime`
  - `fft` package
  - Testing utilities

## Phase 2: Algorithm Implementation (Week 2-3)

### Axis-Differential Detector
- [ ] Implement `CircularBuffer<T>` utility class
- [ ] Create `AxisDifferentialDetector` class
- [ ] Implement variance calculation across axes
- [ ] Implement dominant axis selection
- [ ] Implement peak detection on single axis
- [ ] Add rotation pattern verification
- [ ] Write unit tests with synthetic data
- [ ] Test on real device (orientation independence)

### Frequency-Domain Detector
- [ ] Integrate FFT library
- [ ] Create `FrequencyDomainDetector` class
- [ ] Implement magnitude buffer management
- [ ] Implement FFT analysis pipeline
- [ ] Implement dominant frequency extraction
- [ ] Add noise threshold calculation
- [ ] Write unit tests with synthetic data
- [ ] Test on real device (various rotation speeds)

### Legacy Threshold Mode
- [ ] Extract existing threshold logic to `ThresholdDetector` class
- [ ] Implement `IRotationDetector` interface
- [ ] Ensure backward compatibility
- [ ] Add unit tests for threshold detection
- [ ] Validate against current behavior

## Phase 3: ML Model Development (Week 3-4)

### Data Collection
- [ ] Implement `RotationDataCollector` class
- [ ] Add data collection UI toggle in settings
- [ ] Create labeled data export format (JSON)
- [ ] Record 50+ true rotation sequences (various orientations)
- [ ] Record 50+ false positive scenarios (figure-8, walking, etc.)
- [ ] Record data from multiple devices (iPhone, Samsung)
- [ ] Validate data quality and labeling

### Model Training (Python)
- [ ] Create `train_rotation_model.py` script
- [ ] Implement data loading and preprocessing
- [ ] Extract features (X, Y, Z, magnitude, derivatives)
- [ ] Implement data augmentation (rotation, noise injection)
- [ ] Build temporal CNN architecture
- [ ] Train model with cross-validation
- [ ] Evaluate on held-out test set (>95% accuracy target)
- [ ] Optimize model size (<100 KB target)
- [ ] Convert to TensorFlow Lite format

### Model Integration
- [ ] Add TensorFlow Lite model to Flutter assets
- [ ] Create `RotationClassifierModel` class
- [ ] Implement model loading and initialization
- [ ] Implement feature extraction pipeline
- [ ] Implement tensor preparation and inference
- [ ] Add error handling for model failures
- [ ] Write unit tests with synthetic data
- [ ] Test inference latency (<100ms target)
- [ ] Test on real devices (multiple models)

## Phase 4: Adaptive System (Week 4-5)

### Detector Orchestration
- [ ] Create `AdaptiveRotationDetector` class
- [ ] Implement algorithm selection logic
- [ ] Implement performance tracking per algorithm
- [ ] Implement automatic fallback mechanism
- [ ] Add user feedback collection interface
- [ ] Implement algorithm switching based on feedback
- [ ] Add telemetry and logging
- [ ] Write integration tests

### Service Integration
- [ ] Update `MagnetometerService` to use `AdaptiveRotationDetector`
- [ ] Replace direct threshold detection calls
- [ ] Maintain backward compatibility
- [ ] Add legacy mode toggle
- [ ] Implement detection error reporting methods
- [ ] Update UI notification triggers
- [ ] Test end-to-end rotation detection flow
- [ ] Validate distance calculation accuracy

## Phase 5: UI/UX Updates (Week 5)

### Settings Screen
- [ ] Add "Detection Algorithm" section
- [ ] Add toggle for "Use Advanced Detection"
- [ ] Show current active algorithm
- [ ] Add algorithm information dialog
- [ ] Add manual algorithm selection (for debugging)
- [ ] Add "Report Detection Issue" button
- [ ] Create feedback dialog UI
- [ ] Update threshold sliders (legacy mode only)
- [ ] Add detection accuracy indicator

### Main Survey Screen
- [ ] Add detection confidence indicator
- [ ] Add visual feedback for rotation detection
- [ ] Add "Undo Last Rotation" button
- [ ] Add "Add Missed Rotation" button
- [ ] Update magnetometer readout display
- [ ] Show active algorithm name (debug mode)

### Data Export
- [ ] Include detection algorithm info in CSV export
- [ ] Add detection confidence to survey data model
- [ ] Update export formats (CSV, Therion)

## Phase 6: Testing & Validation (Week 6)

### Unit Tests
- [ ] Test `AxisDifferentialDetector` with synthetic rotations
- [ ] Test frequency domain with known frequencies
- [ ] Test ML model with labeled test dataset
- [ ] Test adaptive selection logic
- [ ] Test CircularBuffer edge cases
- [ ] Test all detector implementations
- [ ] Achieve >90% code coverage

### Integration Tests
- [ ] Test full detection pipeline end-to-end
- [ ] Test algorithm switching scenarios
- [ ] Test legacy mode compatibility
- [ ] Test data persistence and loading
- [ ] Test export with new detection data

### Real-World Testing
- [ ] Test in 6 standard orientations (portrait/landscape × 3)
- [ ] Test with slow rotations (0.5 Hz)
- [ ] Test with fast rotations (5 Hz)
- [ ] Test figure-8 false positive resistance
- [ ] Test 5-minute continuous sessions
- [ ] Test on iPhone 15, 16
- [ ] Test on Samsung S21, S23
- [ ] Test on additional Android devices
- [ ] Compare accuracy vs. manual counting
- [ ] Measure battery impact

### Performance Benchmarking
- [ ] Measure per-sample processing time
- [ ] Measure memory footprint
- [ ] Measure battery drain over 60-minute session
- [ ] Measure detection latency
- [ ] Profile CPU usage
- [ ] Validate <5% battery overhead

## Phase 7: Documentation & Deployment (Week 7)

### Documentation
- [ ] Update README with new algorithm description
- [ ] Document algorithm selection strategy
- [ ] Create migration guide for existing users
- [ ] Document model training process
- [ ] Add troubleshooting guide
- [ ] Update API documentation
- [ ] Create video tutorial for advanced settings

### Code Quality
- [ ] Run static analysis (dart analyze)
- [ ] Fix all lint warnings
- [ ] Add code comments for complex logic
- [ ] Review and refactor as needed
- [ ] Update dependency versions
- [ ] Security review of ML model loading

### Deployment Preparation
- [ ] Create feature flag for gradual rollout
- [ ] Set up A/B testing framework
- [ ] Define rollout plan (beta → 25% → 50% → 100%)
- [ ] Create rollback procedure
- [ ] Set up monitoring and alerting
- [ ] Prepare release notes

### Beta Testing
- [ ] Recruit 10-20 beta testers
- [ ] Provide beta build (TestFlight/Play Console)
- [ ] Collect feedback and metrics
- [ ] Monitor detection accuracy reports
- [ ] Iterate on issues found
- [ ] Validate success criteria met

## Phase 8: Production Release

### Release
- [ ] Merge to main branch
- [ ] Tag release version
- [ ] Build production artifacts
- [ ] Submit to App Store (iOS)
- [ ] Submit to Play Store (Android)
- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Track detection accuracy metrics

### Post-Release
- [ ] Analyze telemetry data
- [ ] Identify improvement opportunities
- [ ] Plan model update schedule
- [ ] Collect additional training data
- [ ] Retrain model with production data
- [ ] Prepare version 2.0 improvements

## Milestone Checklist

### Milestone 1: Prototype Complete (End of Week 3)
- [ ] All three detectors implemented
- [ ] Basic tests passing
- [ ] Works on at least one test device

### Milestone 2: ML Model Trained (End of Week 4)
- [ ] Training data collected
- [ ] Model achieves >95% test accuracy
- [ ] Model integrated in Flutter app

### Milestone 3: Feature Complete (End of Week 5)
- [ ] Adaptive system working
- [ ] UI updates complete
- [ ] All integration tests passing

### Milestone 4: Validated & Ready (End of Week 6)
- [ ] Real-world testing complete
- [ ] Success criteria met
- [ ] Beta feedback incorporated

### Milestone 5: Released (End of Week 7)
- [ ] App submitted to stores
- [ ] Documentation complete
- [ ] Monitoring active

## Risk Mitigation Tasks

### If ML Model Fails to Load
- [ ] Ensure graceful fallback to axis-differential
- [ ] Log error for telemetry
- [ ] Show user-friendly message
- [ ] Continue normal operation

### If Accuracy is Worse Than Legacy
- [ ] Add prominent "Use Classic Detection" toggle
- [ ] Make classic mode the default
- [ ] Collect data to understand failure modes
- [ ] Iterate on algorithms

### If Battery Impact Too High
- [ ] Reduce sampling rate (100Hz → 50Hz)
- [ ] Optimize model inference
- [ ] Add "Power Saving Mode" option
- [ ] Use simpler algorithm (axis-differential)

### If Cross-Device Consistency Poor
- [ ] Train separate models per device family
- [ ] Implement device-specific calibration
- [ ] Add device detection and algorithm tuning
- [ ] Collect more diverse training data

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

- Prioritize axis-differential detector first (simplest, no ML dependency)
- ML model is aspirational - may be deferred to v2.0 if timeline tight
- Maintain legacy threshold mode indefinitely as fallback
- Real-world testing is critical - synthetic data only validates logic, not physics
- Consider adding "Calibration Wizard" to guide users through optimal setup
