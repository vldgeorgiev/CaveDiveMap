# Implementation Tasks: Fractional Rotation Tracking

## 1. Core Implementation

### 1.1 PCARotationDetector Enhancements
- [ ] Add `fractionalRotations` getter using `_forwardPhaseAccum / (2π)`
- [ ] Add `continuousDistance` getter using `fractionalRotations × wheelCircumference`
- [ ] Add `minPhaseForDistanceUpdate` field to `PCARotationConfig`
- [ ] Add `_lastEmittedPhase` tracking variable
- [ ] Add `onDistanceUpdate` callback field
- [ ] Implement distance update interval check in `processSample()`
- [ ] Emit distance updates when phase advance ≥ threshold and gates pass
- [ ] Update `wheelCircumference` setter to work with new getters

### 1.2 MagnetometerService Integration
- [ ] Add `fractionalDistance` getter for PCA mode
- [ ] Ensure threshold mode continues using integer rotations
- [ ] Subscribe to `onDistanceUpdate` callback from PCA detector
- [ ] Forward distance updates to UI via `notifyListeners()`
- [ ] Add getter for `fractionalRotations` (diagnostic/debug)

## 2. Configuration

### 2.1 Default Configuration
- [ ] Set `minPhaseForDistanceUpdate = π/9` (20°) as default
- [ ] Document configuration parameter in code comments
- [ ] Ensure configuration is passed through initialization chain

## 3. Testing

### 3.1 Unit Tests
- [ ] Test `fractionalRotations` accuracy (0.5, 1.25, 2.75 rotations)
- [ ] Test `continuousDistance` calculation with various wheel sizes
- [ ] Test distance update interval (verify callbacks at 20° steps)
- [ ] Test that distance updates respect validity gates
- [ ] Test backward rotation handling (absolute value)
- [ ] Test edge case: zero rotations
- [ ] Test edge case: very slow rotation (< 1 RPM)
- [ ] Test that integer `rotationCount` remains unchanged

### 3.2 Integration Tests
- [ ] Test MagnetometerService exposes fractional distance correctly
- [ ] Test algorithm switching (PCA ↔ threshold) handles distance correctly
- [ ] Test session reset clears fractional accumulator
- [ ] Verify no performance regression (CPU usage)
- [ ] Verify distance updates don't fire during invalid signals

## 4. Documentation

### 4.1 Code Documentation
- [ ] Add dartdoc comments to `fractionalRotations` getter
- [ ] Add dartdoc comments to `continuousDistance` getter
- [ ] Add dartdoc comments to `minPhaseForDistanceUpdate` parameter
- [ ] Document distance update callback behavior
- [ ] Add usage examples in class-level documentation

### 4.2 Specification
- [ ] Complete spec delta in `specs/magnetometer-measurement/spec.md`
- [ ] Add acceptance scenarios for fractional tracking
- [ ] Document configuration parameters
- [ ] Update design documentation if needed

## 5. Validation

### 5.1 Manual Testing
- [ ] Test with slow wheel rotation (< 1 RPM) - distance updates visible
- [ ] Test with fast wheel rotation (3-5 RPM) - smooth distance progression
- [ ] Test with partial rotation (90°, 180°, 270°) - correct fractional values
- [ ] Test with backward rotation - distance still increases
- [ ] Test with figure-8 phone motion - no false distance accumulation
- [ ] Test with phone rotation - no false distance accumulation
- [ ] Test algorithm switch mid-session - clean state transition

### 5.2 Performance Testing
- [ ] Monitor CPU usage during distance updates
- [ ] Verify notification rate matches configuration (5-10 Hz at 1 RPS)
- [ ] Check memory allocation patterns
- [ ] Verify battery drain unchanged

## 6. Deployment

### 6.1 Pre-Release
- [ ] Run all unit tests
- [ ] Run all integration tests
- [ ] Verify backward compatibility (apps using old API work)
- [ ] Code review
- [ ] Performance benchmarks
- [ ] Run `openspec validate add-fractional-rotation-tracking --strict`

### 6.2 Release
- [ ] Merge feature branch
- [ ] Deploy to test environment
- [ ] Beta testing with real wheel device
- [ ] Deploy to production
- [ ] Monitor for issues
- [ ] Archive change proposal

## Success Criteria

All tasks must be completed AND:
- [x] Fractional rotation accuracy ±2% over 10 rotations
- [x] Distance updates at ~20° intervals during rotation
- [x] No false positives during figure-8 motion
- [x] Performance overhead < 1% CPU
- [x] All existing tests still pass
- [x] Zero breaking changes to public API

## Milestones

- **M1** (Day 1): Core getters implemented and tested
- **M2** (Day 2): Distance update intervals working
- **M3** (Day 3): Integration complete, all tests passing
- **M4** (Day 4): Manual testing and performance validation
- **M5** (Day 5): Documentation complete, ready for release
