# Change Proposal: Improve Rotation Detection Algorithm

## Summary

Improve the magnetometer-based wheel rotation detection algorithm to work reliably across all phone orientations, overcome OS auto-calibration effects, and reduce false positives from figure-8 phone movements. Threshold detection remains the default; PCA phase tracking is offered as an opt-in beta path.

## Problem Statement

The current peak detection algorithm has several critical limitations:

### Current Algorithm Description

The existing system uses a simple dual-threshold peak detection approach:

**Algorithm**: Magnitude-based threshold detection
```
1. Calculate magnitude = sqrt(x² + y² + z²) from magnetometer readings
2. Wait for magnitude > maxPeakThreshold (e.g., 100 μT)
3. Count as rotation when detected
4. Wait for magnitude < minPeakThreshold (e.g., 50 μT) before next peak
```

**Parameters**:
- Sampling rate: ~100Hz (10ms intervals)
- Min threshold: 50 μT (configurable)
- Max threshold: 100 μT (configurable)
- Recent max buffer: 3 samples (~60ms window)

### Key Limitations

#### 1. Orientation Dependency
**Problem**: The magnetic field magnitude changes significantly based on phone orientation relative to Earth's magnetic field (~50 μT). When the magnet's field (~100-200 μT near the wheel) combines with Earth's field, the resulting magnitude varies by orientation:
- Parallel alignment: Fields add (higher magnitude)
- Perpendicular alignment: Fields combine at angles (lower magnitude)
- Anti-parallel: Fields partially cancel (lowest magnitude)

**Impact**: Thresholds that work in one orientation fail in others. User must recalibrate when changing phone position.

#### 2. OS Auto-Calibration
**Problem**: Modern smartphones automatically compensate for local magnetic fields to improve compass accuracy. This is intended behavior for compass apps but problematic for our use case:
- OS gradually normalizes the magnet's field
- Magnitude readings decrease over time as calibration adapts
- Previously set thresholds become invalid after ~30-60 seconds

**Impact**: Detection stops working mid-survey, requiring recalibration or threshold adjustment.

#### 3. False Positives from Phone Movement
**Problem**: Moving the phone in figure-8 patterns (common during calibration or orientation changes) causes magnitude fluctuations that can trigger false rotation counts.

**Impact**: Distance measurements include phantom rotations, reducing survey accuracy.

#### 4. Manual Threshold Configuration
**Problem**: Users must manually determine and set min/max thresholds through trial and error:
- Requires understanding of μT units
- No visual feedback during configuration
- Different values needed per device and orientation

**Impact**: Poor user experience, especially for non-technical divers. High barrier to entry.

## Proposed Solution

Implement a **PCA-based phase tracking** rotation detection system that:

1. **Orientation Independence**: Measures angular phase of 3D magnetic field vector, not magnitude
2. **Auto-Calibration Resistance**: Subtracts rolling baseline per axis to remove Earth field and drift
3. **Geometric Approach**: Uses geometry of rotating field, not amplitude peaks or thresholds
4. **Self-Validating**: Automatic quality gates ensure only valid rotation signals are counted

### Key Features

- **Phase-based counting**: Each 2π phase advance = one rotation
- **PCA plane projection**: Finds dominant rotation plane automatically
- **Baseline removal**: Adaptive per-axis baseline subtraction eliminates drift
- **Validity gating**: Planarity, signal strength, frequency, and coherence checks
- **Fail-safe**: No false counts when signal quality is poor
- **Minimal configuration**: Only wheel circumference required from user

## Impact Analysis

### Benefits

**Users**:
- Works in any phone orientation without recalibration
- Eliminates manual threshold configuration
- More accurate distance measurements
- Better underwater usability (less fiddling with settings)

**System**:
- More robust detection algorithm
- Reduced false positives/negatives
- Better handling of device variations
- Foundation for future ML-based improvements

**Development**:
- Opens door to other ML applications (depth estimation, passage width detection)
- Cleaner separation of signal processing from UI
- Better testability with synthetic data

### Risks

**Technical**:
- PCA computation may be too expensive on very old devices
- Phase unwrapping edge cases at exactly 0/2π boundaries
- Noise floor determination needs per-device testing
- Very slow rotations (<0.2 Hz) may need longer windows

