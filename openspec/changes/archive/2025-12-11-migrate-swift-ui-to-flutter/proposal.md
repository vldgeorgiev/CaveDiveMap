# Proposal: Migrate Swift iOS UI to Flutter

**Status**: Approved ✓ (2025-12-09)  
**Change ID**: migrate-swift-ui-to-flutter  
**Author**: AI Assistant  
**Date**: 2025-12-09

## Summary

Migrate the user interface design, styling, and interaction patterns from the archived Swift iOS app to the Flutter cross-platform implementation. This includes replicating button layouts, color schemes, typography, interaction patterns (tap vs long-press), and overall visual feel while adapting to Flutter's Material Design patterns.

## Motivation

The Flutter app currently has basic functional screens but lacks the refined UI/UX of the original Swift iOS app. The Swift version features:

1. **Custom button positioning system** - Allows users to resize and reposition buttons for underwater usability with waterproof cases
2. **Distinctive color scheme** - Green (save), blue (map/cycle), orange (increment/decrement/camera), red (reset), purple (export)
3. **Large, touch-friendly controls** - Circular buttons sized 70-75pt with proportional icons
4. **Cyclic parameter editing** - Single-tap increment/decrement, long-press for rapid adjustment
5. **Clean data presentation** - Large monospaced digits, clear visual hierarchy
6. **Underwater-optimized UX** - High contrast, minimal distractions, essential info only

Migrating these patterns ensures feature parity and provides a consistent experience for users transitioning from iOS to the cross-platform Flutter app.

## Goals

### Primary Goals
1. **Replicate main screen UI** - Match ContentView's layout with sensor data display and circular button controls
2. **Implement SaveDataView patterns** - Cyclic parameter editing with tap/long-press gestures
3. **Apply color scheme consistently** - Use Swift app's button colors throughout Flutter UI
4. **Add button customization system** - Port ButtonCustomizationSettings for position/size adjustment
5. **Match typography and spacing** - Large headings, monospaced digits, clear visual hierarchy
6. **Preserve interaction patterns** - Tap vs hold, gesture handling, navigation flows

### Secondary Goals
1. **Adapt to Material Design** - Use Flutter widgets while maintaining visual similarity
2. **Cross-platform considerations** - Ensure UI works well on both iOS and Android
3. **Improve accessibility** - Leverage Flutter's accessibility features
4. **Maintain performance** - Keep UI responsive during real-time sensor updates

### Non-Goals
1. **Exact pixel-perfect replication** - Similar feel, not identical rendering
2. **AR/3D visualization** - Deferred to future enhancement (VisualMapper from Swift app)
3. **Camera integration** - Not part of core survey functionality
4. **Point cloud visualization** - Advanced feature for later implementation

## Requirements

### R1: Main Screen UI (ContentView Equivalent)

**Current State**: Flutter MainScreen has basic sensor data display with simple rectangular buttons at bottom.

