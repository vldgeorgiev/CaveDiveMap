# magnetometer-measurement Specification

## Purpose
TBD - created by archiving change improve-rotation-detection. Update Purpose after archive.
## Requirements
### Requirement: Configurable Detection Thresholds (REQ-MAG-008)

Manual threshold configuration SHALL be available in threshold mode, AND auto-calibration SHALL be provided as the recommended method for determining threshold values.

**Priority**: SHOULD *(previously SHOULD, now enhanced with auto-calibration)*

**Rationale**: Manual configuration is preserved for advanced users and troubleshooting, while auto-calibration serves as the primary user-friendly method.

**Verification**: Verify both manual entry and auto-calibration can set thresholds successfully.

#### Scenario: Manual threshold entry still works

**Given** user is in settings with threshold mode active  
**When** user manually enters min threshold = 100 μT  
**And** user manually enters max threshold = 180 μT  
**When** user saves settings  
**Then** thresholds SHALL be saved and applied  
**And** manual values SHALL override any previous calibration

#### Scenario: Auto-calibration is recommended

**Given** user opens settings for the first time  
**And** threshold mode is active  
**Then** "Calibrate Thresholds" button SHALL be prominent  
**And** tooltip or hint text SHALL recommend: "Use calibration for best results"  
**And** manual threshold entry SHALL remain available below calibration button

### Requirement: Detection Algorithm Selection (REQ-MAG-009)

The app SHALL default to threshold-based detection with optional PCA phase tracking (beta) for users who opt in; both algorithms SHALL be accessible via settings.

**Priority**: MUST

**Rationale**: Threshold mode is simple and configurable; PCA offers orientation independence but is still in beta. Users can switch based on preference and device behavior.

**Verification**: Verify threshold is default; verify toggle between threshold and PCA; verify both modes function correctly and selection persists.

#### Scenario: Default algorithm is threshold

**Given** the app is launched for the first time OR after update  
**When** magnetometer service initializes  
**Then** threshold detection SHALL be the active algorithm  
**And** settings SHALL show threshold as selected  
**And** PCA toggle SHALL be available

#### Scenario: Manual algorithm toggle

**Given** a user wants to use PCA phase tracking  
**When** they toggle PCA in settings  
**Then** the app SHALL switch to PCA-based algorithm  
**And** threshold processing SHALL be paused  
**And** selection SHALL persist across app restarts

### Requirement: Threshold Auto-Calibration (REQ-MAG-010)

The application SHALL provide a guided auto-calibration process for threshold algorithm that automatically determines optimal min/max magnetic field thresholds through a two-step user-guided measurement procedure. The algorithm SHALL apply asymmetric percentage-based margins (20% low-end, 50% high-end) to account for brief peak detection during quick rotations.

**Priority**: SHOULD

**Rationale**: Manual threshold configuration requires technical knowledge and trial-and-error. Auto-calibration eliminates guesswork, improves accuracy, and enhances user experience by adapting to specific device and magnet characteristics. Asymmetric margins ensure the high peak threshold is set conservatively to catch brief peaks during quick rotations, while the low threshold has a tighter margin for baseline detection.

**Verification**: Complete calibration flow and verify calculated thresholds result in >95% rotation detection accuracy.

#### Scenario: Calibration button visibility

**Given** the user is on the settings screen  
**When** threshold algorithm is selected  
**Then** "Calibrate Thresholds" button SHALL be visible  
**And** button SHALL navigate to calibration screen when pressed

#### Scenario: PCA mode hides calibration

**Given** the user is on the settings screen  
**When** PCA algorithm is selected  
**Then** "Calibrate Thresholds" button SHALL NOT be visible  
**And** threshold configuration controls SHALL be hidden  
**Because** PCA is self-calibrating and does not use thresholds

#### Scenario: Far position calibration (Step 1)

**Given** user starts calibration process  
**When** user is on step 1 (far position)  
**Then** screen SHALL display instructions: "Rotate wheel with magnet as FAR as possible from phone"  
**And** screen SHALL instruct: "Move phone in figure-8 motion"  
**And** screen SHALL display "Start Recording" button  
**When** user presses "Start Recording"  
**Then** app SHALL record magnetometer magnitude for 10 seconds  
**And** app SHALL display real-time magnitude value in large text  
**And** app SHALL display countdown timer (10, 9, 8...)  
**And** app SHALL track maximum magnitude value observed  
**When** recording completes  
**Then** app SHALL store maximum magnitude as `maxField`  
**And** "Next" button SHALL become enabled

#### Scenario: Close position calibration (Step 2)

**Given** user completed far position calibration  
**When** user presses "Next" to step 2  
**Then** screen SHALL display instructions: "Rotate wheel with magnet as CLOSE as possible to phone"  
**And** screen SHALL instruct: "Move phone in figure-8 motion"  
**And** screen SHALL display "Start Recording" button  
**When** user presses "Start Recording"  
**Then** app SHALL record magnetometer magnitude for 10 seconds  
**And** app SHALL display real-time magnitude value in large text  
**And** app SHALL display countdown timer (10, 9, 8...)  
**And** app SHALL track minimum magnitude value observed  
**When** recording completes  
**Then** app SHALL store minimum magnitude as `minField`  
**And** "Calculate" or "Next" button SHALL become enabled

