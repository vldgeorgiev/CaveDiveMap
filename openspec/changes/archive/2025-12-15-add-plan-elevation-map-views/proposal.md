# Proposal: Add Plan and Elevation Map Views

**Change ID**: `add-plan-elevation-map-views`  
**Type**: Feature Addition  
**Status**: Proposed  
**Created**: 2025-12-11

## Summary

Enhance the map visualization screen with dedicated Plan View and Extended Elevation View modes to provide surveyors with accurate, standardized cave survey visualizations. The feature will display only manual survey points (which have reliable compass data), provide north-oriented plan views with left/right passage dimensions, and elevation views with up/down passage dimensions projected onto a vertical plane.

## Motivation

### Current State Problems

1. **Limited Visualization**: Current map only shows a single 2D perspective without distinguishing vertical from horizontal components
2. **Mixed Data Quality**: Map displays both auto and manual points, but auto points have unreliable compass readings
3. **No Standardized Views**: Cave survey standards require both plan (overhead) and elevation (side profile) views
4. **Passage Data Hidden**: Left/Right and Up/Down dimensions are recorded but not visualized
5. **Poor Initial View**: Map doesn't automatically frame the survey extent on first load

### Benefits of Plan/Elevation Views

1. **Survey Standards Compliance**: Plan and elevation views are standard in professional cave mapping (Therion, Compass, etc.)
2. **Data Accuracy**: Filtering to manual points only ensures reliable compass-based positioning
3. **Passage Visualization**: Displays passage dimensions (LRUD - Left, Right, Up, Down) for better cave structure understanding
4. **Proper Orientation**: Plan view always north-up for easy geographic reference
5. **Better Analysis**: Separate views help surveyors identify vertical shafts, horizontal passages, and navigation routes
6. **Professional Output**: Enables review and quality control before exporting to Therion

### Success Criteria

- [ ] Map screen has view mode toggle (Plan / Elevation)
- [ ] Only manual survey points are displayed in both views
- [ ] Plan view shows left/right perpendicular to heading
- [ ] Elevation view shows up/down vertically, ignoring compass
- [ ] Plan view maintains north-up orientation
- [ ] Both views support pan and zoom gestures
- [ ] Point numbers are displayed at each station
- [ ] Initial view is auto-zoomed to 100% (fit all survey points)
- [ ] Smooth transitions between view modes

## Scope

### In Scope

- View mode selector (toggle or tabs for Plan/Elevation)
- Manual points filter (rtype == "manual")
- Plan view rendering with:
  - North-up orientation (heading determines direction)
  - Left/Right passage width display perpendicular to heading
  - Point labels (record numbers)
- Extended elevation view rendering with:
  - Heading ignored (project onto vertical plane)
  - Up/Down passage height displayed vertically
  - Distance along survey curve on horizontal axis
  - Point labels (record numbers)
- Auto-fit zoom on screen load (100% view shows all points)
- Pan and zoom gestures in both views
- View state persistence across screen changes

### Out of Scope

- Auto points visualization (excluded due to unreliable compass)
- 3D perspective views
- Cross-section editing
- Passage profile drawing tools
- Real-time view switching during active survey
- Export of rendered map images (separate feature)
- Grid overlay with coordinates
- Multiple survey comparison

### Dependencies

- Existing `SurveyData` model with left/right/up/down fields
- Current map screen zoom/pan gesture infrastructure
- Storage service for retrieving manual points

## Technical Approach

### View Mode Implementation

**Plan View Algorithm:**
1. Filter points where `rtype == "manual"`
2. Calculate cumulative XY position using distance and heading
3. Draw survey line connecting sequential points
4. At each point, draw perpendicular line showing left/right passage width
5. Rotate entire view so north is up (compensate for device orientation)
6. Label each point with `recordNumber`

**Extended Elevation View Algorithm:**
1. Filter points where `rtype == "manual"`
2. X-axis: cumulative distance along survey centerline (ignore heading)
3. Y-axis: depth (vertical position)
4. Draw survey line as if unfolded into 2D vertical plane
5. At each point, draw vertical line showing up/down passage height
6. Label each point with `recordNumber`

### Auto-Fit Zoom

