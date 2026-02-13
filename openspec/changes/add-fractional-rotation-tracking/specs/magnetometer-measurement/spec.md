# Spec Delta: Magnetometer Measurement - Fractional Rotation Tracking

This document describes changes to the `magnetometer-measurement` specification to support fractional rotation tracking and continuous distance measurement.

---

## ADDED Requirements

### Requirement: Fractional Rotation Tracking (REQ-MAG-011)

The PCA rotation detection algorithm SHALL expose fractional rotation values representing partial wheel rotations, enabling continuous distance measurement at any point during rotation rather than only at 2π boundaries.

**Priority**: MUST

**Rationale**: Phase tracking already computes continuous phase angles but only exposes integer rotation counts. Exposing fractional values enables fine-grained distance updates (every 10-20°) for improved user experience during slow or partial rotations, with zero additional complexity or calibration requirements.

**Verification**: Verify fractional rotation getter returns accurate values for partial rotations (0.25, 0.5, 0.75); verify accuracy within ±2% compared to integer counts over multiple rotations.

#### Scenario: Quarter rotation tracking

**Given** the wheel has rotated 90 degrees (π/2 radians)  
**When** reading the fractional rotation value  
**Then** the value SHALL be 0.25 ± 0.01  
**And** integer rotation count SHALL remain 0

#### Scenario: Half rotation tracking

**Given** the wheel has rotated 180 degrees (π radians)  
**When** reading the fractional rotation value  
**Then** the value SHALL be 0.5 ± 0.01  
**And** integer rotation count SHALL remain 0

#### Scenario: Three-quarter rotation tracking

**Given** the wheel has rotated 270 degrees (3π/2 radians)  
**When** reading the fractional rotation value  
**Then** the value SHALL be 0.75 ± 0.01  
**And** integer rotation count SHALL remain 0

#### Scenario: Mixed integer and fractional rotations

**Given** the wheel has completed 2.25 rotations (4.5π radians)  
**When** reading the fractional rotation value  
**Then** the value SHALL be 2.25 ± 0.02  
**And** integer rotation count SHALL be 2

---

### Requirement: Continuous Distance Measurement (REQ-MAG-012)

The magnetometer service SHALL provide continuous distance values computed from fractional rotations multiplied by wheel circumference, updating smoothly during partial rotations rather than in discrete full-rotation steps.

**Priority**: MUST

**Rationale**: Users expect distance to update continuously as they move, not in 26cm jumps. Continuous distance improves UX for slow movements, provides immediate feedback, and better matches user mental models of distance measurement.

**Verification**: Verify distance updates during partial rotations; verify distance = fractionalRotations × wheelCircumference; verify smooth progression during slow rotation (< 1 RPM).

#### Scenario: Distance during partial rotation

**Given** wheel circumference is 0.263 meters  
**And** the wheel has rotated 0.5 rotations (180°)  
**When** reading the continuous distance  
**Then** distance SHALL be 0.1315 ± 0.005 meters

#### Scenario: Distance updates smoothly during slow rotation

**Given** wheel circumference is 0.263 meters  
**And** the wheel is rotating slowly (0.5 RPM)  
**When** observing distance over 1 second intervals  
**Then** distance SHALL increase continuously  
**And** each update SHALL reflect partial rotation progress

#### Scenario: Distance accuracy matches integer rotations

**Given** wheel circumference is 0.263 meters  
**And** the wheel completes exactly 10 rotations  
**When** comparing continuous distance to integer-based distance  
**Then** the difference SHALL be < 2% (< 5.3 cm over 2.63 m)

---

### Requirement: Configurable Distance Update Frequency (REQ-MAG-013)

The PCA detector SHALL support configurable distance update intervals specified as minimum phase advance (radians) between notifications, with a default of π/9 radians (20 degrees) to balance responsiveness and performance.

**Priority**: MUST

**Rationale**: Updating distance at every sample (100 Hz) would cause excessive UI redraws and wasted CPU. Configurable intervals allow tuning the trade-off between responsiveness and performance. 20° default provides smooth visual feedback (~18 updates per rotation) while keeping notification rate manageable (5-10 Hz at typical rotation speeds).

**Verification**: Verify distance updates trigger at configured phase intervals; verify update frequency scales with rotation speed; verify no updates when phase advance < threshold.

#### Scenario: Default 20-degree update intervals

