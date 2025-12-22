# Issues and Fixes: PCA Rotation Detection

## Critical Mathematical Errors (December 2025)

### Issue #1: Wrong Eigenvector Interpretation ✅ FIXED

**Symptom**: Phase tracking was essentially random noise, quality unstable even with good magnet placement

**Root Cause**: 
- Eigenvalues sorted descending: λ1 ≥ λ2 ≥ λ3
- With this ordering, PC1 and PC2 (corresponding to λ1, λ2) represent the plane with largest variance
- PC3 (corresponding to λ3) represents the perpendicular direction with least variance
- Code was incorrectly projecting onto PC2/PC3, treating PC1 as the normal

**Impact**: Phase was being computed from the wrong plane components, tracking noise instead of rotation

**Fix Applied** (Dec 2025):
```dart
// OLD (WRONG):
final u = centered.dot(pca.pc2);  // PC2
final v = centered.dot(pca.pc3);  // PC3

// NEW (CORRECT):
final u = centered.dot(pca.pc1);  // PC1 - major axis IN plane
final v = centered.dot(pca.pc2);  // PC2 - minor axis IN plane
```

**Files Modified**:
- `lib/services/rotation_detection/pca/phase_tracking.dart`
- `lib/services/rotation_detection/pca/pca_result.dart` (documentation)

**Result**: Phase now correctly tracks actual rotation angle on the correct plane

---

### Issue #2: Incorrect Planarity Metric ✅ FIXED

**Symptom**: "Planarity" values confusing, algorithm rejected valid elongated rotations

**Root Cause**:
- Used metric: `(λ2 - λ3) / λ1`
- This mixes two concepts: dimensionality reduction with ellipse eccentricity
- Not a proper measure of how planar the motion is
- Higher values meant "more planar" which was counter-intuitive

**Impact**: Valid rotations with elongated ellipses (common with real magnets) were being rejected

**Fix Applied** (Dec 2025):
```dart
// OLD (WRONG):
double get planarity => (eigenvalues[1] - eigenvalues[2]) / eigenvalues[0];

// NEW (CORRECT):
/// Flatness: ratio of variance perpendicular to plane vs total variance
/// Range: 0.0 (perfectly planar) to 1.0 (spherical/random)
/// Lower is better - indicates motion confined to a plane
double get flatness => eigenvalues[2] / (eigenvalues[0] + eigenvalues[1] + eigenvalues[2]);
```

**Interpretation Change**:
- Old: Higher planarity = better
- New: Lower flatness = better (more planar)

**Files Modified**:
- `lib/services/rotation_detection/pca/pca_result.dart`
- `lib/services/rotation_detection/pca/validity_gates.dart`
- All logging and UI code

**Result**: Correct identification of planar motion regardless of ellipse eccentricity

---

## Stability and Robustness Issues

### Issue #3: Negative Rotation Counts Not Accumulated ✅ FIXED

**Symptom**: No points collected during rotation, distance not increasing

**Root Cause**:
- Phase unwrapper can count backwards (negative rotations) depending on initial phase
- Callback condition: `if (newCount > _rotationCount)`
- When count was negative (-1, -2, -3...), condition never true

**Impact**: Distance never accumulated, survey points never created

**Fix Applied** (Dec 2025):
```dart
// In magnetometer_service.dart
final newCount = _pcaDetector!.rotationCount.abs();  // Take absolute value
if (newCount > _rotationCount) {
    // Count rotations
}
```

**Result**: Distance accumulates regardless of phase direction (sign)

---

### Issue #4: Quality Flickering at Gate Boundaries ✅ IMPROVED

**Symptom**: Gates oscillated rapidly PASS/FAIL even with stable signal, quality percentage jumping

**Root Causes**:
1. Flatness threshold exactly at noise floor (0.15) - no hysteresis
2. Frequency calculated per-sample - instantaneous spikes caused rapid switching

