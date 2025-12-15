# Design: Plan and Elevation Map Views

## Context

Cave surveying requires standardized visualization methods to accurately represent three-dimensional cave passages. The industry standard includes two primary views:

1. **Plan View**: Overhead perspective showing horizontal layout
2. **Extended Elevation View**: Side profile showing vertical development

Current CaveDiveMap implementation displays all survey points (auto + manual) in a single rotatable 2D view, which:
- Mixes unreliable auto points (no compass during wheel rotation) with accurate manual points
- Doesn't separate horizontal from vertical components
- Lacks standardized formatting expected by professional cave surveyors
- Doesn't display passage dimension data (LRUD - Left, Right, Up, Down)

## Goals

- Provide industry-standard Plan and Elevation views for survey review
- Display only manual points (reliable compass data)
- Visualize passage dimensions using LRUD data
- Enable proper survey quality control before Therion export
- Maintain existing zoom/pan gesture infrastructure

## Non-Goals

- Real-time switching during active survey (use case is post-survey review)
- 3D perspective rendering
- Cross-section editing tools
- Grid overlays with UTM coordinates
- Image export (separate feature)

## Technical Decisions

### Decision 1: Manual Points Only

**Choice**: Filter to `rtype == "manual"` exclusively

**Rationale**:
- Auto points have unreliable compass readings (magnetometer detects wheel rotation, not device orientation)
- Including auto points would create misleading visualizations
- Manual points are intentionally recorded with accurate compass alignment
- Surveyors expect map to reflect compass-based positioning

**Alternatives Considered**:
- Include auto points with visual distinction (rejected: still misleading)
- Use interpolated heading for auto points (rejected: too error-prone)

### Decision 2: View Mode Toggle vs. Side-by-Side

**Choice**: Single view with toggle button (Plan | Elevation)

**Rationale**:
- Maximizes screen real estate for map detail
- Mobile screen size limits side-by-side effectiveness
- Aligns with existing single-view map architecture
- Simpler implementation and maintenance

**Alternatives Considered**:
- Split screen showing both views simultaneously (rejected: too small on phone)
- Tabs for view selection (rejected: toggle is more discoverable)

### Decision 3: North-Up Plan View (Not Device-Up)

**Choice**: Plan view always displays north at top of screen

**Rationale**:
- Industry standard for cave survey maps
- Enables geographic orientation without rotating device
- Matches Therion, Compass, and other survey software conventions
- Makes sharing and comparing maps easier

**Alternatives Considered**:
- Device orientation-based (rejected: not standard, confusing)
- Optional rotation (rejected: adds complexity, rarely needed)

### Decision 4: Auto-Fit on Load

**Choice**: Calculate bounding box and zoom to fit all manual points on screen load

**Rationale**:
- Immediate context of entire survey
- Eliminates manual zoom/pan to find survey extent
- Standard behavior in mapping applications
- Better UX for reviewing unfamiliar surveys

**Implementation**:
```dart
// Calculate bounding box
Rect _calculateBounds(List<SurveyData> points, MapViewMode mode) {
  if (points.isEmpty) return Rect.zero;
  
  if (mode == MapViewMode.plan) {
    // Calculate XY from heading/distance
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    double x = 0, y = 0;
    for (var point in points) {
      x += point.distance * sin(point.heading * pi / 180);
      y += point.distance * cos(point.heading * pi / 180);
      minX = min(minX, x - point.left);
      maxX = max(maxX, x + point.right);
      minY = min(minY, y);
      maxY = max(maxY, y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  } else {
    // Elevation: distance x depth
    double totalDist = 0;
    double minDepth = double.infinity, maxDepth = -double.infinity;
    
    for (var point in points) {
      totalDist += point.distance;
      minDepth = min(minDepth, point.depth - point.down);
      maxDepth = max(maxDepth, point.depth + point.up);
    }
    return Rect.fromLTRB(0, minDepth, totalDist, maxDepth);
  }
}

void _autoFit(Size screenSize, Rect bounds) {
  final padding = 0.1; // 10% margin
  final scaleX = screenSize.width / (bounds.width * (1 + padding));
  final scaleY = screenSize.height / (bounds.height * (1 + padding));
  _scale = min(scaleX, scaleY);
  _offset = Offset(
    screenSize.width / 2 - bounds.center.dx * _scale,
    screenSize.height / 2 - bounds.center.dy * _scale,
  );
}
```

### Decision 5: Coordinate System

**Plan View**:
- Origin: First manual point (0, 0)
- X-axis: East (positive right)
- Y-axis: North (positive up)
- Heading: 0° = North, 90° = East (compass convention)

**Elevation View**:
- X-axis: Cumulative distance along centerline
- Y-axis: Depth (positive down, following cave convention)
- Origin: First point at (0, depth₀)