#### Scenario: Threshold calculation with valid separation

**Given** far position recorded `maxField` = 200 μT  
**And** close position recorded `minField` = 120 μT  
**When** app calculates thresholds  
**Then** range = 200 - 120 = 80 μT  
**And** low margin = 80 × 0.20 = 16 μT  
**And** high margin = 80 × 0.50 = 40 μT  
**And** `calculatedMin = minField + lowMargin = 120 + 16 = 136 μT`  
**And** `calculatedMax = maxField - highMargin = 200 - 40 = 160 μT`  
**And** separation check SHALL pass (`160 - 136 = 24 μT > 20 μT`)  
**And** result screen SHALL display calculated thresholds  
**And** result screen SHALL display "Low Margin: 20%, High Margin: 50%"  
**And** "Apply" button SHALL be enabled

**Note**: Asymmetric margins (20% low, 50% high) account for brief peak detection during quick rotations.

#### Scenario: Threshold calculation with insufficient separation

**Given** far position recorded `maxField` = 150 μT  
**And** close position recorded `minField` = 140 μT  
**When** app calculates thresholds  
**Then** range = 150 - 140 = 10 μT  
**And** low margin = 10 × 0.20 = 2 μT  
**And** high margin = 10 × 0.50 = 5 μT  
**And** `calculatedMin = 140 + 2 = 142 μT`  
**And** `calculatedMax = 150 - 5 = 145 μT`  
**And** separation check SHALL fail (`145 - 142 = 3 μT < 20 μT`)  
**And** error message SHALL be displayed: "Insufficient separation between far and close positions"  
**And** "Retry" button SHALL be offered  
**And** "Apply" button SHALL remain disabled

#### Scenario: Apply calibration results

**Given** calibration completed successfully  
**And** calculated thresholds are `minThreshold = 136 μT`, `maxThreshold = 160 μT`  
**When** user presses "Apply"  
**Then** app SHALL call `settings.updateMinPeakThreshold(136.0)`  
**And** app SHALL call `settings.updateMaxPeakThreshold(160.0)`  
**And** settings SHALL be persisted via `StorageService`  
**And** app SHALL navigate back to settings screen  
**And** success message SHALL be displayed: "Thresholds calibrated successfully"

#### Scenario: Cancel calibration

**Given** user is in the middle of calibration (any step)  
**When** user presses "Cancel" or back button  
**Then** confirmation dialog SHALL be displayed: "Cancel calibration?"  
**When** user confirms cancellation  
**Then** calibration state SHALL reset to idle  
**And** app SHALL navigate back to settings screen  
**And** existing threshold settings SHALL remain unchanged

#### Scenario: Calibration accuracy validation

**Given** user completed auto-calibration  
**And** calculated thresholds are applied  
**When** user performs 100 wheel rotations  
**Then** magnetometer service SHALL detect ≥95 rotations (95-105 range)  
**And** false positive rate SHALL be ≤5%  
**And** missed rotation rate SHALL be ≤5%

---

### Requirement: Calibration State Persistence (REQ-MAG-011)

Calibrated threshold values SHALL persist across app restarts and SHALL continue to be used until user manually changes them or performs re-calibration.

**Priority**: MUST

**Rationale**: Users should not need to recalibrate every time they restart the app. Calibration values should persist indefinitely until changed.

**Verification**: Complete calibration, restart app, verify thresholds are still applied.

#### Scenario: Threshold persistence after restart

**Given** user completed calibration with thresholds 136/160 μT  
**And** app is closed completely  
**When** app is restarted  
**Then** settings SHALL load persisted thresholds (136/160 μT)  
**And** magnetometer service SHALL use persisted thresholds  
**And** calibration status indicator SHALL show "Calibrated" (if implemented)

#### Scenario: Re-calibration overwrites previous values

**Given** user has previously calibrated thresholds to 136/160 μT  
**When** user performs calibration again  
**And** new calibration results in 145/170 μT  
**When** user applies new calibration  
**Then** settings SHALL update to new thresholds 145/170 μT  
**And** old thresholds (136/160 μT) SHALL be replaced  
**And** new thresholds SHALL persist across restarts

---

### Requirement: Real-time Magnitude Display (REQ-MAG-012)

During calibration recording, the app SHALL display real-time magnetic field magnitude to provide immediate feedback to the user.

**Priority**: SHOULD

**Rationale**: Real-time feedback helps users understand if they are capturing sufficient range and if the magnet is being detected properly.

**Verification**: Observe magnitude display updates at least 5 times per second during recording.

#### Scenario: Magnitude display during recording

**Given** calibration step is recording  
**When** magnetometer reports new magnitude value  
**Then** displayed magnitude SHALL update within 200ms  
**And** magnitude SHALL be displayed in large, readable text  
**And** units (μT) SHALL be displayed alongside value

**Note**: Color-coded visual feedback was removed in favor of neutral display colors for consistency.

---

