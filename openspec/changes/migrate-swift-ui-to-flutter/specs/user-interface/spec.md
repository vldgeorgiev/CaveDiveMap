# User Interface Specification Delta

**Change ID**: migrate-swift-ui-to-flutter  
**Capability**: user-interface

This delta describes changes to the user interface design, layout, styling, and interaction patterns when migrating from the Swift iOS implementation to the Flutter cross-platform implementation.

---

## ADDED Requirements

### Requirement: Button Customization System
The system SHALL provide a button customization interface that allows users to adjust the size and position of all action buttons on both the main screen and save data screen for improved underwater usability with waterproof cases.

#### Scenario: User customizes save button position
- **GIVEN** user is in the button customization screen
- **WHEN** user selects "Main Screen" context and "Save Button"
- **AND** user adjusts the horizontal position slider to +50
- **AND** user adjusts the vertical position slider to -30
- **AND** user saves the customization
- **THEN** the save button on the main screen SHALL be positioned at offset (50, -30) from screen center
- **AND** the customization SHALL persist across app restarts

#### Scenario: User customizes button size
- **GIVEN** user is in the button customization screen
- **WHEN** user selects any button and adjusts the size slider to 90
- **AND** user saves the customization
- **THEN** the button diameter SHALL be 90 logical pixels
- **AND** the icon size SHALL scale proportionally to 35-40% of button size

#### Scenario: User resets all buttons to defaults
- **GIVEN** user has customized multiple buttons
- **WHEN** user taps "Reset All to Defaults" button
- **AND** user confirms the reset action
- **THEN** all 8 buttons (4 main screen, 4 save data view) SHALL return to their default configurations
- **AND** the defaults SHALL match the original Swift app defaults

### Requirement: Circular Action Buttons with Custom Positioning
The system SHALL render all primary action buttons as circular elements with semantic color coding, customizable sizes, and stack-based positioning that allows overlap and free placement on screen.

#### Scenario: Main screen displays positioned circular buttons
- **GIVEN** user is on the main screen
- **THEN** the system SHALL display 4 circular action buttons:
  - Save button: Green background, save icon, positioned at configured offset
  - Map button: Blue background, map icon, positioned at configured offset
  - Reset button: Red background, "Reset" text, positioned at configured offset
  - Camera button: Orange background, camera icon, positioned at configured offset
- **AND** buttons SHALL be rendered using Stack with Positioned widgets
- **AND** button icons SHALL scale to 35-40% of button diameter
- **AND** button text SHALL scale to 20-26% of button diameter

#### Scenario: Save data screen displays positioned circular buttons
- **GIVEN** user is on the save data screen
- **THEN** the system SHALL display 4 circular action buttons:
  - Decrement button: Orange background, minus icon, positioned at configured offset
  - Increment button: Orange background, plus icon, positioned at configured offset
  - Save button: Green background, "Save" text, positioned at configured offset
  - Cycle button: Blue background, cycle icon, positioned at configured offset
- **AND** all buttons SHALL use the customization system for positioning and sizing

### Requirement: Tap vs Long-Press Gesture Discrimination
The system SHALL distinguish between tap gestures (instant action) and long-press gestures (continuous action) on increment/decrement buttons with a 0.5-second threshold and proper timer cleanup.

#### Scenario: User taps increment button (short press)
- **GIVEN** user is on the save data screen editing a parameter
- **WHEN** user presses the increment button
- **AND** user releases before 0.5 seconds
- **THEN** the current parameter SHALL increment by 1.0
- **AND** no continuous increment SHALL occur

#### Scenario: User long-presses increment button (hold)
- **GIVEN** user is on the save data screen editing a parameter
- **WHEN** user presses and holds the increment button for more than 0.5 seconds
- **THEN** the system SHALL enter continuous increment mode
- **AND** the current parameter SHALL increment by 10.0 every 0.5 seconds
- **AND** increments SHALL continue until user releases the button
- **AND** all timers SHALL be cleaned up when gesture ends