**Desired State**: 
- Large, prominent sensor data displays with proper typography (matching Swift's font sizes)
- Circular action buttons with customizable positioning (ZStack overlay pattern)
- Button colors: Green (save), Blue (map), Red (reset), Orange (camera placeholder)
- Monospaced digits for numeric values
- Heading accuracy indicator (green <20° error, red otherwise)
- Top-left settings gear icon
- Calibration toast notifications

**UI Elements**:
```
┌─────────────────────────────┐
│ ⚙️ Settings                  │
│                             │
│      Magnetic Heading       │
│         245.32°             │
│                             │
│   Heading error: 8.45  🟢   │
│                             │
│         Distance            │
│         12.45 m             │
│                             │
│   Datapoints collected:     │
│            15               │
│                             │
│                             │
│          [🗺️] [🔴]          │  <- Circular buttons
│      [💾]      [📷]          │     with custom offsets
└─────────────────────────────┘
```

**Acceptance Criteria**:
- [ ] Sensor data displays match Swift font sizes and weights
- [ ] Circular buttons with proper color coding
- [ ] Button positioning can be customized (via settings)
- [ ] Heading accuracy indicator shows green/red circle
- [ ] Monospaced digits for all numeric displays
- [ ] Calibration toast appears when needed
- [ ] 3-second long-press on reset button requires confirmation

### R2: Save Data Screen UI (SaveDataView Equivalent)

**Current State**: Flutter SaveDataScreen has basic parameter editing with small rectangular +/- buttons.

**Desired State**:
- Header card showing current point info (number, distance, heading)
- Large central display of currently selected parameter
- Cyclic parameter selection (depth → left → right → up → down → depth)
- Large circular buttons: Orange (decrement), Green (save), Orange (increment), Blue (cycle)
- Buttons positioned using custom offsets
- Tap: increment/decrement by 1.0
- Long-press (>0.5s): rapid increment/decrement by 10.0 (repeating every 0.5s)
- Visual feedback for parameter cycling

**UI Elements**:
```
┌─────────────────────────────┐
│ Point Number: 16            │
│ Distance: 12.45 m           │
│ Heading: 245.32°            │
│ ─────────────────────────── │
│                             │
│          Depth              │  <- Current parameter
│         5.20 m              │     (large display)
│                             │
│                             │
│                             │
│      [➖]    [💾]    [➕]     │  <- Circular buttons
│                 [🔄]         │     with offsets
└─────────────────────────────┘
```

**Acceptance Criteria**:
- [ ] Header card matches Swift's rounded design
- [ ] Parameter name and value displayed prominently (size 28/36)
- [ ] Tap increments/decrements by 1.0
- [ ] Long-press (>0.5s) triggers rapid adjustment (10.0 per 0.5s)
- [ ] Cycle button switches parameter in order
- [ ] All five parameters properly cycle through
- [ ] Button colors match Swift (orange/green/blue)
- [ ] Buttons use custom positioning system

### R3: Settings Screen Enhancements

**Current State**: Basic settings form with text fields and export buttons.

**Desired State**:
- Match Swift SettingsView layout with sections
- Display live magnetic field strength (X, Y, Z, Magnitude)
- Button customization navigation link
- Calibration controls (if implemented)
- Segmented picker for magnetic axis selection
- Formatted number fields with validation
- Documentation link
- Reset to defaults button (red)

**Sections**:
1. Magnetic Axis for Detection (segmented picker)
2. Calibration (thresholds, start/cancel buttons)
3. Wheel Settings (diameter in cm)
4. Magnetic Debug Info (live sensor readout)
5. Documentation Link
6. Button Customization Link

**Acceptance Criteria**:
- [ ] Form sections match Swift's organization
- [ ] Live magnetic field display updates in real-time
- [ ] Number fields properly formatted with decimal handling
- [ ] Button customization navigation implemented
- [ ] Reset to defaults uses red styling
- [ ] Documentation link opens browser

### R4: Button Customization System

**Current State**: No button customization in Flutter app.

**Desired State**:
- Separate screen for button customization
- Segmented picker to choose screen context (Main Screen vs Save Data View)
- Button selector (dropdown or segmented control)
- Sliders for Size (40-150), Horizontal Position (-200 to +200), Vertical Position (-200 to +200)
- Live preview showing selected button with current settings
- Reset all to defaults button
- Settings persisted to storage (Hive)
- ButtonCustomizationSettings model/service

**Button Defaults (Main Screen)**:
- Save: size 75, offset (0, 20)
- Map: size 75, offset (130, 10)
- Reset: size 75, offset (-70, -70)
- Camera: size 75, offset (70, -70)

**Button Defaults (Save Data View)**:
- Save: size 70, offset (0, 120)
- Increment: size 70, offset (100, 80)
- Decrement: size 70, offset (-100, 80)
- Cycle: size 70, offset (150, 150)

**Acceptance Criteria**:
- [ ] ButtonCustomizationSettings model with Hive adapter
- [ ] Customization screen with screen/button selectors
- [ ] Sliders for size and position adjustment
- [ ] Live preview updates as sliders change
- [ ] Settings persist across app restarts
- [ ] Reset to defaults restores original values
- [ ] Main screen buttons respect custom settings
- [ ] Save data screen buttons respect custom settings

### R5: Map Screen Enhancements

**Current State**: Basic 2D map with simple line drawing.

**Desired State**:
- Match NorthOrientedMapView's interaction patterns
- Touch gestures: pan (drag), zoom (pinch), rotate (two-finger rotation)
- North-oriented compass overlay (top-right)
- Export buttons (CSV purple circle, Therion gray circle) at bottom-left
- Cave profile drawing with left/right wall offsets (from manual points)
- Guide line with markers and labels
- Empty state message when no data
- Proper coordinate transformation (heading to Cartesian)

**Acceptance Criteria**:
- [ ] CustomPainter implements cave profile drawing
- [ ] Touch gestures: pan, zoom, rotate all functional
- [ ] Compass overlay shows north direction relative to map rotation
- [ ] Export buttons positioned at bottom-left
- [ ] Wall profiles drawn from manual point dimensions
- [ ] Empty state shows "No manual data available" message
- [ ] Initial fit-to-bounds on first load

### R6: Color Scheme and Typography

**Current State**: Generic Material Design colors with basic typography.

**Desired State**: Consistently apply Swift app's color scheme and typography patterns across all screens.

**Color Palette**:
- **Save/Confirm**: `Colors.green` (primary action)
- **Map/Navigation/Cycle**: `Colors.blue` or `Colors.blue[700]`
- **Increment/Decrement/Warning**: `Colors.orange`
- **Reset/Delete/Cancel**: `Colors.red` or `Colors.red[700]`
- **Export CSV**: `Colors.purple`
- **Export Therion**: `Colors.grey`
- **Background**: `Colors.black` (main), `Colors.grey[900]` (cards)
- **Text Primary**: `Colors.white`
- **Text Secondary**: `Colors.grey[400]`

**Typography**:
- **Large Title**: 48pt, bold, monospaced digits (distance)
- **Title**: 36pt, bold, monospaced digits (heading, depth)
- **Headline**: 26-28pt, bold/black, rounded design (labels)
- **Body**: 18pt, regular/semibold (parameter names)
- **Caption**: 12-14pt, regular (hints, secondary info)

**Icon Sizing**:
- Icons scale to 35-40% of button size for large buttons
- Icons scale to 20-26% of button size for text buttons

**Acceptance Criteria**:
- [ ] All screens use consistent color palette
- [ ] Button colors match Swift app's semantics
- [ ] Typography sizes match Swift's font specifications
- [ ] Monospaced digits used for all numeric displays
- [ ] Icon sizes scale proportionally with button sizes
- [ ] Background colors: black for screens, grey[900] for cards

### R7: Interaction Patterns

**Current State**: Basic tap interactions only.

**Desired State**: Implement Swift app's sophisticated interaction patterns.

**Patterns**:
1. **Tap vs Long-Press**:
   - Tap: Single action (increment by 1.0, decrement by 1.0)
   - Long-press (>0.5s): Rapid repeat action (increment/decrement by 10.0 every 0.5s)
   - Cancel long-press detection on gesture end

2. **Gesture Handling** (Map):
   - Simultaneous pan, pinch-zoom, and rotate gestures
   - GestureDetector for drag (pan)
   - ScaleGestureRecognizer for pinch and rotate
   - State preservation across gesture sequences

3. **Navigation**:
   - Standard Navigator.push/pop for screen transitions
   - Back button dismisses sheets/screens
   - Settings sheet dismisses and restarts sensors

4. **Confirmation Dialogs**:
   - Reset survey: 3-second long-press OR confirmation dialog
   - Data loss actions: Always confirm with AlertDialog
   - Success toasts: SnackBar with auto-dismiss

**Acceptance Criteria**:
- [ ] Increment/decrement buttons: tap (1.0), long-press (10.0 repeating)
- [ ] Long-press detection uses 0.5s threshold
- [ ] Long-press cancels on gesture end, cleans up timers
- [ ] Map gestures: pan, zoom, rotate all work simultaneously
- [ ] Reset requires 3-second hold (visual feedback)
- [ ] Data loss actions show confirmation dialog
- [ ] Success messages use green SnackBar

## Technical Approach

### Architecture
1. **Positioned Overlays**: Use `Stack` with `Positioned` widgets to replicate SwiftUI's ZStack with offset positioning
2. **Button Customization Service**: Create `ButtonCustomizationSettings` ChangeNotifier with Hive persistence
3. **Gesture Detection**: Use `GestureDetector` with custom handling for tap vs long-press discrimination
4. **Theme Extensions**: Define color scheme and text styles as ThemeData extensions
5. **Responsive Layout**: Use MediaQuery for screen-size-aware positioning

### Flutter Widget Patterns
- **Circular Buttons**: `Container` with `BoxDecoration(shape: BoxShape.circle)` or `FloatingActionButton` styled
- **Cards**: `Container` with `BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[900])`
- **Monospaced Digits**: `TextStyle(fontFeatures: [FontFeature.tabularFigures()])`
- **Segmented Control**: `SegmentedButton` widget (Material 3)
- **Sliders**: `Slider` widget with custom theming

### State Management
- Existing Provider pattern for services
- ButtonCustomizationSettings as ChangeNotifierProvider
- Local StatefulWidget state for UI-only state (gesture tracking)

## Dependencies

### Existing
- provider: State management ✓
- hive: Local storage ✓
- sensors_plus: Magnetometer ✓
- flutter_compass: Heading ✓
- share_plus: Export ✓

### New (None Required)
All patterns can be implemented with existing dependencies and Flutter built-in widgets.

## Impact Analysis

### Files to Create
- `lib/models/button_customization_settings.dart` - Button config model with Hive adapter
- `lib/services/button_customization_service.dart` - ChangeNotifier for button settings
- `lib/screens/button_customization_screen.dart` - UI for customizing buttons
- `lib/widgets/circular_action_button.dart` - Reusable circular button component
- `lib/widgets/positioned_button.dart` - Button with customizable positioning
- `lib/widgets/compass_overlay.dart` - North compass indicator for map
- `lib/utils/theme_extensions.dart` - Color and typography constants

### Files to Modify
- `lib/main.dart` - Add ButtonCustomizationSettings provider
- `lib/screens/main_screen.dart` - Redesign with circular buttons and positioning
- `lib/screens/save_data_screen.dart` - Implement cyclic editing with long-press
- `lib/screens/settings_screen.dart` - Add button customization link and sections
- `lib/screens/map_screen.dart` - Add compass overlay, export buttons, gestures
- `lib/services/storage_service.dart` - Add button settings persistence

### Database Schema
**New Hive Box**: `buttonCustomizationSettings`
- Key: `main_save`, `main_map`, `main_reset`, `main_camera`
- Key: `save_save`, `save_increment`, `save_decrement`, `save_cycle`
- Value: JSON with `{size: double, offsetX: double, offsetY: double}`

## Testing Strategy

### Manual Testing Checklist
1. **Button Positioning**:
   - Customize each button's size and position
   - Verify settings persist across app restart
   - Reset to defaults works correctly

2. **Interaction Patterns**:
   - Tap increments/decrements by 1.0
   - Long-press triggers rapid adjustment after 0.5s
   - Long-press repeats every 0.5s until release
   - Gesture cleanup (no stuck timers)

3. **Visual Consistency**:
   - Colors match Swift app across all screens
   - Typography sizes appropriate for each element
   - Monospaced digits align properly
   - Icon sizes proportional to buttons

4. **Responsive Layout**:
   - Test on different screen sizes (phone, tablet)
   - Test on both iOS and Android
   - Portrait and landscape orientations

5. **Map Interactions**:
   - Pan, zoom, rotate gestures smooth
   - Compass overlay tracks rotation correctly
   - Export buttons accessible

### Automated Testing
- Unit tests for ButtonCustomizationSettings model
- Widget tests for CircularActionButton component
- Integration tests for long-press gesture handling
- Golden tests for visual regression (optional)

## Migration Path

### Phase 1: Foundation (Tasks 1-15)
1. Create button customization models and services
2. Add color and typography constants
3. Create reusable button components

### Phase 2: Main Screen (Tasks 16-30)
4. Redesign MainScreen with circular buttons
5. Implement button positioning system
6. Add heading accuracy indicator
7. Polish typography and spacing

### Phase 3: Save Data Screen (Tasks 31-50)
8. Redesign SaveDataScreen layout
9. Implement cyclic parameter editing
10. Add tap vs long-press detection
11. Add visual feedback for parameter changes

### Phase 4: Settings and Customization (Tasks 51-70)
12. Enhance SettingsScreen with sections
13. Add magnetic field debug display
14. Create ButtonCustomizationScreen
15. Integrate customization into app flow

### Phase 5: Map Enhancements (Tasks 71-85)
16. Add compass overlay to map
17. Implement export buttons
18. Enhance gesture handling
19. Polish visual presentation

### Phase 6: Polish and Testing (Tasks 86-100)
20. Visual consistency pass
21. Interaction pattern testing
22. Responsive layout testing
23. Documentation updates

## Risks and Mitigations

### Risk 1: Gesture Conflicts
**Risk**: Simultaneous gestures (pan/zoom/rotate) may conflict in Flutter.  
**Mitigation**: Use `GestureDetector` with proper gesture arena resolution. Test extensively.

### Risk 2: Performance with Positioned Widgets
**Risk**: Many Positioned widgets in Stack may impact performance.  
**Mitigation**: Limit number of buttons (4-6 per screen). Profile with DevTools.

### Risk 3: Platform Differences
**Risk**: iOS and Android may render buttons differently.  
**Mitigation**: Use platform-agnostic Material widgets. Test on both platforms early.

### Risk 4: Custom Positioning Usability
**Risk**: Users may position buttons off-screen or overlapping.  
**Mitigation**: Add constraints to position sliders. Show preview before applying.

## Success Criteria

1. **Visual Similarity**: Flutter app has similar look and feel to Swift app (subjective assessment)
2. **Feature Parity**: All Swift UI features implemented in Flutter
3. **Usability**: Users can perform underwater surveys with customized button layouts
4. **Performance**: UI remains responsive during real-time sensor updates (60 FPS)
5. **Cross-Platform**: Works well on both iOS and Android devices

## Open Questions

1. Should we implement the AR/3D VisualMapper view, or defer to future enhancement?
   - **Decision**: Defer to future. Focus on core 2D survey UI first.

2. Should button customization allow rotation/angle adjustments?
   - **Decision**: No, keep it simple with size and x/y offsets only.

3. Should we support different button customization profiles (e.g., "Left-handed", "Right-handed")?
   - **Decision**: No, single customizable layout per screen context.

4. Should the camera button be functional or just a placeholder?
   - **Decision**: Placeholder for now. Camera integration is a separate feature.

5. Should we replicate the double-tap-to-exit gesture (CoreMotion) from Swift app?
   - **Decision**: No, use standard back button navigation. Double-tap is iOS-specific pattern.

## References

- Swift ContentView: `archive/swift-ios-app/cave-mapper/ContentView.swift`
- Swift SaveDataView: `archive/swift-ios-app/cave-mapper/SaveDataView.swift`
- Swift ButtonCustomization: `archive/swift-ios-app/cave-mapper/ButtonCustomizationSettings.swift`
- Swift SettingsView: `archive/swift-ios-app/cave-mapper/SettingsView.swift`
- Swift NorthOrientedMapView: `archive/swift-ios-app/cave-mapper/NorthOrientedMapView.swift`
- Button Customization README: `archive/swift-ios-app/cave-mapper/BUTTON_CUSTOMIZATION_README.md`

## Approval

- [x] Proposal reviewed by project maintainer
- [x] Technical approach approved
- [x] Ready to proceed with implementation
