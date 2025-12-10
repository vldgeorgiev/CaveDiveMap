# Implementation Tasks: Migrate Swift UI to Flutter

**Change ID**: migrate-swift-ui-to-flutter  
**Status**: Pending Approval

## Task Checklist

### Phase 1: Foundation (Tasks 1-15)

#### Theme and Styling Foundation
- [x] **Task 1**: Create `lib/utils/theme_extensions.dart`
  - Define color palette constants matching Swift app
  - Define text style constants (large title, title, headline, body, caption)
  - Export monospaced digit TextStyle helper
  - Validation: Colors and text styles accessible app-wide

- [x] **Task 2**: Update `lib/main.dart` theme configuration
  - Apply custom color scheme from theme_extensions.dart
  - Set default text styles
  - Configure Material 3 theming
  - Validation: Theme colors applied throughout app

#### Button Customization System
- [x] **Task 3**: Create `lib/models/button_config.dart`
  - Define ButtonConfig class (size, offsetX, offsetY)
  - Add Hive TypeAdapter for serialization
  - Add copyWith method
  - Validation: Model serializes/deserializes correctly

- [x] **Task 4**: Create `lib/models/button_customization_settings.dart`
  - Define ButtonCustomizationSettings class extending ChangeNotifier
  - Add properties for all 8 buttons (4 main screen, 4 save data view)
  - Add default values matching Swift defaults
  - Add resetToDefaults() method
  - Validation: Settings model with proper defaults
  - Note: Implemented as ButtonCustomizationService instead

- [x] **Task 5**: Update `lib/services/storage_service.dart`
  - Add saveButtonCustomization method
  - Add loadButtonCustomization method
  - Register ButtonConfig Hive adapter
  - Add default values fallback
  - Validation: Button settings persist across app restarts

- [x] **Task 6**: Create `lib/services/button_customization_service.dart`
  - Extend ChangeNotifier
  - Load settings from StorageService on init
  - Expose getters for each button config
  - Add update methods that notify listeners and save
  - Add resetAllToDefaults method
  - Validation: Service loads, updates, and persists settings

- [x] **Task 7**: Add ButtonCustomizationService to Provider hierarchy
  - Register in main.dart MultiProvider
  - Initialize on app startup
  - Validation: Service accessible via context.read/watch

#### Reusable Components
- [x] **Task 8**: Create `lib/widgets/circular_action_button.dart`
  - Accept parameters: color, icon, size, onTap, onLongPress
  - Render circular button with icon scaled to 35-40% of size
  - Add shadow and styling matching Swift
  - Validation: Button renders with correct proportions

- [x] **Task 9**: Create `lib/widgets/positioned_button.dart`
  - Wrap CircularActionButton in Positioned widget
  - Accept ButtonConfig for positioning
  - Calculate absolute position from screen center with offsets
  - Validation: Button positions correctly with various offset values

- [x] **Task 10**: Create `lib/widgets/monospaced_text.dart`
  - Reusable widget for numeric displays
  - Apply tabular figures font feature
  - Accept fontSize, fontWeight, color parameters
  - Validation: Numbers align properly in columns

- [x] **Task 11**: Create `lib/widgets/heading_accuracy_indicator.dart`
  - Display colored circle (green <20°, red >=20°)
  - Accept accuracy value
  - Show "Heading error: X.XX" with indicator
  - Validation: Color changes at 20° threshold

- [x] **Task 12**: Create `lib/widgets/calibration_toast.dart`
  - Overlay message "Move to calibrate"
  - Red text on semi-transparent black background
  - Auto-dismiss after duration
  - Validation: Toast appears and dismisses smoothly

- [x] **Task 13**: Create `lib/widgets/info_card.dart`
  - Rounded rectangle container with grey[900] background
  - Border with secondary color
  - Padding and proper styling
  - Validation: Card renders with consistent styling

- [x] **Task 14**: Create `lib/widgets/compass_overlay.dart`
  - Compass indicator for map view
  - Accepts map rotation angle
  - Shows north arrow relative to rotation
  - Positioned in top-right corner
  - Validation: Arrow points north regardless of map rotation

- [ ] **Task 15**: Test all foundation components
  - Unit tests for ButtonConfig model
  - Widget tests for each reusable component
  - Integration test for button customization service
  - Validation: All tests pass

### Phase 2: Main Screen Redesign (Tasks 16-30)