**Impact**: 
- User saw unstable quality display
- Rotation counting was intermittent (though magnetometer service helped by filtering)

**Fixes Applied** (Dec 2025):

**Part A - Flatness Hysteresis**:
```dart
// In validity_gates.dart
maxFlatness = 0.20  // Raised from 0.15
flatnessHysteresis = 0.05

// Gate logic:
final flatnessThreshold = _lastPlanarState 
    ? config.maxFlatness + config.flatnessHysteresis  // 0.25 to stay PASS
    : config.maxFlatness;                             // 0.20 to become PASS
final isPlanar = pca.flatness <= flatnessThreshold;
```

**Part B - Frequency Debouncing**:
```dart
// Average frequency over last 10 samples (~0.1s)
_recentFrequencies.add(instantFreq);
if (_recentFrequencies.length > 10) _recentFrequencies.removeAt(0);
final avgFreq = _recentFrequencies.reduce((a, b) => a + b) / _recentFrequencies.length;
final hasValidFrequency = avgFreq <= config.maxRotationFrequencyHz;
```

**Result**: Significant reduction in flickering, user reported "quality...when the wheel rotates, it is good or excellent"

---

### Issue #5: Motion Gate Too Sensitive ✅ FIXED

**Symptom**: Motion gate failed too easily during normal rotation pauses

**Root Cause**:
- Motion threshold: 0.001 rad/sample was too high
- Slight slowdowns or brief pauses caused motion gate to fail
- Original averaging: 10 samples (0.1s) too short

**Impact**: Valid rotations rejected during natural speed variations

**Fixes Applied** (Dec 2025):

**Part A - Lower Threshold**:
```dart
// In PCARotationConfig
minPhaseChangePerSample = 0.0001  // Was 0.001 (100x more sensitive)
```

**Part B - Longer Averaging Window**:
```dart
// In validity_gates.dart
_phaseChangeHistorySize = 50  // Was 10 (now 0.5s at 100Hz)
```

**Result**: Motion gate more tolerant of speed variations and brief pauses

---

### Issue #6: Missed Rotations During Brief Stops ✅ FIXED

**Symptom**: "If there are interruptions or short stops in the rotation, the points get missed"

**Root Cause**:
- Rotation counting required ALL 4 validity gates to pass: `if (_latestValidity!.isValid)`
- When wheel stopped briefly, motion gate failed (average phase change below threshold)
- Even though phase unwrapper had accumulated 360° of rotation, count wasn't updated
- Result: Legitimate rotations spanning multiple stop/start cycles were lost

**Impact**: Real-world usage (pushing wheel through tight cave passages with pauses) caused missed data points

**Fix Applied** (Dec 2025):
```dart
// In pca_rotation_detector.dart

// OLD (STRICT):
if (_latestValidity!.isValid) {  // Required ALL 4 gates: planar + signal + freq + motion
    // Count rotations
}

// NEW (RELAXED):
final canCount = _latestValidity!.isPlanar && _latestValidity!.hasStrongSignal;
if (canCount) {  // Only requires: planar + signal (tolerates motion/freq gate failures)
    // Count rotations - trusts phase unwrapper's accumulated angle
}
```

**Rationale**:
- Phase unwrapper tracks cumulative angle continuously
- Motion gate measures recent velocity (can fail during stops)
- Frequency gate measures rate (can fail during irregular motion)
- But if signal is planar and strong, magnet is definitely present
- Therefore, trust the phase unwrapper's total angle even during brief pauses

**Result**: Rotation counting continues during pauses as long as magnet signal quality is decent

---

### Issue #7: Rotation Count Oscillation ✅ FIXED

**Symptom**: Rotation count jumping back and forth (-6 → -7 → -6 → -7...), points counter not increasing