```dart
// Calculate bounding box of all manual points
Rect calculateSurveyBounds(List<SurveyData> manualPoints) {
  // Find min/max X, Y in plan view
  // Find min/max distance, depth in elevation view
  // Add padding margin
  return boundingRect;
}

// Set initial scale to fit bounds in viewport
void autoFitView(Size screenSize, Rect surveyBounds) {
  _scale = min(
    screenSize.width / surveyBounds.width,
    screenSize.height / surveyBounds.height
  ) * 0.9; // 90% to leave margin
  _offset = calculateCenterOffset(screenSize, surveyBounds);
}
```

### UI Layout

```
┌─────────────────────────────────────┐
│ AppBar: Cave Map        [Reset] [•••]│
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Plan View] [Elevation View]    │ │ <- View mode tabs
│ └─────────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │    Map Canvas               │   │
│  │    (GestureDetector +       │   │
│  │     CustomPaint)            │   │
│  │                             │   │
│  │    Points with labels       │   │
│  │    Passage width/height     │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Scale: 5m]    Stats    [Compass]  │
└─────────────────────────────────────┘
```

### Data Flow

```dart
class MapScreen extends StatefulWidget {
  MapViewMode _viewMode = MapViewMode.plan;
  
  List<SurveyData> _getManualPoints() {
    return allPoints.where((p) => p.rtype == 'manual').toList();
  }
}

enum MapViewMode { plan, elevation }

class MapPainter extends CustomPainter {
  final List<SurveyData> manualPoints;
  final MapViewMode viewMode;
  
  void paint(Canvas canvas, Size size) {
    if (viewMode == MapViewMode.plan) {
      _drawPlanView(canvas);
    } else {
      _drawElevationView(canvas);
    }
  }
}
```

## Impact

### Affected Components

**Modified:**
- `lib/screens/map_screen.dart` - Add view mode toggle and manual point filtering
- `lib/screens/map_screen.dart` (CaveMapPainter) - Implement plan/elevation rendering logic

**New:**
- None (all changes within existing map screen)

### Affected Specs

- **map-visualization** (MODIFIED) - Add plan and elevation view requirements

### Data Model Changes

- None (uses existing SurveyData fields)

### Breaking Changes

- None (additive feature, backward compatible)

## Migration Plan

No data migration required. Existing surveys will automatically work with new views.

## Testing Strategy

### Unit Tests
- Calculate plan view coordinates from heading/distance
- Calculate elevation view coordinates from distance/depth
- Bounding box calculation for auto-fit
- Manual point filtering logic

### Widget Tests
- View mode toggle switches correctly
- Point labels render at correct positions
- Passage width/height lines display correctly

### Integration Tests
- Load survey with mixed auto/manual points, verify only manual shown
- Verify north-up orientation in plan view
- Zoom/pan gestures work in both view modes
- Auto-fit works for various survey shapes (linear, loop, vertical)

### Manual Testing Scenarios
1. Survey with only manual points (typical use case)
2. Survey with mixed auto/manual points (verify filtering)
3. North-oriented survey (verify correct heading interpretation)
4. Survey with large vertical component (verify elevation view)
5. Single point survey (edge case)
6. Empty survey (no manual points)

## Alternatives Considered

### 1. Include Auto Points with Disclaimer
**Rejected**: Auto points have unreliable compass data (no rotation detection during wheel spin). Including them would create misleading visualizations and reduce trust in the tool.

### 2. Single Combined View with 3D Projection
**Rejected**: Adds complexity without providing the standard plan/elevation format expected by cave surveyors. Also harder to interpret passage dimensions.

### 3. Grid-Based View Instead of True Survey Projection
**Rejected**: Doesn't match real-world surveying needs. Cave surveys use bearing/distance, not grid coordinates.

## Open Questions

- [ ] Should elevation view show depth increasing downward (standard) or upward?
  - **Recommendation**: Downward (depth increases as you go deeper into the cave)
- [ ] Should we add a "Combined" view mode showing both plan and elevation side-by-side?
  - **Recommendation**: Defer to Phase 2, keep initial implementation simple
- [ ] How to handle surveys that loop (close back on themselves)?
  - **Recommendation**: Display as-is; loop closure adjustment is a separate feature

## Timeline Estimate

- View mode toggle UI: 2 hours
- Manual point filtering: 1 hour
- Plan view rendering: 4 hours
- Elevation view rendering: 3 hours
- Auto-fit zoom logic: 2 hours
- Point labels: 2 hours
- Testing: 3 hours
- **Total**: ~17 hours

## References

- Therion cave surveying software: Standard plan/elevation view conventions
- Current map_screen.dart implementation: Existing zoom/pan infrastructure
- SurveyData model: left/right/up/down fields available for visualization
