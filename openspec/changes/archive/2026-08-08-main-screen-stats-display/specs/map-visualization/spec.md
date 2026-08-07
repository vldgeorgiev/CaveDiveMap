## ADDED Requirements

### Requirement: Stats Overlay Display Format

The system SHALL display a stats overlay on the map screen showing contextual distance and station information in a compact "value / total" format.

#### Scenario: Stats overlay shows leg and total distance

- **WHEN** the map screen displays survey data with at least one leg
- **THEN** the overlay shows "Distance: <last-leg> / <total> m"
- **AND** `<last-leg>` is the distance of the most recent survey leg
- **AND** `<total>` is the sum of all leg distances
- **AND** both values are formatted to one decimal place

#### Scenario: Stats overlay shows active and total stations

- **WHEN** the map screen displays survey data with at least one station
- **THEN** the overlay shows "Stations: <active> / <total>"
- **AND** `<active>` is the number of the latest (most recently created) station
- **AND** `<total>` is the count of all stations in the survey

#### Scenario: Survey has no legs yet

- **WHEN** the map screen displays survey data with stations but no legs
- **THEN** the distance line shows "Distance: 0.0 / 0.0 m"

#### Scenario: Survey is empty

- **WHEN** the map screen displays an empty survey
- **THEN** the overlay shows "Stations: 0 / 0"
- **AND** the overlay shows "Distance: 0.0 / 0.0 m"

## MODIFIED Requirements

### Requirement: Manual Points Only Display

The system SHALL filter and display only manual survey points (rtype == "manual") in map views, excluding automatic points.

#### Scenario: Survey contains mixed auto and manual points

- **WHEN** map view loads survey data
- **THEN** only points with rtype="manual" are rendered
- **AND** auto points are excluded from visualization

#### Scenario: Survey contains no manual points

- **WHEN** map view loads survey with only auto points
- **THEN** empty state message is displayed
- **AND** message explains that manual points are required for accurate map visualization