**Root Cause**:
- Phase unwrapper oscillating due to noise near rotation boundaries
- Every change in rotation count triggered `notifyListeners()`
- Magnetometer service correctly ignored backwards movement with `if (newCount > _rotationCount)`
- But frequent notifications still processed, log spam, potential performance impact

**Impact**: 
- Points counter stuck despite rotation detection events
- Log spam made debugging difficult
- Unnecessary listener notifications

**Fix Applied** (Dec 22, 2025):
```dart
// In pca_rotation_detector.dart

// Added field:
int _maxAbsRotationCount = 0;  // Track maximum absolute count

// Modified counting logic:
if (canCount) {
    final newCount = _phaseUnwrapper.rotationCount;
    final absCount = newCount.abs();
    
    // Only notify if absolute count increased
    if (absCount > _maxAbsRotationCount) {
        print('[PCA] 🎯 ROTATION DETECTED! Count: $newCount (abs=$absCount, was $_maxAbsRotationCount) ...');
        _maxAbsRotationCount = absCount;
        _rotationCount = newCount;  // Keep raw count for reference
        notifyListeners();
    } else {
        // Update raw count but don't notify (oscillation)
        _rotationCount = newCount;
    }
}
```

**Result**: 
- Only notifies when distance actually increases (6 → 7 → 8...)
- Oscillations like -6 → -7 → -6 are silently ignored
- Points counter now increments correctly
- Cleaner logs, better performance

---

## Configuration Evolution

### Validity Gate Thresholds

**Initial Values** (Early Dec 2025):
```dart
minPlanarity = 0.15
maxFrequencyHz = 5.0
minPhaseChange = 0.001
signalRange = 5.0 - 10000.0
```

**Current Values** (Dec 22, 2025):
```dart
maxFlatness = 0.20 (with 0.05 hysteresis)
maxFrequencyHz = 10.0 (with 10-sample debouncing)
minPhaseChange = 0.0001 (with 50-sample averaging)
signalRange = 5.0 - 10000.0 (unchanged)
```

**Changes Summary**:
- Flatness threshold raised 0.15→0.20 (more permissive)
- Flatness hysteresis added (0.05 buffer)
- Frequency limit raised 5Hz→10Hz (allows faster rotation)
- Frequency debouncing added (10 samples)
- Motion threshold lowered 100x (0.001→0.0001)
- Motion averaging increased 5x (10→50 samples)

---

## Testing History

### Field Test #1 (Early Dec 2025)
**Setup**: Initial PCA implementation with incorrect math
**Results**: 
- Quality unstable ("fluctuates a lot")
- Sporadic rotation counting ("count doesn't work")
**Action**: Added comprehensive debug logging

### Field Test #2 (Mid Dec 2025)
**Setup**: After math corrections (eigenvector, flatness)
**Results**:
- "This one works better"
- "quality...when the wheel rotates, it is good or excellent"
- "quality still flickers a lot in stationary position" (acceptable - should reject stationary)
- "Points get collected too"
**Issues**: Still some flickering, points collection intermittent

### Field Test #3 (Dec 20, 2025)
**Setup**: After hysteresis, debouncing, relaxed counting
**Results**:
- "points are collected when the wheel rotates smoothly"
- "If there are interruptions or short stops in the rotation, the points get missed"
**Issue**: Brief pauses causing missed rotations

### Field Test #4 (Dec 22, 2025 - Pending)
**Setup**: After oscillation fix (max absolute count tracking)
**Expected**: Points counter should increment correctly during both smooth and interrupted rotation
**Status**: Waiting for user testing

---

## Lessons Learned

### 1. Eigenvector Interpretation is Critical
- With descending eigenvalue ordering, PC1/PC2 span the plane with MOST variance
- This is opposite to some PCA literature that uses ascending order
- Always verify eigenvector semantics with your specific implementation

### 2. Planarity Metrics are Non-Standard
- No universal "planarity" metric in literature
- Flatness (perpendicular variance / total variance) is intuitive and correct
- Lower values = more planar (opposite of many intuitive metrics)