- [x] **Task 16**: Backup existing main_screen.dart
  - Copy to main_screen_old.dart for reference
  - Validation: Backup exists
  - Note: Not backed up, but redesign complete

- [x] **Task 17**: Redesign MainScreen layout structure
  - Convert to Stack-based layout
  - Top layer: sensor data display
  - Bottom layer: positioned circular buttons
  - Validation: Layout structure in place

- [x] **Task 18**: Implement sensor data display section
  - Large "Magnetic Heading" title (largeTitle style)
  - Heading value in degrees (48pt, monospaced, cyan)
  - Heading error display with accuracy indicator
  - Divider
  - "Distance" title (largeTitle style)
  - Distance value in meters (48pt, monospaced, cyan)
  - Divider
  - "Datapoints collected" with count
  - Validation: Data displays match Swift sizing and layout

- [x] **Task 19**: Add HeadingAccuracyIndicator to main screen
  - Position below heading value
  - Pass accuracy from CompassService
  - Validation: Indicator shows correct color based on accuracy

- [x] **Task 20**: Implement circular Save button
  - Use PositionedButton with ButtonConfig from service
  - Green color, save icon
  - Navigate to SaveDataScreen on tap
  - Show calibration toast if accuracy >15°
  - Validation: Button positioned correctly, navigation works

- [x] **Task 21**: Implement circular Map button
  - Use PositionedButton with ButtonConfig
  - Blue color, map icon
  - Navigate to MapScreen on tap
  - Validation: Button positioned correctly, navigation works

- [x] **Task 22**: Implement circular Reset button
  - Use PositionedButton with ButtonConfig
  - Red color, "Reset" text (not icon)
  - 3-second long-press detection
  - Show confirmation dialog
  - Clear all data on confirm
  - Validation: Long-press works, data clears, shows success message

- [x] **Task 23**: Implement circular Camera button (placeholder)
  - Use PositionedButton with ButtonConfig
  - Orange color, camera icon
  - Show "Camera not implemented" toast on tap
  - Validation: Button visible but non-functional as expected

- [x] **Task 24**: Add CalibrationToast overlay
  - Show when attempting to save with poor accuracy
  - Auto-dismiss after 1 second
  - Validation: Toast appears and dismisses correctly

- [x] **Task 25**: Add settings gear icon to AppBar
  - Top-left position
  - Navigate to SettingsScreen
  - Stop and restart sensors on return
  - Validation: Navigation works, sensors restart

- [x] **Task 26**: Implement Consumer for reactive updates
  - Watch MagnetometerService for distance/point updates
  - Watch CompassService for heading/accuracy updates
  - Watch ButtonCustomizationService for button positions
  - Validation: UI updates in real-time

- [x] **Task 27**: Apply typography from theme_extensions
  - All text uses defined styles
  - Numeric values use monospaced text
  - Consistent sizing throughout
  - Validation: Typography matches Swift app

- [ ] **Task 28**: Test main screen on different devices
  - iPhone SE size (small)
  - iPhone 15 Pro size (medium)
  - iPad size (large)
  - Android equivalents
  - Validation: Layout works on all sizes

- [x] **Task 29**: Test button customization on main screen
  - Open customization screen
  - Adjust save button size and position
  - Return to main screen
  - Verify button reflects changes
  - Validation: Customization works end-to-end

- [x] **Task 30**: Polish main screen visual details
  - Proper spacing and padding
  - Shadow effects if needed
  - Background colors correct
  - Validation: Screen looks polished

### Phase 3: Save Data Screen Redesign (Tasks 31-50)

- [x] **Task 31**: Backup existing save_data_screen.dart
  - Copy to save_data_screen_old.dart
  - Validation: Backup exists
  - Note: Not backed up, redesign complete

- [x] **Task 32**: Redesign SaveDataScreen layout structure
  - Top: InfoCard with point number, distance, heading
  - Middle: Large parameter display
  - Bottom: Stack with positioned circular buttons
  - Validation: Layout structure in place

- [x] **Task 33**: Implement header InfoCard
  - Show "Point Number: X"
  - Show "Distance: X.XX m"
  - Show "Heading: X.XX°"
  - Use font size 26, bold/semibold, rounded design
  - Grey[900] background with border
  - Validation: Card matches Swift styling

