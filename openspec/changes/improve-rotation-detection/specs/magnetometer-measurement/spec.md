# Spec Delta: Magnetometer Measurement - PCA Phase Tracking

This spec defines the requirements for PCA-based wheel rotation detection that measures angular phase of the 3D magnetic field vector.

## ADDED Requirements

### Requirement: PCA-Based Phase Tracking (REQ-MAG-001)

The rotation detection algorithm SHALL use Principal Component Analysis (PCA) to track the angular phase of the 3D magnetic field vector, where each 2π phase advance corresponds to one wheel rotation.

**Priority**: MUST

**Rationale**: Phase tracking is orientation-independent (works in any phone position), drift-resistant (baseline removal handles OS calibration), and deterministic (no manual thresholds or ML training required). This solves all limitations of magnitude-based peak detection.

**Verification**: Measure phase advance during known rotations; verify 2π per rotation within ±5% error.

#### Scenario: Phase tracking in portrait orientation

**Given** the phone is mounted in portrait orientation  
**And** the magnetometer service is using PCA phase tracking  
**And** the measurement wheel completes 1 full rotation  
**When** measuring the cumulative phase change  
**Then** the phase SHALL advance by 2π ± 0.1 radians  
**And** one rotation SHALL be counted  
**And** distance SHALL increase by wheel circumference

#### Scenario: Phase tracking in arbitrary orientation

**Given** the phone is mounted in any arbitrary orientation  
**And** the PCA algorithm identifies the rotation plane  
**And** the measurement wheel completes 5 rotations  
**When** measuring the cumulative phase change  
**Then** the phase SHALL advance by 10π ± 0.5 radians (5 × 2π)  
**And** 5 rotations SHALL be counted  
**And** detection accuracy SHALL be ≥95%

---

### Requirement: Per-Axis Baseline Removal (REQ-MAG-002)

