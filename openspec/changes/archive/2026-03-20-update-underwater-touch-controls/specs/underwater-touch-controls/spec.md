## ADDED Requirements

### Requirement: Unified In-Dive Control Interaction
All in-dive action controls on Main, Save Data, and Map screens SHALL use a shared underwater interaction model so tap/hold behavior is consistent across screens.

#### Scenario: Main and Save Data controls share behavior
- **WHEN** a user performs the same press pattern on `Save` (Main) and `Save` (Save Data)
- **THEN** both controls apply the same touch filtering and activation rules

#### Scenario: Map overlay controls use the same model
- **WHEN** a user taps Map overlay controls (view mode or export actions)
- **THEN** those controls use the same underwater interaction model as Main and Save Data controls

### Requirement: Intent-Filtered Activation for Noisy Touch Environments
The system SHALL harden single-tap activation against ghost touches by requiring a stable press window, allowing limited movement drift, ignoring secondary pointers while active, and applying a cooldown after activation.

#### Scenario: Short phantom contact is ignored
- **WHEN** pointer contact duration is shorter than the stable-press threshold
- **THEN** the control action SHALL NOT trigger

#### Scenario: Small drift still activates intended action
- **WHEN** the pointer drifts within the configured movement tolerance before release
- **THEN** the control action SHALL trigger on release

#### Scenario: Excessive drift cancels action
- **WHEN** the pointer drifts beyond the configured movement tolerance
- **THEN** the in-progress control interaction SHALL cancel and no action SHALL trigger

#### Scenario: Secondary pointer noise is ignored
- **WHEN** a control is already tracking an active pointer
- **THEN** additional pointers SHALL NOT trigger actions until the active interaction completes

#### Scenario: Bounce touches are suppressed
- **WHEN** a second tap occurs within the post-activation cooldown window
- **THEN** the second tap SHALL be ignored

### Requirement: Global Underwater Control Shape
The system SHALL use a single global rounded-rectangle paddle shape for in-dive action controls.

#### Scenario: Paddle shape applies by default
- **WHEN** button controls are loaded with default settings
- **THEN** in-dive action controls SHALL render in rounded-rectangle paddle style

#### Scenario: Paddle shape applies consistently across screens
- **WHEN** the user navigates between Main, Save Data, and Map screens
- **THEN** all in-dive action controls SHALL use the same rounded-rectangle paddle shape

### Requirement: Critical and Repeat Action Safety Profiles
The system SHALL preserve dedicated safety profiles for critical and repeat actions: hold-to-confirm for reset and press-and-repeat for increment/decrement.

#### Scenario: Reset requires hold confirmation
- **WHEN** user presses reset for less than the required hold duration
- **THEN** reset SHALL NOT execute
- **AND** the user SHALL receive hold-duration feedback

#### Scenario: Increment/decrement repeats during intentional hold
- **WHEN** user holds increment or decrement past long-press threshold
- **THEN** value changes SHALL repeat at configured intervals until release or cancellation

### Requirement: Underwater-Safe Customization Constraints
Button customization for in-dive controls SHALL enforce minimum size, maximum size, minimum spacing, and no-overlap rules, and SHALL sanitize previously saved layouts that violate these constraints.

#### Scenario: Minimum size is enforced
- **WHEN** a user sets a control smaller than the allowed minimum
- **THEN** the saved value SHALL clamp to the configured minimum size

#### Scenario: Overlap is prevented during drag
- **WHEN** user drags a control into another control's occupied area
- **THEN** the layout engine SHALL reject overlap and keep controls separated by at least minimum spacing

#### Scenario: Legacy unsafe layout is sanitized on load
- **WHEN** saved button configuration contains undersized or overlapping controls
- **THEN** the system SHALL sanitize the layout before rendering
- **AND** persist the sanitized layout

### Requirement: Map Overlay Touch Isolation
Touching map overlay controls SHALL NOT propagate to map pan/zoom/rotate gesture handlers.

#### Scenario: Export button touch does not pan map
- **WHEN** user taps and releases an export overlay control
- **THEN** export action SHALL trigger
- **AND** map offset, scale, and rotation SHALL remain unchanged by that interaction

#### Scenario: View mode toggle touch does not rotate map
- **WHEN** user taps a view mode toggle control
- **THEN** view mode SHALL change
- **AND** no map pan/zoom/rotation gesture SHALL be applied from the same interaction