- [x] **Task 34**: Implement large parameter display
  - Show currently selected parameter name (28pt, black weight)
  - Show parameter value (36pt, black weight, monospaced)
  - Center aligned
  - Grey[900] background card
  - Validation: Display updates when parameter changes

- [x] **Task 35**: Create parameter cycling logic
  - State variable for current parameter index (0-4)
  - cycleParameter method increments index modulo 5
  - Order: Depth → Left → Right → Up → Down
  - Validation: Cycles through all 5 parameters

- [x] **Task 36**: Implement Decrement button
  - Orange circular button, minus icon
  - Positioned using ButtonConfig
  - Tap: decrement by 1.0
  - Long-press: start rapid decrement
  - Validation: Tap and long-press work correctly

- [x] **Task 37**: Implement Increment button
  - Orange circular button, plus icon
  - Positioned using ButtonConfig
  - Tap: increment by 1.0
  - Long-press: start rapid increment
  - Validation: Tap and long-press work correctly

- [x] **Task 38**: Implement Save button
  - Green circular button, "Save" text
  - Positioned using ButtonConfig
  - Save manual point with all parameters
  - Navigate back to main screen
  - Show success snackbar
  - Validation: Point saves with correct data

- [x] **Task 39**: Implement Cycle button
  - Blue circular button, cycle icon
  - Positioned using ButtonConfig
  - Cycle to next parameter on tap
  - Validation: Parameter cycles correctly

- [x] **Task 40**: Implement tap vs long-press detection
  - Use GestureDetector with onTapDown/onTapUp/onTapCancel
  - Schedule 0.5s timer on tap down
  - If timer fires: enter long-press mode
  - If tap up before timer: single tap
  - Clean up timers on cancel/up
  - Validation: Distinguishes tap from hold correctly

- [x] **Task 41**: Implement rapid adjustment on long-press
  - Start repeating timer on long-press threshold
  - Increment/decrement by 10.0 every 0.5s
  - Stop timer on gesture end
  - Validation: Rapid adjustment repeats correctly

- [ ] **Task 42**: Add visual feedback for long-press
  - Button scale or opacity change during hold
  - Validation: User can see button is being held

- [x] **Task 43**: Ensure parameter values respect bounds
  - All parameters clamp to 0.0 minimum
  - Depth max: 200.0m
  - Other parameters max: 100.0m
  - Validation: Values don't exceed limits

- [x] **Task 44**: Add all dimensions summary display (optional)
  - Grid showing all 5 parameters with values
  - Highlight currently selected parameter
  - Below large parameter display
  - Validation: All values visible at once

- [x] **Task 45**: Apply typography from theme_extensions
  - Header card: 26pt semibold
  - Parameter name: 28pt black
  - Parameter value: 36pt black monospaced
- [x] **Task 45**: Apply typography from theme_extensions
  - Header card: 26pt semibold
  - Parameter name: 28pt black
  - Parameter value: 36pt black monospaced
  - Validation: Typography matches Swift

- [ ] **Task 46**: Test save data screen on different devices
  - Small, medium, large screens
  - iOS and Android
  - Validation: Layout adapts properly

- [x] **Task 47**: Test tap vs long-press interaction
  - Tap increments by 1.0
  - Hold >0.5s starts rapid increment
  - Release stops rapid increment
  - No stuck timers
  - Validation: Gesture handling robust

- [x] **Task 48**: Test parameter cycling
  - Cycle button switches parameter
  - All 5 parameters accessible
  - Values persist when cycling back
  - Validation: Cycling works smoothly

- [x] **Task 49**: Test data persistence
  - Enter parameter values
  - Save manual point
  - Verify data in storage
  - Check CSV export includes manual point
  - Validation: Manual points saved correctly

- [x] **Task 50**: Polish save data screen visual details
  - Spacing, padding, alignment
  - Button colors and shadows
  - Card styling
  - Validation: Screen looks polished

### Phase 4: Settings Screen Enhancement (Tasks 51-70)

- [x] **Task 51**: Backup existing settings_screen.dart
  - Copy to settings_screen_old.dart
  - Validation: Backup exists
  - Note: Not backed up, redesign complete

- [x] **Task 52**: Reorganize settings into sections
  - Section 1: Magnetic Axis Selection
  - Section 2: Calibration
  - Section 3: Wheel Settings
  - Section 4: Magnetic Debug Info
  - Section 5: Links (Documentation, Button Customization)
  - Section 6: Reset to Defaults
  - Validation: Section structure in place
  - Note: Sections simplified, some merged/removed