The algorithm SHALL remove baseline magnetic field (Earth's field + drift) by subtracting a rolling mean or exponential moving average from each magnetometer axis independently.

**Priority**: MUST

**Rationale**: OS auto-calibration and Earth's magnetic field (~50 μT) create a slowly varying baseline that must be removed to isolate the rotating magnet's signal. Per-axis removal preserves the 3D geometry needed for PCA.

**Verification**: Inject synthetic baseline drift and verify removal within 1-2 seconds; test with stationary wheel showing zero rotation count.

#### Scenario: Earth field removal

**Given** the phone magnetometer reports Earth's magnetic field of ~50 μT  
**And** the baseline removal uses EMA with alpha=0.01  
**When** baseline removal is applied to incoming samples  
**Then** the baseline-subtracted signal SHALL have mean magnitude <5 μT within 2 seconds  
**And** the rotating magnet signal SHALL be preserved  
**And** rotation detection SHALL work correctly

#### Scenario: OS calibration drift compensation

**Given** the phone OS gradually adjusts magnetometer readings over 60 seconds  
**And** baseline magnitude changes from 50 μT to 35 μT  
**And** the wheel continues rotating at 1 Hz  
**When** baseline removal adapts to the changing baseline  
**Then** rotation detection accuracy SHALL remain ≥90%  
**And** no manual recalibration SHALL be required  
**And** distance measurements SHALL remain accurate

---

### Requirement: Validity Gating (REQ-MAG-003)

The algorithm SHALL implement automatic validity gates (planarity, signal strength, frequency, coherence) to ensure only legitimate rotation signals are counted and false positives are rejected.

**Priority**: MUST

**Rationale**: Phone movements, random noise, and non-rotational magnetic disturbances can create phase changes that don't correspond to wheel rotations. Validity gates ensure the signal has the geometric and temporal characteristics of a true rotation before counting.

**Verification**: Test with figure-8 movements, phone rotation, and random noise; verify <2% false positive rate.

#### Scenario: Planarity gate rejects 3D motion

**Given** the magnetometer service is recording with PCA validity gates  
**And** the user moves the phone in figure-8 patterns (3D motion)  
**When** the PCA algorithm computes λ3 / (λ1 + λ2 + λ3) > 0.1 (non-planar)  
**Then** the validity gate SHALL reject the signal  
**And** no rotations SHALL be counted  
**And** signal quality SHALL indicate "Invalid signal"

#### Scenario: Signal strength gate rejects noise

**Given** the magnetometer service is recording  
**And** the measurement wheel is stationary  
**And** only random sensor noise is present (~5 μT)  
**When** the signal strength is below minimum threshold (10 μT)  
**Then** the validity gate SHALL reject the signal  
**And** no rotations SHALL be counted

#### Scenario: Frequency gate rejects impossible speeds

**Given** a detected phase change corresponds to 10 Hz rotation speed  
**And** the maximum physical rotation speed is 7 Hz  
**When** the frequency validity gate evaluates the signal  
**Then** the gate SHALL reject the signal as unphysical  
**And** no rotation SHALL be counted

#### Scenario: Coherence gate rejects inconsistent motion

**Given** the phase derivative changes direction erratically  
**And** coherence score is <0.8 (unstable rotation direction)  
**When** the coherence validity gate evaluates the signal  
**Then** the gate SHALL reject the signal  
**And** no rotation SHALL be counted until coherence improves

---

### Requirement: Sliding Window PCA (REQ-MAG-004)

The algorithm SHALL maintain a sliding window buffer (≈1 second) of baseline-subtracted samples and compute PCA on this window to identify the dominant 2D rotation plane.

**Priority**: MUST

**Rationale**: PCA finds the plane where the magnetic field vector exhibits maximum variance (the rotation plane), automatically handling any phone orientation. A 1-second window provides stable eigenvector estimates while maintaining responsiveness.

**Verification**: Test with synthetic circular rotation data; verify PCA identifies correct rotation plane (planarity <0.1).

#### Scenario: PCA identifies rotation plane

**Given** a sliding window contains 100 samples (1 second at 100 Hz)  
**And** samples represent circular rotation of magnet field vector  
**When** PCA eigenvalue decomposition is performed  
**Then** the first two eigenvalues SHALL capture ≥95% of variance  
**And** the third eigenvalue SHALL be <10% of total variance (planarity <0.1)  
**And** the rotation plane is defined by the first two eigenvectors

#### Scenario: Window size affects stability

**Given** rotation speed is 1 Hz  
**And** window size is varied from 0.5s to 2.0s  
**When** measuring phase estimation stability  
**Then** 1.0s window SHALL provide stable detection  
**And** shorter windows MAY increase noise sensitivity  
**And** longer windows MAY increase latency

---

### Requirement: Real-Time Performance (REQ-MAG-005)

The PCA phase tracking algorithm SHALL process magnetometer samples with <200ms average latency from physical rotation to detection callback.

**Priority**: MUST

**Rationale**: Users need timely feedback for survey point creation. PCA computation is performed every N samples (not every sample) to balance accuracy and performance.

**Verification**: Measure time from simulated rotation peak to detection event; verify 95th percentile <200ms.

#### Scenario: Detection latency under normal operation

**Given** magnetometer sampling rate is 100 Hz  
**And** PCA is computed every 10 samples (100ms intervals)  
**And** a wheel rotation causes phase advance of 2π  
**When** the rotation is complete  
**Then** detection SHALL occur within 200ms  
**And** 95% of detections SHALL complete within 150ms

#### Scenario: Computational cost remains low

**Given** the app is running on target hardware  
**And** magnetometer samples are being processed continuously  
**When** measuring CPU usage during rotation detection  
**Then** PCA phase tracking SHALL use <10% CPU on average  
**And** SHALL NOT cause UI frame drops  
**And** battery drain SHALL NOT increase by more than 5%

---

### Requirement: Signal Quality Indicator (REQ-MAG-006)

The system SHALL provide a real-time signal quality metric (0-100%) based on planarity, signal strength, and coherence, displayed to the user.

**Priority**: SHOULD

**Rationale**: Users need feedback on whether the system is detecting valid rotations. Signal quality indicator helps troubleshoot positioning issues and confirms proper operation.

**Verification**: Verify signal quality correlates with detection accuracy; test with poor positioning showing low quality.

#### Scenario: High quality signal indication

**Given** the measurement wheel is properly positioned near sensor  
**And** planarity <0.05, signal strength >30 μT, coherence >0.9  
**When** computing signal quality  
**Then** signal quality SHALL be ≥80%  
**And** UI SHALL display green indicator  
**And** rotation detection SHALL be highly accurate

#### Scenario: Low quality signal warning

**Given** the measurement wheel is far from sensor or misaligned  
**And** planarity >0.15 or signal strength <15 μT  
**When** computing signal quality  
**Then** signal quality SHALL be <50%  
**And** UI SHALL display red/orange warning  
**And** user SHALL be prompted to adjust positioning

---

### Requirement: Zero-Configuration Operation (REQ-MAG-007)

The PCA phase tracking algorithm SHALL operate without manual threshold configuration, requiring only wheel circumference as user input.

**Priority**: MUST

**Rationale**: Manual threshold configuration creates poor UX and high barrier to entry. PCA is inherently self-calibrating through automatic baseline removal and validity gates.

**Verification**: New user installs app, sets wheel circumference, and achieves ≥90% accuracy without configuring any detection parameters.

#### Scenario: First-time user experience

**Given** a new user installs the app  
**And** connects the measurement wheel device  
**And** enters wheel circumference only  
**When** starting the first survey session  
**Then** rotation detection SHALL work immediately  
**And** NO threshold configuration SHALL be required  
**And** accuracy SHALL be ≥90% in default orientation

#### Scenario: Automatic noise floor calibration

**Given** the app is launched for the first time  
**When** magnetometer service initializes  
**Then** it SHALL automatically calibrate noise floor  
**And** SHALL record 5 seconds of baseline samples  
**And** SHALL compute minimum signal strength threshold  
**And** NO user interaction SHALL be required

---

### Requirement: Uncalibrated Magnetometer Support (REQ-MAG-010)

The system SHALL use uncalibrated magnetometer readings (e.g., Android `TYPE_MAGNETIC_FIELD_UNCALIBRATED`) for rotation detection, and SHALL surface an error state when uncalibrated data is unavailable on the device.

**Priority**: MUST

**Rationale**: Calibrated feeds are auto-normalized by the OS and hide the magnet’s field during static periods. Uncalibrated data preserves the true field and enables reliable PCA phase tracking.

**Verification**: On Android, verify the app consumes uncalibrated x/y/z; simulate unavailability and confirm an error/warning is shown and counting does not proceed silently with calibrated data.

#### Scenario: Use uncalibrated data when available

**Given** the device exposes `TYPE_MAGNETIC_FIELD_UNCALIBRATED`  
**When** the magnetometer service starts  
**Then** PCA and legacy detectors SHALL consume uncalibrated x/y/z values only  
**And** calibrated values SHALL NOT be used for detection

#### Scenario: Uncalibrated data not supported

**Given** the device does not expose uncalibrated magnetometer data  
**When** the app starts  
**Then** the app SHALL display an error/warning about missing uncalibrated support  
**And** detection SHALL NOT silently fall back to calibrated data without informing the user

---

## MODIFIED Requirements

### Requirement: Configurable Detection Thresholds (REQ-MAG-008)

Manual threshold configuration SHALL be available only in legacy mode for backward compatibility. PCA phase tracking SHALL NOT require or expose threshold parameters to users.

**Priority**: SHOULD

**Change Summary**: Changed from MUST configure (previous: manual threshold configuration required) to legacy-only (new: PCA is zero-configuration)

**Rationale**: PCA algorithm is inherently self-calibrating through automatic baseline removal and validity gates, eliminating need for manual thresholds.

**Verification**: Verify PCA mode operates without threshold settings; verify legacy mode still supports manual thresholds.

#### Scenario: PCA mode hides threshold controls

**Given** the app is using PCA phase tracking (default mode)  
**When** user opens settings screen  
**Then** threshold configuration controls SHALL NOT be visible  
**And** only wheel circumference input SHALL be required  
**And** signal quality indicator SHALL be displayed instead

#### Scenario: Legacy mode shows threshold controls

**Given** user selects "Classic Detection Mode" in settings  
**When** legacy threshold algorithm is active  
**Then** min/max threshold sliders SHALL be visible  
**And** SHALL function identically to previous app versions  
**And** user CAN configure thresholds as before

---

### Requirement: Detection Algorithm Selection (REQ-MAG-009)

The app SHALL use PCA phase tracking by default with optional legacy threshold mode for backward compatibility and debugging.

**Priority**: MUST

**Change Summary**: Changed from single algorithm (previous: magnitude-based threshold only) to PCA-primary with legacy fallback

**Rationale**: PCA solves orientation dependency, drift sensitivity, and false positive issues. Legacy mode preserved for users who prefer it or encounter PCA issues on specific devices.

**Verification**: Verify PCA is default; verify toggle between PCA and legacy modes; verify both modes function correctly.

#### Scenario: Default algorithm is PCA

**Given** the app is launched for the first time OR after update  
**When** magnetometer service initializes  
**Then** PCA phase tracking SHALL be the active algorithm  
**And** settings SHALL show "PCA Detection (Recommended): ON"  
**And** legacy mode toggle SHALL be available

#### Scenario: Manual algorithm toggle

**Given** a user wants to use legacy threshold mode  
**When** they toggle "Use Classic Detection" in settings  
**Then** the app SHALL switch to threshold-based algorithm  
**And** PCA processing SHALL be paused  
**And** threshold configuration controls SHALL become visible  
**And** selection SHALL persist across app restarts

## REMOVED Requirements

None - all existing functionality is preserved in legacy mode.

---

## Test Coverage Requirements

All scenarios defined above SHALL have corresponding automated tests where possible, or documented manual test procedures for hardware-dependent scenarios.

**Unit Tests** (target coverage >90%):
- Circular buffer edge cases
- PCA/validity gating combinations
- Algorithm selection logic and uncalibrated availability handling

**Integration Tests**:
- End-to-end detection pipeline (uncalibrated feed)
- Algorithm switching and fallback
- Legacy mode compatibility
- Data persistence with new fields

**Real-World Tests** (manual):
- Multi-orientation testing (6 orientations × 10 rotations)
- Long-session stability (5 minutes continuous)
- False positive resistance (figure-8, walking)
- Multi-device compatibility (iPhone 15/16, Samsung S21/S23)
- Battery impact measurement

---

## Performance Requirements

- **CPU Usage**: Detection processing SHALL NOT exceed 10% average CPU on target devices
- **Memory**: Algorithm runtime memory SHALL NOT exceed 10 MB additional
- **Battery**: Extended detection (60 minutes) SHALL NOT increase battery drain by >5%
- **Latency**: 95th percentile detection latency <100ms

---

## Backward Compatibility

- **Data Format**: Existing survey data SHALL load without modification
- **Legacy Mode**: Previous threshold-based detection SHALL remain available
- **Export Formats**: CSV and Therion exports SHALL remain compatible
- **Settings Migration**: Existing threshold settings SHALL be preserved and used in legacy mode

---

## Security & Privacy

- **Model Integrity**: ML model files SHALL be verified at load time (checksum)
- **Data Collection**: User data collection for model training SHALL be opt-in only
- **Local Processing**: All detection SHALL occur on-device; no cloud communication required
- **Telemetry**: Anonymous algorithm performance metrics MAY be collected with user consent