#### Scenario: User cancels long-press gesture
- **GIVEN** user is holding the increment button
- **WHEN** user moves finger outside button area (tap cancel)
- **THEN** all increment timers SHALL be cancelled
- **AND** no further increments SHALL occur
- **AND** no memory leaks SHALL be present

### Requirement: Cyclic Parameter Editing Interface
The system SHALL provide a cyclic parameter editing interface on the save data screen that allows users to switch between five parameters (depth, left, right, up, down) in a fixed order with visual indication of the currently selected parameter.

#### Scenario: User cycles through parameters
- **GIVEN** user is on the save data screen with depth parameter selected
- **WHEN** user taps the cycle button
- **THEN** the selected parameter SHALL change to "Left"
- **WHEN** user taps cycle button again
- **THEN** the selected parameter SHALL change to "Right"
- **AND** the sequence SHALL continue: Up → Down → Depth (wrapping)

#### Scenario: User adjusts different parameters
- **GIVEN** user has cycled to "Left" parameter
- **WHEN** user increments the value to 3.5
- **AND** user cycles to "Right" parameter
- **AND** user increments the value to 2.8
- **THEN** both values SHALL be preserved independently
- **AND** both values SHALL be saved when user saves the manual point

---

## MODIFIED Requirements

### Requirement: Main Screen Sensor Data Display
The system SHALL display real-time sensor data (heading, distance, point count) with large typography, monospaced digits, and heading accuracy indication using color-coded visual feedback.

**Previous**: Basic text display with simple labels and standard typography.

**Modified**:
- Large title text (48pt bold) for primary values (distance)
- Title text (36pt bold) for secondary values (heading)
- Monospaced digits with tabular figures for all numeric displays
- Heading accuracy indicator: green circle for accuracy <20°, red circle for >=20°
- Dividers between data sections
- Label text above each value
- Grey[400] color for labels, white/cyan for values

#### Scenario: User views sensor data with good heading accuracy
- **GIVEN** user is on the main screen
- **AND** compass accuracy is 15 degrees
- **THEN** the system SHALL display:
  - "Magnetic Heading" label
  - Heading value in large cyan text (48pt, monospaced)
  - "Heading error: 15.00" with green circle indicator
  - "Distance" label  
  - Distance value in large cyan text (48pt, monospaced)
  - "Datapoints collected:" label
  - Point count in white text
- **AND** all numeric values SHALL use monospaced digits

#### Scenario: User views sensor data with poor heading accuracy
- **GIVEN** user is on the main screen
- **AND** compass accuracy is 35 degrees
- **THEN** the heading error indicator SHALL display a red circle
- **AND** the heading error text SHALL show "Heading error: 35.00"

### Requirement: Calibration Feedback
The system SHALL display a calibration toast notification when user attempts to save a manual point with heading accuracy worse than 15 degrees.

**Previous**: No calibration feedback in Flutter app.

**Modified**:
- Toast overlay with "Move to calibrate" message
- Red text on semi-transparent black background
- Auto-dismiss after 1 second
- Prevents navigation to save data screen when accuracy insufficient

#### Scenario: User attempts to save with poor calibration
- **GIVEN** user is on the main screen
- **AND** heading accuracy is 25 degrees (poor)
- **WHEN** user taps the save button
- **THEN** the system SHALL display calibration toast "Move to calibrate"
- **AND** the toast SHALL auto-dismiss after 1 second
- **AND** the system SHALL NOT navigate to save data screen

### Requirement: Reset Survey Confirmation
The system SHALL require explicit confirmation before clearing all survey data, either via 3-second long-press gesture or confirmation dialog.

**Previous**: Simple tap with confirmation dialog only.

**Modified**:
- 3-second long-press on reset button required
- Visual feedback during long-press (optional)
- Confirmation dialog after successful long-press
- Auto-export CSV before reset (matches Swift behavior)
- Success message after reset completes

#### Scenario: User resets survey with long-press
- **GIVEN** user is on the main screen
- **WHEN** user presses and holds the reset button for 3 seconds
- **THEN** a confirmation dialog SHALL appear asking "Are you sure you want to reset all survey data?"
- **WHEN** user confirms
- **THEN** the system SHALL export current survey data as CSV
- **AND** the system SHALL clear all survey data
- **AND** the system SHALL reset distance counter to 0
- **AND** the system SHALL reset point counter to 0
- **AND** the system SHALL display "Data reset successfully" message