- [ ] **Task 53**: Implement Magnetic Axis Selection section
  - SegmentedButton with options: X, Y, Z
  - Save selection to settings
  - Pass to MagnetometerService
  - Validation: Axis selection persists and affects measurement

- [ ] **Task 54**: Implement Calibration section
  - Text fields for low/high threshold
  - Validate numeric input with decimal support
  - Start Calibration button (10s duration)
  - Cancel Calibration button during calibration
  - Progress indicator and countdown
  - Validation: Calibration runs for 10s, updates thresholds

- [x] **Task 55**: Implement Wheel Settings section
  - Text field for wheel diameter (cm)
  - Convert to circumference and save
  - Validate positive number
  - Validation: Wheel circumference updates correctly
  - Note: Implemented in millimeters

- [x] **Task 56**: Implement Magnetic Debug Info section
  - Display live magnetic field X, Y, Z (μT)
  - Display magnitude
  - Update in real-time from MagnetometerService
  - Use monospaced digits
  - Validation: Values update live as device moves

- [x] **Task 57**: Add Documentation link
  - Link to GitHub repository
  - Opens in browser (url_launcher package if needed, or simple_browser)
  - Validation: Link opens correctly

- [x] **Task 58**: Add Button Customization link
  - Navigate to ButtonCustomizationScreen
  - Validation: Navigation works

- [ ] **Task 59**: Implement Reset to Defaults button
  - Red styling to indicate caution
  - Confirmation dialog before resetting
  - Reset all settings to defaults
  - Validation: Settings reset correctly

- [x] **Task 60**: Style section headers and dividers
  - Match Swift's section header styling
  - Proper spacing between sections
  - Validation: Sections visually distinct

- [x] **Task 61**: Implement number field validation
  - Accept digits and decimal separator
  - Only one decimal separator allowed
  - Prevent invalid characters
  - Show error message for invalid input
  - Validation: Invalid input rejected gracefully

- [x] **Task 62**: Add Save Settings button
  - Green button at bottom
  - Validate all fields before saving
  - Show success snackbar
  - Navigate back to main screen
  - Validation: Settings save correctly
  - Note: Auto-save implemented instead

- [x] **Task 63**: Test settings persistence
  - Change multiple settings
  - Save and restart app
  - Verify all settings loaded correctly
  - Validation: Settings persist across restarts

- [ ] **Task 64**: Test calibration flow
  - Start calibration
  - Verify 10s countdown
  - Verify thresholds updated after completion
  - Test cancel during calibration
  - Validation: Calibration works correctly

- [x] **Task 65**: Test magnetic field display
  - Move device around
  - Verify X, Y, Z values update
  - Verify magnitude calculated correctly
  - Validation: Debug info accurate

- [x] **Task 66**: Apply typography from theme_extensions
  - Section headers
  - Field labels
  - Debug info display
  - Validation: Typography consistent

- [ ] **Task 67**: Test settings on different devices
  - Small, medium, large screens
  - iOS and Android
  - Validation: Form layout responsive

- [ ] **Task 68**: Test number input on different keyboards
  - iOS numeric keyboard
  - Android numeric keyboard
  - Validation: Input works on both platforms

- [x] **Task 69**: Polish settings screen visual details
  - Form styling
  - Button styling
  - Section dividers
  - Validation: Screen looks professional

- [x] **Task 70**: Update settings documentation
  - Add comments for each setting
  - Document valid ranges
  - Validation: Code well-documented

### Phase 5: Button Customization Screen (Tasks 71-85)

- [x] **Task 71**: Create `lib/screens/button_customization_screen.dart`
  - Basic scaffold with AppBar
  - Validation: Screen exists and navigates
  - Note: Redesigned with drag-and-drop interface instead of sliders
  - Design documentation: See `button-customization-drag-redesign.md`

- [x] **Task 71.1**: Create `lib/widgets/draggable_button_customizer.dart`
  - Draggable button wrapper for visual customization
  - Converts between center-based offsets and absolute screen positions
  - Shows selection highlight and label when selected
  - Animates during drag with scale effect
  - Validation: Buttons can be dragged and repositioned
  - Full-screen mode with compact top bar (size slider + instructions)
  - Buttons constrained below 100px top bar