**Coordinate Transform**:
```dart
// Plan view: heading/distance → XY
Offset planCoordinate(List<SurveyData> points, int index) {
  double x = 0, y = 0;
  for (int i = 0; i <= index; i++) {
    double heading = points[i].heading * pi / 180;
    x += points[i].distance * sin(heading); // East component
    y += points[i].distance * cos(heading); // North component
  }
  return Offset(x, -y); // Flutter Y increases downward
}

// Elevation view: cumulative distance, depth
Offset elevationCoordinate(List<SurveyData> points, int index) {
  double totalDist = 0;
  for (int i = 0; i <= index; i++) {
    totalDist += points[i].distance;
  }
  return Offset(totalDist, points[index].depth);
}
```

## Risks and Mitigation

### Risk 1: Performance with Large Surveys

**Risk**: Rendering 500+ points with passage dimensions could be slow

**Mitigation**:
- Use Flutter's CustomPainter for efficient canvas rendering
- Implement level-of-detail: hide passage dimensions when zoomed out
- Profile with large test datasets before release
- Consider skipping labels below certain zoom threshold

### Risk 2: Passage Dimension Overlap

**Risk**: Left/right or up/down lines may overlap between nearby points

**Mitigation**:
- Accept overlap as standard cave map behavior (Therion does this)
- Use semi-transparent passage lines
- Future enhancement: add toggle to hide passage dimensions

### Risk 3: Single-Point Edge Case

**Risk**: Auto-fit fails with only one manual point

**Mitigation**:
- Set default scale (e.g., 20px/meter)
- Center on the single point
- Test explicitly in test suite

## Migration Plan

**Phase 1**: Implement core functionality
- View mode toggle
- Manual point filtering
- Plan view rendering
- Elevation view rendering

**Phase 2**: Polish and testing
- Auto-fit zoom
- Point labels
- Passage dimension visualization
- Performance optimization

**Phase 3**: Post-implementation fixes
- Pan gesture rotation compensation
- Grid world-space rendering
- Smart scale bar with round numbers
- Rotation persistence across view switches
- FutureBuilder caching for gesture performance

**Phase 4**: Future enhancements (out of scope)
- Combined split-screen view
- Passage dimension toggle
- Grid overlay with coordinates
- Export rendered map as image

## Open Questions

### Q1: Depth orientation in elevation view?

**Question**: Should depth increase upward or downward?

**Answer**: Downward (standard cave surveying convention - you go deeper into the earth)

### Q2: What if survey has loop closure error?

**Question**: Loops won't close perfectly. Show as-is or adjust?

**Answer**: Show as-is. Loop closure adjustment is a separate feature requiring surveyor input on error distribution method (compass, tape, etc.). Manual adjustment is standard practice in Therion.

### Q3: Handle multi-survey projects?

**Question**: Should we support viewing multiple surveys simultaneously?

**Answer**: Out of scope for this change. Current storage model is single survey per app instance. Multi-survey support is a separate architectural change.

### Q4: How should pan work when map is rotated?

**Question**: Should pan follow screen coordinates or world coordinates when map is rotated?

**Answer**: World coordinates. When the map is rotated, pan gestures should move the map in world space, not screen space. This requires rotating the screen delta by the negative of the current rotation angle before applying to the world offset. Implemented in onScaleUpdate handler.

### Q5: Should rotation persist when switching between plan and elevation views?

**Question**: Reset rotation when switching views or preserve it?

**Answer**: Preserve rotation across view switches. Only reset to north-up (0°) when user explicitly presses the "Fit to Screen" button. This allows surveyors to maintain their preferred orientation while comparing plan and elevation views.

### Q6: How should the background grid behave during pan/zoom?

**Question**: Should the grid be fixed in screen space or move with the map?

**Answer**: Move with the map in world space. The grid is drawn at fixed 5-meter intervals in world coordinates and transforms along with all other map elements. This makes the grid a useful reference for scale and alignment.

## Dependencies

- Existing `SurveyData` model (no changes needed)
- Current `map_screen.dart` gesture infrastructure
- `StorageService.getAllSurveyData()` method
- Flutter canvas rendering (CustomPaint/CustomPainter)
- Dart math library for rotation transformations

## Success Metrics

- All manual tests pass on Android (Samsung SM S911B)
- No performance degradation with 200+ point surveys
- Pan/zoom/rotate gestures work smoothly without flicker
- Grid renders correctly at all zoom levels and rotations
- Scale indicator shows appropriate round numbers
- OpenSpec validation passes
- Code review approval
- Zero crashes in survey visualization

## Implementation Notes

### Coordinate System
- World space: meters (survey data coordinates)
- Screen space: pixels (display coordinates)
- Offset stored in world units, converted via scale factor
- Transform order: translate(center) → scale → rotate → translate(offset)

### Gesture Handling
- Screen delta must be rotated by -rotation angle to get world delta
- Formula: `worldDelta = rotate(screenDelta, -rotation) / scale`
- Rotation compensation critical for correct pan when map is rotated

### Performance Optimizations
- Cache `_surveyFuture` in initState() to prevent FutureBuilder recreation
- Use HitTestBehavior.opaque for reliable gesture detection
- Grid extent calculation optimized for visible area only