---

## MODIFIED Requirements (Settings Screen)

### Requirement: Settings Screen Organization
The system SHALL organize settings into logical sections with live magnetic field debug information and navigation to button customization.

**Previous**: Flat list of settings with export buttons.

**Modified**:
- Section 1: Magnetic Axis Selection (segmented picker for X/Y/Z)
- Section 2: Calibration controls (thresholds, start/cancel calibration)
- Section 3: Wheel Settings (diameter in cm)
- Section 4: Magnetic Debug Info (live X/Y/Z/magnitude display)
- Section 5: Links (Documentation, Button Customization)
- Section 6: Reset to Defaults (red button)

#### Scenario: User views live magnetic field data
- **GIVEN** user is on the settings screen
- **WHEN** magnetometer is active
- **THEN** the Magnetic Debug Info section SHALL display:
  - "X: XX.XX μT" (monospaced)
  - "Y: YY.YY μT" (monospaced)
  - "Z: ZZ.ZZ μT" (monospaced)
  - "Magnitude: MM.MM μT" (monospaced)
- **AND** values SHALL update in real-time as device moves

#### Scenario: User navigates to button customization
- **GIVEN** user is on the settings screen
- **WHEN** user taps "Button Customization" link
- **THEN** the system SHALL navigate to the button customization screen
- **AND** the settings screen SHALL remain in navigation stack for back navigation

---

## MODIFIED Requirements (Map Screen)

### Requirement: Map Gesture Handling
The system SHALL support simultaneous pan, zoom, and rotate gestures on the map view using Flutter's GestureDetector with scale gesture recognition.

**Previous**: Basic tap-based interaction only.

**Modified**:
- Pan gesture: Single-finger drag translates map offset
- Zoom gesture: Two-finger pinch scales map (0.1x to 10x)
- Rotate gesture: Two-finger rotation rotates map around center
- All three gestures SHALL work simultaneously
- Gesture state SHALL persist across gesture sequences

#### Scenario: User pans and zooms simultaneously
- **GIVEN** user is viewing the map
- **WHEN** user performs pinch gesture while dragging
- **THEN** the map SHALL zoom to the pinch scale
- **AND** the map SHALL translate to follow the drag
- **AND** both transformations SHALL apply smoothly without conflicts

### Requirement: Compass Overlay on Map
The system SHALL display a north-pointing compass overlay in the top-right corner of the map that rotates inversely to the map rotation to always indicate north.

**Previous**: No compass overlay in Flutter map.

**Modified**:
- Compass positioned in top-right corner
- White icon on semi-transparent black circular background
- Rotates opposite to map rotation (if map rotates 45° clockwise, compass rotates 45° counter-clockwise)
- Always indicates true north direction

#### Scenario: User rotates map and compass updates
- **GIVEN** user is viewing the map with 0° rotation
- **WHEN** user rotates the map 90 degrees clockwise
- **THEN** the compass overlay SHALL rotate 90 degrees counter-clockwise
- **AND** the compass arrow SHALL point upward (north) relative to world coordinates

### Requirement: Map Export Buttons
The system SHALL display circular export buttons in the bottom-left corner of the map for quick access to CSV and Therion export functions.

**Previous**: No export buttons on map screen.

**Modified**:
- CSV export button: Purple circular button with export icon
- Therion export button: Gray circular button with document icon
- Both positioned at bottom-left with vertical spacing
- Buttons trigger export and share sheet

#### Scenario: User exports CSV from map
- **GIVEN** user is viewing the map with survey data
- **WHEN** user taps the purple CSV export button
- **THEN** the system SHALL generate CSV file
- **AND** the system SHALL display share sheet for file sharing
- **AND** user SHALL remain on map screen

---

## ADDED Requirements (Color Scheme and Typography)

### Requirement: Consistent Color Palette
The system SHALL apply a consistent semantic color palette across all screens matching the Swift iOS app's color scheme.