- [x] **Task 72**: Implement screen context selector
  - SegmentedButton with "Main Screen" and "Save Data View"
  - State variable for selected context
  - Validation: Selector switches between contexts
  - Note: Clears button selection when switching screens

- [x] **Task 73**: Implement button selection
  - Tap any button in preview to select it
  - Selected button shows highlight border and label
  - Only one button selected at a time
  - Validation: Button selection toggles on tap

- [x] **Task 74**: Implement interactive full-screen editor
  - Tap preview area to enter full-screen mode
  - All 4 buttons visible and draggable across entire screen
  - Center crosshair guide for positioning reference (below top bar)
  - Compact top bar with instructions and close button
  - Validation: All buttons visible and draggable simultaneously

- [x] **Task 75**: Implement Size slider (top bar)
  - Range: 40-150
  - Only shown when button is selected
  - Compact display in top bar (icon + value + slider + button name)
  - Updates selected button config in real-time
  - Validation: Slider adjusts button size

- [x] **Task 76**: Position adjustment via drag
  - Buttons positioned by dragging in full-screen area
  - Offsets clamped to available screen bounds (below top bar)
  - Updates config on drag end
  - Visual feedback during drag (10% scale up)
  - Validation: Drag repositions buttons accurately
  - Note: Replaces horizontal/vertical position sliders

- [x] **Task 77**: Implement live visual feedback
  - Full-screen interactive editor mode
  - All buttons for current screen visible at once
  - Selected button highlighted with border and label
  - Real-time updates as size changes
  - Buttons cannot enter top bar area (100px)
  - Validation: Preview updates immediately

- [x] **Task 78**: Implement Reset All to Defaults button
  - Red styling in bottom control panel
  - Confirmation dialog
  - Resets all 8 buttons to defaults
  - Clears button selection after reset
  - Validation: Reset works correctly

- [x] **Task 79**: Implement Save button
  - Green button at bottom
  - Saves all button configs to storage
  - Shows success snackbar
  - Navigate back
  - Validation: Changes persist
  - Note: Auto-save implemented instead

- [ ] **Task 80**: Add constraints to position sliders
  - Prevent buttons from going completely off-screen
  - Calculate screen bounds
  - Validation: Buttons always partially visible

- [ ] **Task 81**: Add live preview interaction
  - Tap button in preview to select it
  - Validation: Selecting button in preview updates sliders

- [x] **Task 82**: Style button customization screen
  - Match settings screen styling
  - Clear section divisions
  - Validation: Screen looks professional

- [x] **Task 83**: Test button customization workflow
  - Select main screen context
  - Adjust save button size and position
  - Save changes
  - Return to main screen
  - Verify button reflects changes
  - Validation: End-to-end customization works

- [x] **Task 84**: Test reset to defaults
  - Customize several buttons
  - Reset to defaults
  - Verify all buttons restored
  - Validation: Reset works for all buttons

- [x] **Task 85**: Test customization persistence
  - Customize buttons
  - Close and reopen app
  - Verify customizations loaded
  - Validation: Settings persist across restarts

### Phase 6: Map Screen Enhancement (Tasks 86-100)

- [x] **Task 86**: Add CompassOverlay to map screen
  - Position in top-right corner
  - Pass map rotation angle
  - Show north arrow
  - Validation: Compass rotates with map

- [ ] **Task 87**: Add export CSV button
  - Purple circular button, bottom-left
  - Export icon
  - Tap to export and share CSV
  - Validation: CSV export triggered from map

- [ ] **Task 88**: Add export Therion button
  - Gray circular button, bottom-left below CSV
  - Document icon
  - Tap to export and share Therion file
  - Validation: Therion export triggered from map

- [x] **Task 89**: Enhance pan gesture handling
  - Use GestureDetector for drag
  - Update map offset on drag
  - Preserve offset across gestures
  - Validation: Pan gesture smooth

- [x] **Task 90**: Enhance zoom gesture handling
  - Use ScaleGestureRecognizer
  - Update scale on pinch
  - Clamp scale to 0.1-10.0 range
  - Preserve scale across gestures
  - Validation: Zoom gesture smooth

- [x] **Task 91**: Enhance rotate gesture handling
  - Use RotationGestureRecognizer
  - Update rotation on two-finger rotate
  - Preserve rotation across gestures
  - Validation: Rotate gesture smooth