**Given** minPhaseForDistanceUpdate is π/9 (20 degrees)  
**And** the wheel is rotating at 1 RPS  
**When** monitoring distance update callbacks  
**Then** updates SHALL occur approximately 18 times per rotation  
**And** update rate SHALL be approximately 18 Hz

#### Scenario: Configurable update interval

**Given** minPhaseForDistanceUpdate is set to π/18 (10 degrees)  
**And** the wheel rotates 45 degrees (π/4 radians)  
**When** monitoring distance update callbacks  
**Then** callbacks SHALL fire approximately 4-5 times  
**And** each callback SHALL represent ~10° of rotation

#### Scenario: No updates when phase advance insufficient

**Given** minPhaseForDistanceUpdate is π/9 (20 degrees)  
**And** the wheel rotates only 10 degrees (π/18 radians)  
**When** monitoring distance update callbacks  
**Then** NO distance update callback SHALL fire  
**Until** cumulative phase advance reaches 20 degrees

---

### Requirement: Validity Gate Integration (REQ-MAG-014)

Fractional distance updates SHALL respect all existing validity gates (planarity, signal strength, coherence, inertial, frequency) and only emit updates when the signal is valid, ensuring the same false-positive rejection as integer rotation counts.

**Priority**: MUST

**Rationale**: Fractional tracking must not introduce new false positives. Using the same `canEmit` condition ensures figure-8 phone motion, handset rotation, and weak signals are rejected identically to the current implementation. Distance updates during invalid signal periods would accumulate phantom distance.

**Verification**: Verify distance does not accumulate during figure-8 motion; verify distance does not accumulate during phone rotation; verify distance only updates when all validity gates pass; verify grace periods work identically.

#### Scenario: No distance accumulation during figure-8 motion

**Given** the user moves the phone in figure-8 pattern  
**And** coherence gate fails (coherence < 0.4)  
**When** monitoring fractional distance over 10 seconds  
**Then** distance SHALL not increase  
**And** fractional rotations SHALL not advance

#### Scenario: No distance accumulation during phone rotation

**Given** the user rotates the phone in hand  
**And** gyroscope magnitude > 6 rad/s (inertial gate fails)  
**When** monitoring fractional distance over 5 seconds  
**Then** distance SHALL not increase  
**And** fractional rotations SHALL not advance

#### Scenario: Distance updates respect planarity grace periods

**Given** the wheel is rotating with strong signal  
**And** planarity briefly fails for 800ms (< 1200ms grace)  
**When** signal strength and coherence remain valid  
**Then** fractional distance SHALL continue updating  
**Because** planarity grace period allows temporary dropout

#### Scenario: Distance updates only when all gates pass

**Given** the wheel is rotating  
**And** any validity gate fails (planarity, signal, coherence, inertial, frequency)  
**When** monitoring distance updates  
**Then** NO distance updates SHALL be emitted  
**Until** all gates pass again

---

### Requirement: Backward Compatibility (REQ-MAG-015)

The integer rotation count API SHALL remain unchanged and continue to function identically, ensuring existing code using `rotationCount` getter works without modification while new code can opt into fractional tracking.

**Priority**: MUST

**Rationale**: Breaking changes would require updating all dependent code and could introduce bugs. Adding new getters alongside existing ones allows gradual migration and supports use cases that prefer integer counts (e.g., historical data, discrete event counting).

**Verification**: Verify `rotationCount` getter returns integer values as before; verify behavior unchanged for code not using fractional getters; verify existing tests still pass.

#### Scenario: Integer rotation count unchanged

**Given** the wheel completes 2.7 rotations  
**When** reading the integer rotation count  
**Then** the value SHALL be 2  
**And** fractional rotation count SHALL be 2.7 ± 0.02

#### Scenario: Existing code works without changes

**Given** application code uses `rotationCount` getter  
**And** does not use `fractionalRotations` getter  
**When** wheel completes rotations  
**Then** behavior SHALL be identical to pre-fractional implementation  
**And** all existing tests SHALL pass

#### Scenario: Threshold mode unaffected

**Given** threshold detection algorithm is selected  
**When** wheel rotations are detected  
**Then** only integer rotation counts SHALL be available  
**And** fractional tracking SHALL not apply  
**Because** threshold mode lacks continuous phase measurement

---

## MODIFIED Requirements

None. This change is purely additive and does not modify existing requirements.

---

## REMOVED Requirements

None. All existing functionality is preserved.