#### Scenario: User navigates through all screens
- **GIVEN** user navigates between main, save data, settings, map, and customization screens
- **THEN** all screens SHALL use the following color palette:
  - Save/Confirm actions: Green (`Colors.green`)
  - Map/Navigation/Cycle actions: Blue (`Colors.blue` or `Colors.blue[700]`)
  - Increment/Decrement/Warning actions: Orange (`Colors.orange`)
  - Reset/Delete/Cancel actions: Red (`Colors.red` or `Colors.red[700]`)
  - Export CSV: Purple (`Colors.purple`)
  - Export Therion: Gray (`Colors.grey`)
  - Background (main): Black (`Colors.black`)
  - Background (cards): Dark gray (`Colors.grey[900]`)
  - Text (primary): White (`Colors.white`)
  - Text (secondary): Gray (`Colors.grey[400]`)

### Requirement: Typography Scale
The system SHALL use a consistent typography scale with appropriate font sizes, weights, and monospaced digits for numeric values.

#### Scenario: User views text on any screen
- **GIVEN** user is on any screen in the app
- **THEN** text SHALL use the following typography scale:
  - Large Title: 48pt, bold, monospaced digits (primary values like distance)
  - Title: 36pt, bold, monospaced digits (secondary values like heading)
  - Headline: 26-28pt, bold/black, rounded design (labels, parameter names)
  - Body: 18pt, regular/semibold (general text, parameter labels)
  - Caption: 12-14pt, regular (hints, secondary info)
- **AND** all numeric displays SHALL use tabular figures (monospaced digits)
- **AND** icon sizes SHALL scale proportionally to button sizes (35-40% for icons, 20-26% for text)

---

## REMOVED Requirements

### Requirement: Rectangular Button Layout with Fixed Positions
**Reason**: Migrating to circular buttons with customizable positioning for better underwater usability and to match Swift app's proven UX patterns.

**Migration**: Existing rectangular buttons are replaced with circular action buttons. No user data migration needed. Users will need to customize button positions if defaults don't suit their workflow, but defaults match Swift app positions.

---

## Technical Notes

### Implementation Approach
1. **Stack-based Layout**: Use Flutter's `Stack` widget with `Positioned` children to replicate SwiftUI's `ZStack` with offset positioning
2. **Button Customization Service**: Implement `ButtonCustomizationService` extending `ChangeNotifier` with Hive persistence
3. **Gesture Detection**: Use `GestureDetector` with manual timer-based discrimination for tap vs long-press (0.5s threshold)
4. **Theme Extensions**: Define color and typography constants in `lib/utils/theme_extensions.dart`
5. **Reusable Components**: Create widget library for circular buttons, info cards, compass overlay, etc.

### State Management
- Existing Provider pattern with ChangeNotifier services
- ButtonCustomizationService added to Provider hierarchy
- Local StatefulWidget state for UI-only state (gesture tracking, parameter selection)

### Performance Considerations
- Limit positioned buttons to 4-6 per screen to maintain performance
- Use `Consumer` with specific service types to minimize rebuilds
- Throttle sensor updates to 10-20Hz for UI display
- Use `const` widgets where possible
- Profile with Flutter DevTools to identify bottlenecks

### Cross-Platform Compatibility
- All patterns implemented using Flutter built-in widgets (no platform-specific code)
- Test on both iOS and Android devices
- Ensure touch target sizes meet platform guidelines (minimum 48x48 logical pixels)

### Accessibility
- Add Semantics widgets to all custom buttons with proper labels
- Ensure sufficient color contrast (white icons on colored backgrounds)
- Test with iOS VoiceOver and Android TalkBack
- Minimum button size respects accessibility guidelines

### Testing Strategy
- Unit tests for ButtonConfig model and customization service
- Widget tests for reusable components
- Integration tests for gesture handling and navigation flows
- Manual tests for visual comparison with Swift app
- Golden tests for visual regression (optional)

---

## Cross-References

- Related to survey data capture (automatic and manual points)
- Related to sensor services (magnetometer, compass)
- Related to data export functionality
- Related to settings persistence

## Version History

- **2025-12-09**: Initial delta for Swift UI migration