**User Experience**:
- New algorithm may behave differently than users expect
- Signal quality indicator needs clear visual design
- Transition from threshold-based to phase-based needs explanation

**Migration**:
- Existing users with calibrated thresholds need migration path
- Threshold-based mode retained as fallback option
- Beta testing required to validate improvements across devices

### Mitigation Strategies

- PCA only on 1-second windows (50-150 samples) - very low cost
- Phase unwrapping is standard, well-tested algorithm
- Quality gates prevent false counts when signal poor
- Maintain threshold-based mode as "Classic" option in settings
- Provide clear migration guide and in-app explanations

## Scope

### In Scope

- Design and implement ML-based rotation detection algorithm
- Feature engineering from magnetometer X/Y/Z data
- Model training pipeline with synthetic and real data
- Real-time inference integration in `MagnetometerService`
- Fallback to threshold-based detection
- User feedback mechanism for detection quality
- Documentation and testing

### Out of Scope

- Cloud-based model training infrastructure
- Automated data collection from production users (privacy concerns)
- Integration with other sensors (gyroscope, accelerometer)
- Complete removal of threshold-based algorithm
- iOS-specific implementations (focus on Flutter/cross-platform)

## Success Criteria

1. **Orientation Independence**: 95%+ accuracy in 6 standard orientations (portrait/landscape × 3 rotations)
2. **Auto-Calibration Resistance**: Maintains 90%+ accuracy for 5 minutes without threshold adjustment
3. **False Positive Rate**: <2% false rotations during figure-8 phone movements
4. **Detection Latency**: <100ms from physical rotation to detection
5. **User Satisfaction**: Beta testers report "improved" or "much improved" accuracy
6. **Battery Impact**: <5% additional battery drain during typical 60-minute dive

## Timeline Estimate

- **Research & Design**: 1 week
- **PCA Implementation**: 1 week
- **Baseline & Gating Logic**: 1 week
- **Phase Tracking**: 1 week
- **Integration & UI**: 1 week
- **Testing & Refinement**: 2 weeks
- **Total**: 7 weeks

## Dependencies

- Access to multiple phone models for testing (iPhone 15/16, Samsung S21/S23 minimum)
- 3D-printed wheel device for data collection
- Linear algebra library for Dart/Flutter (eigenvalue decomposition)
- Test data from real underwater surveys for validation

## Alternatives Considered

### 1. Machine Learning Classification
- Train CNN or LSTM to classify rotation patterns
- Requires labeled training data collection
- Model file increases app size

**Rejected because**: PCA phase tracking is deterministic, requires no training, and is provably correct from first principles

### 2. FFT-Only Frequency Detection
- Fourier analysis to detect rotation frequency
- Estimate rotation count from dominant frequency

**Rejected because**: Frequency alone doesn't give rotation count, only average rate; loses individual rotation timing

### 3. Multi-Sensor Fusion
- Combine magnetometer with gyroscope and accelerometer
- Use IMU data to detect phone motion separately from wheel rotation

**Rejected because**: Increases complexity, battery drain; magnetometer alone is sufficient with proper processing

### 4. Peak Detection on Single Axis
- Use single strongest axis (X, Y, or Z) instead of magnitude
- Switch axes dynamically based on orientation

**Rejected because**: Still has threshold tuning issues; PCA finds optimal projection automatically

## Open Questions

1. What is the optimal PCA window size (0.5s vs 1.0s vs 2.0s)?
2. Should we use covariance or correlation matrix for PCA?
3. What are the appropriate threshold values for planarity, signal strength, and coherence gates?
4. How do we determine noise floor per device automatically?
5. Should rotation direction (forward/backward) be tracked and displayed?

## Stakeholder Input Needed

- **Beta Testers**: Real-world testing in underwater conditions
- **Hardware Team**: Magnet placement recommendations for optimal signal
- **UX Team**: Design for "learning mode" feedback and threshold migration

## References

- Current implementation: `flutter-app/lib/services/magnetometer_service.dart`
- Original Swift version: `archive/swift-ios-app/cave-mapper/MagnetometerViewModel 2.swift`
- README limitations: `README.md` lines 115-133
- Related spec: To be created in `openspec/specs/magnetometer-measurement/`
