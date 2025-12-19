# Implementation Tasks

## 1. View Mode Infrastructure

- [x] 1.1 Create `MapViewMode` enum (plan, elevation)
- [x] 1.2 Add view mode state to `_MapScreenState`
- [x] 1.3 Create view mode toggle UI (segmented control or tabs)
- [x] 1.4 Persist view mode preference to settings

## 2. Manual Points Filtering

- [x] 2.1 Add `_getManualPoints()` method to filter `rtype == "manual"`
- [x] 2.2 Update FutureBuilder to use filtered points
- [x] 2.3 Add empty state handling when no manual points exist
- [x] 2.4 Update stats overlay to show manual point count

## 3. Plan View Implementation

- [x] 3.1 Implement plan view coordinate calculation (heading + distance → XY)
- [x] 3.2 Add north-up rotation transformation
- [x] 3.3 Draw survey centerline connecting points
- [x] 3.4 Draw left/right passage width perpendicular to heading at each point
- [x] 3.5 Add point number labels at each station
- [x] 3.6 Test with various heading angles (0°, 90°, 180°, 270°)
- [x] 3.7 Fix azimuth usage (use point A heading for A→B leg)

## 4. Elevation View Implementation

- [x] 4.1 Implement elevation view coordinate calculation (distance → X, depth → Y)
- [x] 4.2 Draw survey centerline as unfolded vertical profile
- [x] 4.3 Draw up/down passage height vertically at each point
- [x] 4.4 Add point number labels at each station
- [x] 4.5 Handle depth orientation (increasing downward)
- [x] 4.6 Test with vertical shafts and horizontal passages

## 5. Auto-Fit Zoom

- [x] 5.1 Create `calculateSurveyBounds()` for plan view
- [x] 5.2 Create `calculateSurveyBounds()` for elevation view
- [x] 5.3 Implement `autoFitView()` to set scale and offset
- [x] 5.4 Call auto-fit on initial screen load (first frame)
- [x] 5.5 Add "Fit to Screen" button to toolbar
- [x] 5.6 Handle edge cases (single point, very small surveys)
- [x] 5.7 Reset rotation to 0 on auto-fit

## 6. Point Labels

- [x] 6.1 Create text painter for point numbers
- [x] 6.2 Position labels clearly (offset from point, avoid overlap with lines)
- [x] 6.3 Add label background for readability
- [x] 6.4 Scale label size with zoom level (readable but not overwhelming)
- [x] 6.5 Test label positioning in both view modes

## 7. View-Specific Rendering

- [x] 7.1 Refactor `CaveMapPainter` to accept `MapViewMode` parameter
- [x] 7.2 Implement `_drawPlanView()` method
- [x] 7.3 Implement `_drawElevationView()` method
- [x] 7.4 Share common rendering code (point markers, labels, grid)
- [x] 7.5 Update painter to use manual points only
- [x] 7.6 Remove compass overlay (not needed)
- [x] 7.7 Fix grid rendering to move with map (world space)

## 8. UI/UX Polish

- [x] 8.1 Add smooth animation when switching view modes
- [x] 8.2 Update scale indicator to show appropriate units for each view
- [x] 8.3 Implement smart scale bar with nice round numbers (0.5, 1, 2, 5, 10, etc.)
- [x] 8.4 Show centimeters when scale < 1 meter
- [x] 8.5 Remove compass overlay (not needed for manual points)
- [x] 8.6 Preserve rotation when switching between plan/elevation

## 9. Gesture Handling

- [x] 9.1 Implement pan gesture with rotation compensation
- [x] 9.2 Implement zoom gesture (pinch)
- [x] 9.3 Implement rotation gesture (two-finger twist, plan view only)
- [x] 9.4 Fix pan to work correctly when map is rotated
- [x] 9.5 Cache FutureBuilder to prevent flicker on gesture updates
- [x] 9.6 Use HitTestBehavior.opaque for reliable gesture detection

## 10. Testing

- [x] 10.1 Unit test plan view coordinate calculation
- [x] 10.2 Unit test elevation view coordinate calculation
- [x] 10.3 Unit test bounding box calculation
- [x] 10.4 Unit test manual point filtering
- [x] 10.5 Widget test view mode toggle
- [x] 10.6 Widget test point label rendering
- [x] 10.7 Integration test with sample survey data (linear passage)
- [x] 10.8 Integration test with vertical survey data (pit/shaft)
- [x] 10.9 Integration test with empty/single point surveys
- [x] 10.10 Manual testing on Android device (Samsung SM S911B)
- [x] 10.11 Verify pan/zoom/rotate gestures work smoothly

## 11. Documentation

- [x] 11.1 Add code comments explaining coordinate transformations
- [x] 11.2 Document passage width/height visualization conventions
- [x] 11.3 Document azimuth convention (point A heading for A→B leg)
- [x] 11.4 Document rotation compensation in pan gesture
- [x] 11.5 Document world-space grid rendering

## Validation Checklist

Before marking complete, verify:

- [x] Manual points filter works correctly (no auto points shown)
- [x] Plan view is always north-up regardless of device orientation
- [x] Elevation view correctly projects survey onto vertical plane
- [x] Auto-fit shows entire survey on screen load
- [x] Point numbers are clearly visible
- [x] Zoom and pan work smoothly in both views
- [x] Pan works correctly when map is rotated
- [x] View mode toggle works without losing zoom/pan state
- [x] Rotation persists when switching views (reset only on fit)
- [x] Grid moves with map during pan/zoom
- [x] Scale indicator shows nice round numbers and adapts to zoom
- [x] No crashes with edge cases (empty, single point, all auto points)
- [x] Performance is acceptable with 100+ manual points
- [x] Code passes `flutter analyze` with no warnings
- [x] FutureBuilder doesn't recreate on every setState (cached)

## Post-Implementation Fixes

### Coordinate System & Gestures
- Fixed pan gesture to account for rotation (rotate screen delta by -rotation angle)
- Fixed grid rendering to use world space coordinates (moves with map)
- Cached `_surveyFuture` in initState() to prevent FutureBuilder recreation
- Added HitTestBehavior.opaque to GestureDetector for reliable touch handling

### Scale Indicator
- Replaced fixed 50px scale with smart round-number selection
- Implemented nice numbers: 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000 meters
- Dynamic scale bar width based on zoom level
- Shows centimeters when scale < 1 meter

### Rotation Behavior
- Removed rotation reset from view mode toggle
- Rotation now persists when switching between plan/elevation
- Rotation resets to 0 only when pressing "Fit to Screen" button

### Azimuth Convention
- Fixed plan view to use point i-1 heading for leg from point i-1 to point i
- Ensures surveying convention: azimuth at point A determines vector from A to B

