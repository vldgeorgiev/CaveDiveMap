# magnetometer-measurement Specification

## Purpose
TBD - created by archiving change improve-rotation-detection. Update Purpose after archive.
## Requirements
### Requirement: Configurable Detection Thresholds (REQ-MAG-008)

Manual threshold configuration SHALL be available only in threshold mode (default). PCA phase tracking SHALL NOT require or expose threshold parameters to users.

**Priority**: SHOULD

**Rationale**: PCA algorithm is inherently self-calibrating through automatic baseline removal and validity gates, eliminating need for manual thresholds.

**Verification**: Verify PCA mode operates without threshold settings; verify threshold mode still supports manual thresholds.

#### Scenario: PCA mode hides threshold controls

**Given** the app is using PCA phase tracking  
**When** user opens settings screen  
**Then** threshold configuration controls SHALL NOT be visible  
**And** only wheel circumference input SHALL be required  
**And** signal quality indicator SHALL be displayed instead

#### Scenario: Threshold mode shows threshold controls

**Given** user selects "Classic/Threshold Detection Mode" in settings  
**When** threshold algorithm is active  
**Then** min/max threshold sliders SHALL be visible  
**And** SHALL function identically to previous app versions  
**And** user CAN configure thresholds as before

---

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