- [x] **Task 92**: Implement simultaneous gesture recognition
  - Allow pan, zoom, and rotate at same time
  - Test complex multi-finger gestures
  - Validation: Gestures don't conflict

- [x] **Task 93**: Improve cave profile drawing
  - Use manual points for wall offsets
  - Draw closed polygon for cave outline
  - Draw centerline with markers
  - Add labels for point numbers
  - Validation: Cave profile visible and accurate

- [x] **Task 94**: Add empty state message
  - Show "No manual data available to draw cave walls"
  - Center in screen when no data
  - Validation: Empty state appears when appropriate

- [ ] **Task 95**: Implement fit-to-bounds on load
  - Calculate bounding box of all points
  - Set initial scale and offset to fit
  - Only on first load, not every time
  - Validation: Map centered on data initially

- [ ] **Task 96**: Test map on different screen sizes
  - Small, medium, large devices
  - Portrait and landscape
  - Validation: Map scales appropriately

- [x] **Task 97**: Test all map gestures
  - Pan in all directions
  - Zoom in and out
  - Rotate 360 degrees
  - Simultaneous gestures
  - Validation: All gestures smooth and accurate

- [x] **Task 98**: Test compass overlay
  - Rotate map
  - Verify north arrow always points up
  - Validation: Compass accurate

- [ ] **Task 99**: Test export buttons
  - Tap CSV button, verify share sheet
  - Tap Therion button, verify share sheet
  - Validation: Exports accessible from map

- [x] **Task 100**: Polish map screen visual details
  - Colors for cave profile
  - Button shadows
  - Compass styling
  - Validation: Map looks polished

### Final Validation and Documentation

- [ ] **Task 101**: Comprehensive visual comparison
  - Screenshots of Swift app screens
  - Screenshots of Flutter app screens
  - Side-by-side comparison document
  - Validation: Visual similarity achieved

- [ ] **Task 102**: Comprehensive interaction testing
  - Test every button on every screen
  - Test all gestures
  - Test all navigation flows
  - Validation: All interactions work

- [ ] **Task 103**: Cross-platform testing
  - Test on iOS device
  - Test on Android device
  - Document any platform-specific issues
  - Validation: Works on both platforms

- [ ] **Task 104**: Performance profiling
  - Run Flutter DevTools
  - Check for jank during sensor updates
  - Check for memory leaks
  - Optimize if needed
  - Validation: App runs smoothly (60 FPS)

- [ ] **Task 105**: Update IMPLEMENTATION_STATUS.md
  - Mark UI migration as complete
  - Document any deviations from Swift app
  - List known issues or future enhancements
  - Validation: Documentation accurate

- [ ] **Task 106**: Update README.md
  - Add screenshots of new UI
  - Document button customization feature
  - Update feature list
  - Validation: README reflects current state

- [ ] **Task 107**: Code cleanup
  - Remove commented-out code
  - Remove backup files (_old.dart)
  - Format all code (flutter format)
  - Validation: Code clean and consistent

- [ ] **Task 108**: Final code review
  - Check for TODOs
  - Check for hardcoded values
  - Check for missing error handling
  - Validation: Code quality high

- [ ] **Task 109**: Create demo video
  - Record screen showing all features
  - Show button customization
  - Show map interactions
  - Validation: Video demonstrates UI migration

- [ ] **Task 110**: Archive change proposal
  - Move to openspec/changes/archive/
  - Update specs if needed
  - Mark change as complete
  - Validation: Change properly archived

## Progress Tracking

- **Total Tasks**: 110
- **Completed**: 79
- **In Progress**: 0
- **Not Started**: 31

## Summary by Phase

- **Phase 1 (Foundation)**: 14/15 complete (93%)
- **Phase 2 (Main Screen)**: 14/15 complete (93%)
- **Phase 3 (Save Data Screen)**: 18/20 complete (90%)
- **Phase 4 (Settings Screen)**: 15/20 complete (75%)
- **Phase 5 (Button Customization)**: 13/15 complete (87%)
- **Phase 6 (Map Screen)**: 5/15 complete (33%)
- **Final Validation**: 0/10 complete (0%)

## Notes

- Tasks are designed to be completed sequentially within each phase
- Each task includes validation criteria to ensure quality
- Some tasks may be parallelizable (e.g., creating multiple widgets)
- Estimated time: 20-30 hours total (based on complexity and testing)
