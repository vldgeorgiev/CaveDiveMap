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

### Requirement: Auto-Fit Initial Zoom

The system SHALL automatically calculate and apply zoom level to fit all manual survey points on screen when map view first loads (100% view).

#### Scenario: Map screen loads with survey data

- **WHEN** map screen is opened
- **THEN** bounding box of all manual points is calculated
- **AND** zoom scale is set to fit entire survey in viewport
- **AND** 10% margin is added around survey bounds
- **AND** map is centered on survey centroid

#### Scenario: User manually zooms then reopens screen

- **WHEN** user has manually zoomed map
- **AND** user navigates away and returns to map screen
- **THEN** auto-fit is reapplied on screen load
- **AND** previous zoom/pan state is reset

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

The system SHALL support pan and zoom gestures in both Plan and Elevation views with smooth responsive feedback.

#### Scenario: User pans map

- **WHEN** user drags finger across map
- **THEN** view offset updates in real-time
- **AND** pan works in both view modes
- **AND** pan state is maintained when switching between view modes

#### Scenario: User zooms map

- **WHEN** user pinches to zoom
- **THEN** scale updates smoothly
- **AND** zoom center is at gesture focal point
- **AND** zoom range is clamped to prevent excessive zoom in/out
- **AND** zoom state is maintained when switching between view modes

