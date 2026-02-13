# Proposal: Add Fractional Rotation Tracking

**Change ID**: `add-fractional-rotation-tracking`  
**Type**: Feature Enhancement  
**Status**: Proposed  
**Created**: 2026-01-17

## Summary

Enable continuous distance measurement during partial wheel rotations by exposing fractional rotation values from the PCA phase tracking algorithm. This allows distance updates at any point during rotation (e.g., every 10-20 degrees) rather than only after complete 2π cycles.

## Motivation

### Current State Problems

1. **Full Rotation Requirement**: Distance only updates after complete 360° rotations
2. **Coarse Granularity**: For 26.3cm wheel circumference, minimum distance increment is 26.3cm
3. **Delayed Feedback**: No visual feedback during slow or partial rotations
4. **Poor UX for Short Movements**: Walking 10cm forward shows 0cm until full rotation completes
5. **Wasted Data**: Phase tracking already measures continuous angles but truncates to integer rotations

### Current Algorithm Capabilities

The PCA phase tracking algorithm **already computes** all necessary data:
- Continuous phase angle θ(t) via `atan2(v, u)` every sample (~10ms)
- Accumulated phase via `PhaseUnwrapper` tracking total phase advance
- Phase changes measured at 100Hz sample rate

Current limitation: Only **emits** rotation counts after 2π advances.

### Benefits of Fractional Tracking

1. **Continuous Distance**: Distance updates smoothly during rotation
2. **Fine Granularity**: Updates every 10-20° (2-5cm for 26.3cm wheel)
3. **Immediate Feedback**: UI shows progress during slow rotations
4. **Better UX**: Responsive distance display matches user expectations
5. **Zero Calibration**: Inherits PCA's self-calibrating behavior
6. **Same Accuracy**: No new algorithms, just exposes existing phase data
7. **Backward Compatible**: Integer rotation count still available

### Success Criteria

- [ ] Fractional rotations exposed as public getter (e.g., `1.25` = 1¼ rotations)
- [ ] Continuous distance computed from fractional rotations
- [ ] Configurable distance update frequency (default: every 20°)
- [ ] Distance updates respect all existing validity gates (planarity, signal strength, coherence, inertial)
- [ ] False positive rejection maintained (figure-8 motion, phone rotation)
- [ ] Works without calibration (same as current PCA)
- [ ] UI updates smoothly without performance degradation
- [ ] Threshold mode compatibility (full rotations only)

## Scope

### In Scope

- Add `fractionalRotations` getter to `PCARotationDetector`
- Add `continuousDistance` getter to `PCARotationDetector`
- Add configurable `minPhaseForDistanceUpdate` parameter
- Distance update callback with configurable phase intervals
- Expose fractional distance in `MagnetometerService`
- Unit tests for fractional distance accuracy
- Integration with existing validity gates
- Backward compatibility with integer rotation count

### Out of Scope

- New detection algorithms or calibration procedures
- Changes to validity gate logic
- Sector-based quantization (future enhancement)
- Ultra-precision calibration mode (future enhancement)
- Threshold algorithm fractional tracking (would require signal processing changes)
- UI changes (separate task)

### Dependencies

- Existing PCA rotation detection (REQ-MAG-001)
- Phase unwrapping logic in `PhaseUnwrapper`
- Validity gates (REQ-MAG-005, REQ-MAG-006)
- `MagnetometerService` integration

## Technical Approach

### Architecture

**No new algorithms needed** - only expose existing computed data:

```
Existing Pipeline:
  PhaseUnwrapper
    ↓
  _totalPhase (continuous, already computed)
    ↓
  _rotationCount = floor(_totalPhase / 2π)  ← Currently used
    
New Addition:
  fractionalRotations = _totalPhase / 2π    ← Simply expose the raw value
    ↓
  continuousDistance = fractionalRotations × wheelCircumference
```

### Implementation Details

**1. Fractional Rotation Getter**
```dart
double get fractionalRotations {
  // Use _totalForwardPhase (separate accumulator for fractional tracking)
  return _totalForwardPhase.abs() / (2 * pi);
}
```

**2. Continuous Distance Getter**
```dart
double get continuousDistance {
  return fractionalRotations * wheelCircumference;
}
```

**3. Phase Accumulation with Validity Gating**
```dart
// CRITICAL: Only accumulate fractional phase during valid signals
final signedPhaseChange = _forwardSign == 0 ? phaseChange : phaseChange * _forwardSign;
if (signedPhaseChange > 0) {
  _forwardPhaseAccum += signedPhaseChange; // For integer rotation count
  // Only accumulate fractional distance when validity gates pass
  if (canEmit) {
    _totalForwardPhase += signedPhaseChange;
  }
}
```