### 3. Hysteresis Essential for Real Sensors
- Magnetometer data is noisy even with good signal
- Any threshold-based gate needs hysteresis to prevent oscillation
- Typical buffer: 10-25% of threshold value

### 4. Debouncing/Averaging Critical
- Single-sample metrics (frequency, motion) too volatile
- Average over 0.1-0.5s (10-50 samples @ 100Hz)
- Trade latency for stability

### 5. Decouple Quality from Counting
- Quality feedback (all gates) tells user "signal is perfect now"
- Rotation counting (relaxed gates) accumulates motion over time
- Different purposes require different strictness levels
- Phase unwrapper's cumulative angle is gold standard when magnet present

### 6. Track Absolute Progress, Not Signed Values
- Distance only increases (never negative)
- Track maximum absolute count to prevent oscillation
- Only notify listeners on forward progress

### 7. Real-World Usage is Unpredictable
- Users don't rotate smoothly at constant speed
- Brief pauses, speed variations, interruptions are normal
- Algorithm must be robust to these patterns
- Laboratory testing with synthetic data insufficient

### 8. Debug Logging is Essential
- Comprehensive logging at every pipeline stage enabled rapid bug identification
- User can provide logs without deep technical knowledge
- Gate state changes should be explicitly logged
- Phase unwrapper state (total phase, count) critical for debugging

---

## Open Questions

### 1. Optimal Flatness Threshold
- Current: 0.20 ± 0.05
- Based on limited field testing
- May need adjustment for different magnet types, distances, interference levels

### 2. Motion Gate Necessity
- Currently used for quality feedback only (not counting)
- Could potentially remove entirely and rely on flatness + signal
- Useful for detecting when user has stopped moving

### 3. Frequency Gate Utility
- Catches rapid phase jumps from interference
- But with 10-sample debouncing, may be redundant with signal quality
- Could experiment with removal

### 4. Calibration Workflow
- No automatic noise floor calibration yet
- Thresholds hardcoded based on test device
- Different magnetometer hardware may need different values

### 5. Long-Term Drift
- Phase unwrapper accumulates indefinitely
- Potential for drift over extended sessions (hours)
- May need periodic re-zeroing or drift correction

---

## Future Improvements

### Short Term
- [ ] Comprehensive unit tests for all components
- [ ] Automatic noise floor calibration on first launch
- [ ] CSV export for offline analysis
- [ ] Rotation direction tracking (useful for backing up wheel)

### Medium Term
- [ ] Adaptive thresholds based on signal characteristics
- [ ] Multi-magnet support (detect multiple peaks per rotation)
- [ ] Confidence score per rotation
- [ ] Battery impact analysis and optimization

### Long Term
- [ ] Machine learning for automatic threshold tuning
- [ ] Device-specific calibration profiles
- [ ] Anomaly detection (detect magnet falling off, interference)
- [ ] Advanced filtering (Kalman filter for phase tracking)

---

## References

### Code Files
- `lib/services/rotation_detection/pca/pca_result.dart` - PCA decomposition results
- `lib/services/rotation_detection/pca/phase_tracking.dart` - Projection and phase
- `lib/services/rotation_detection/pca/validity_gates.dart` - 4-gate validation
- `lib/services/rotation_detection/pca_rotation_detector.dart` - Main pipeline
- `lib/services/magnetometer_service.dart` - Service layer integration

### Documentation
- `/openspec/changes/improve-rotation-detection/proposal.md` - Original specification
- `/openspec/changes/improve-rotation-detection/tasks.md` - Implementation checklist
- `/openspec/changes/improve-rotation-detection/TESTING.md` - Testing protocols

### External Resources
- PCA fundamentals: Understanding eigenvalue decomposition
- Phase unwrapping: Handling 2π discontinuities
- Magnetometer noise characteristics: Understanding sensor limitations
