# map-visualization Specification

## Purpose
TBD - created by archiving change add-plan-elevation-map-views. Update Purpose after archive.
## Requirements
### Requirement: View Mode Selection

The system SHALL provide a view mode selector allowing users to switch between Plan View and Extended Elevation View.

#### Scenario: User switches to Plan View

- **WHEN** user selects Plan View mode
- **THEN** map displays overhead perspective with north at top
- **AND** passage left/right dimensions are shown perpendicular to survey heading

#### Scenario: User switches to Elevation View

- **WHEN** user selects Elevation View mode
- **THEN** map displays vertical profile with depth on Y-axis
- **AND** passage up/down dimensions are shown as vertical lines
- **AND** compass heading is ignored (survey projected onto vertical plane)

### Requirement: Manual Points Only Display

The system SHALL filter and display only manual survey points (rtype == "manual") in map views, excluding automatic points.

#### Scenario: Survey contains mixed auto and manual points

- **WHEN** map view loads survey data
- **THEN** only points with rtype="manual" are rendered
- **AND** auto points are excluded from visualization
- **AND** stats show count of manual points displayed

#### Scenario: Survey contains no manual points

- **WHEN** map view loads survey with only auto points
- **THEN** empty state message is displayed
- **AND** message explains that manual points are required for accurate map visualization

### Requirement: Plan View North-Up Orientation

The system SHALL render Plan View with north oriented to the top of the screen regardless of device orientation.

#### Scenario: Plan view displays survey with various headings

- **WHEN** Plan View is active
- **THEN** north direction is always at top of screen
- **AND** survey line rotates based on heading values
- **AND** compass overlay shows current device heading relative to north

### Requirement: Plan View Passage Dimensions

The system SHALL display left and right passage dimensions perpendicular to the survey heading at each manual point in Plan View.

#### Scenario: Manual point has left/right passage data

- **WHEN** manual point has non-zero left or right values
- **THEN** perpendicular line is drawn from centerline
- **AND** line extends left distance to the left of heading direction
- **AND** line extends right distance to the right of heading direction
- **AND** passage width visualization scales with zoom level

### Requirement: Elevation View Projection

The system SHALL render Extended Elevation View by projecting survey points onto a vertical plane, ignoring compass heading.

#### Scenario: Elevation view displays vertical survey

- **WHEN** Elevation View is active
- **THEN** X-axis represents cumulative distance along centerline
- **AND** Y-axis represents depth (vertical position)
- **AND** survey line shows vertical profile as if cave were unfolded into 2D plane

### Requirement: Elevation View Passage Dimensions

The system SHALL display up and down passage dimensions as vertical lines at each manual point in Elevation View.

#### Scenario: Manual point has up/down passage data

- **WHEN** manual point has non-zero up or down values
- **THEN** vertical line is drawn from centerline
- **AND** line extends up distance above centerline
- **AND** line extends down distance below centerline
- **AND** passage height visualization scales with zoom level

### Requirement: Point Number Labels

The system SHALL display record numbers at each manual survey point in both Plan and Elevation views.

#### Scenario: Point labels are rendered

- **WHEN** map displays manual points
- **THEN** each point shows its recordNumber as a text label
- **AND** label has contrasting background for readability
- **AND** label position avoids overlapping with survey lines
- **AND** label size scales appropriately with zoom level

#### Scenario: Zoomed out view with many points

- **WHEN** zoom level is very low (many points visible)
- **THEN** labels remain readable but do not clutter view
- **AND** label rendering is optimized for performance

### Requirement: Pan and Zoom Gestures

The system SHALL support pan and zoom gestures with independent state for Plan and Elevation views, providing smooth responsive feedback.

#### Scenario: User pans map

- **WHEN** user drags finger across map
- **THEN** view offset updates in real-time for current view mode
- **AND** pan works in both view modes
- **AND** pan state is independent between Plan and Elevation views

#### Scenario: User zooms map

- **WHEN** user pinches to zoom
- **THEN** scale updates smoothly for current view mode
- **AND** zoom center is at gesture focal point
- **AND** zoom range is clamped between 1.0 and 100.0 pixels per meter (minimum ~1m to maximum ~50m visible area)
- **AND** zoom state is independent between Plan and Elevation views

#### Scenario: User switches between view modes

- **WHEN** user switches from Plan to Elevation view or vice versa
- **THEN** each view maintains its own zoom level
- **AND** each view maintains its own pan offset
- **AND** auto-fit is applied once on first load for each view mode

#### Scenario: User rotates map in Plan view

- **WHEN** user performs two-finger twist gesture in Plan view
- **THEN** map rotates around center point
- **AND** rotation is only available in Plan view (not Elevation)
- **AND** rotation state is maintained when switching away and back to Plan view

### Requirement: Visual Grid Display

The system SHALL display a reference grid with adaptive spacing that remains visible at all zoom levels.

#### Scenario: Grid displays at medium zoom

- **WHEN** zoom scale is 10 pixels/meter or higher (zoomed in)
- **THEN** grid spacing is 1 meter
- **AND** grid lines are visible across entire viewport

#### Scenario: Grid displays at low zoom

- **WHEN** zoom scale is less than 10 pixels/meter (zoomed out)
- **THEN** grid spacing is 10 meters
- **AND** grid lines are visible across entire viewport

#### Scenario: User pans to different area

- **WHEN** user pans map to show different survey area
- **THEN** grid extends to cover visible area
- **AND** grid remains aligned to world coordinates
- **AND** grid does not disappear at viewport edges

### Requirement: North Arrow Indicator

The system SHALL display a north arrow indicator in Plan view that rotates to match map orientation.

#### Scenario: North arrow displays in Plan view

- **WHEN** Plan view is active
- **THEN** north arrow is visible in top-right corner
- **AND** arrow points to true north
- **AND** arrow rotates with map when user rotates view

#### Scenario: North arrow hidden in Elevation view

- **WHEN** Elevation view is active
- **THEN** north arrow is not displayed
- **AND** indicator space is available for other UI elements

### Requirement: Auto-Fit Initial Zoom

The system SHALL automatically calculate and apply zoom level to fit all manual survey points on screen when each view mode is first loaded.

#### Scenario: Map screen loads Plan view with survey data

- **WHEN** map screen is opened and Plan view loads for first time
- **THEN** bounding box of all manual points is calculated for Plan projection
- **AND** zoom scale is set to fit entire survey in viewport
- **AND** 20% margin is added around survey bounds (10% each side)
- **AND** map is centered on survey centroid
- **AND** rotation is reset to zero (north-up)

#### Scenario: User switches to Elevation view for first time

- **WHEN** user switches to Elevation view for first time in session
- **THEN** bounding box of all manual points is calculated for Elevation projection
- **AND** zoom scale is set to fit entire survey in viewport
- **AND** 20% margin is added around survey bounds
- **AND** map is centered on survey centroid

#### Scenario: User manually adjusts then switches views

- **WHEN** user has manually zoomed/panned in one view mode
- **AND** user switches to other view mode and back
- **THEN** previous zoom/pan state is preserved for each view
- **AND** auto-fit is not reapplied after initial load