**4. Configurable Distance Updates**
```dart
// In config
final double minPhaseForDistanceUpdate; // Default: π/9 ≈ 20°

// In detector
double _lastEmittedPhase = 0.0;
Function()? onDistanceUpdate;

// Check for distance update interval
final phaseAdvance = (_totalForwardPhase - _lastEmittedPhase).abs();
if (phaseAdvance >= config.minPhaseForDistanceUpdate && canEmit) {
  _lastEmittedPhase = _totalForwardPhase;
  onDistanceUpdate?.call();
  notifyListeners();
}
```

### False Positive Prevention

**Critical Design Decision:**
⚠️ **Phase accumulation MUST be gated by validity checks** - Early implementation accumulated phase regardless of validity, causing distance to increase from noise and invalid signals (e.g., stationary phone on desk).

**Correct Implementation:**
- `_totalForwardPhase` only accumulates when `canEmit == true`
- This ensures ALL validity gates pass before distance advances
- Prevents false positives from signal noise, weak signals, or invalid motion

**Inherited Validity Gates:**

- ✅ **Coherence gate**: Rejects figure-8 motion (coherence < 0.4)
- ✅ **Inertial gate**: Rejects phone rotation (gyro > 6 rad/s)
- ✅ **Planarity gate**: Requires 2D rotation plane (flatness < 0.3)
- ✅ **Signal strength gate**: Requires strong magnet signal (λ1 > 5 μT²)
- ✅ **Frequency gate**: Rejects impossibly fast changes (> 10 Hz)

Distance updates only occur when `canEmit` is true (all gates pass).

### Edge Cases

1. **Slow rotations**: Fractional tracking improves UX (shows progress)
2. **Backward rotation**: Uses absolute value, consistent with current behavior
3. **Stopped wheel**: No distance update (hasPhaseMotion gate fails)
4. **Brief signal loss**: Grace periods maintain counting (existing behavior)
5. **Threshold mode**: Falls back to integer rotations (no fractional support)

## Impact

### Affected Specifications

- `magnetometer-measurement` - Add fractional rotation requirements

### Affected Code

- `flutter-app/lib/services/rotation_detection/pca_rotation_detector.dart` - Add getters and distance update logic
- `flutter-app/lib/services/magnetometer_service.dart` - Expose fractional distance
- `flutter-app/lib/screens/map_screen.dart` - Display continuous distance (separate task)

### Migration Path

**Backward compatible** - no breaking changes:
- Existing `rotationCount` getter unchanged
- New `fractionalRotations` getter added alongside
- Apps not using fractional values work identically

### Performance Impact

- **CPU**: Negligible (one division per update interval, ~5-10 Hz)
- **Memory**: +16 bytes (2 doubles: `_lastEmittedPhase`, `minPhaseForDistanceUpdate`)
- **Battery**: No measurable impact
- **UI updates**: Configurable frequency prevents excessive redraws

### Risks

1. **Risk**: Excessive UI updates if not throttled
   - **Mitigation**: Configurable update interval (default: 20°)
   
2. **Risk**: Confusion between integer and fractional rotation counts
   - **Mitigation**: Clear naming (`rotationCount` vs `fractionalRotations`)
   
3. **Risk**: Accumulation of small errors over long sessions
   - **Mitigation**: Uses same accumulator as integer counts (proven accurate)

## Alternatives Considered

### Alternative 1: Sector-Based Quantization
Divide rotation into fixed sectors (e.g., 18 sectors = 20° each).

**Rejected because:**
- More complex implementation
- Quantization feels artificial
- No accuracy benefit over continuous tracking

### Alternative 2: Calibrated Arc-Length Tracking
Add calibration phase to improve small-angle accuracy.

**Rejected because:**
- Adds complexity and user friction
- Current accuracy (±2-5%) sufficient for most use cases
- Can be added later if needed

### Alternative 3: Do Nothing
Keep full-rotation-only behavior.

**Rejected because:**
- Poor user experience for slow movements
- Wastes available data from phase tracking
- Trivial implementation cost for significant UX improvement

## Open Questions

- [x] Should distance update frequency be user-configurable in settings?
  - **Decision**: Start with fixed 20° default, add to settings if users request it
  
- [x] Should threshold mode support fractional tracking?
  - **Decision**: No - requires signal processing changes. PCA mode encourages migration.

- [x] What should happen when switching algorithms mid-session?
  - **Decision**: Reset distance on algorithm change (existing behavior)

## Success Metrics

After implementation, verify:
- [ ] Fractional rotation accuracy within ±2% of integer counts over 10 rotations
- [ ] Distance updates at configured intervals (20° default)
- [ ] No performance regression (CPU < 1% additional)
- [ ] All existing validity gate tests still pass
- [ ] UI responsiveness improved for slow rotations
- [ ] No false distance accumulation during figure-8 motion

## References

- Previous work: `changes/archive/2025-12-25-improve-rotation-detection/` (PCA implementation)
- Current spec: `specs/magnetometer-measurement/spec.md`
- Related: Phase unwrapping in `pca/phase_tracking.dart`
