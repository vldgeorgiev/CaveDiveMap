## Purpose

Define the core survey data entities — Station, SurveyLeg, and AutoPoint — and their relationships, enabling linear and branching cave survey topologies with clean manual-only station numbering.

## ADDED Requirements

### Requirement: Station entity

The system SHALL store each manually-created survey station as a Station record with a globally unique sequential display number, depth, and timestamp.

#### Scenario: Station created on manual save

- **WHEN** the diver presses Save and confirms measurements
- **THEN** a Station record is created with the next sequential display number
- **AND** the station stores depth and timestamp
- **AND** LRUD passage dimensions are stored on the associated SurveyLeg

#### Scenario: Station numbering is global and sequential

- **WHEN** multiple stations are created across different branches of a survey
- **THEN** each station receives the next globally sequential number (1, 2, 3, ...)
- **AND** no two stations in the same survey share a display number

### Requirement: SurveyLeg entity

The system SHALL store each survey leg as a directed edge from one station to another, carrying per-leg distance, heading, and LRUD passage dimensions.

#### Scenario: Leg created between consecutive stations

- **WHEN** the diver saves a new station
- **THEN** a SurveyLeg record is created linking the current departure station (from) to the new station (to)
- **AND** the leg stores the distance traveled between the two stations in meters
- **AND** the leg stores the compass heading of travel in degrees
- **AND** the leg stores left, right, up, and down passage dimensions entered by the diver

#### Scenario: Branching survey at a junction

- **WHEN** the diver departs from a previously visited station into a new gallery
- **AND** saves a new station
- **THEN** a SurveyLeg is created with from_station pointing to the junction station
- **AND** the junction station now has multiple outgoing legs
- **AND** each outgoing leg has its own distance and heading

#### Scenario: Per-leg distance

- **WHEN** a leg is created
- **THEN** the distance value represents the length of that single leg in meters
- **AND** cumulative distance along a path is computed by summing leg distances, not stored directly

### Requirement: AutoPoint entity

The system SHALL store automatically collected data points in a separate debug-only table with no visible station number.

#### Scenario: Auto-point recorded during travel

- **WHEN** the wheel rotation sensor triggers an automatic data capture
- **THEN** an AutoPoint record is created with distance, heading, depth, and timestamp
- **AND** the auto-point has no station number and is not shown on the map or in the survey table

#### Scenario: Auto-points are independent of stations

- **WHEN** auto-points are recorded
- **THEN** they do not affect the station numbering sequence
- **AND** they are not included in survey leg topology

### Requirement: Current departure station tracking

The system SHALL track which station is the current departure point for the next survey leg.

#### Scenario: Default departure station after save

- **WHEN** the diver saves a new station
- **THEN** the current departure station is automatically set to the newly created station

#### Scenario: Departure station persists across app restart

- **WHEN** the app is restarted during a survey
- **THEN** the current departure station is restored to its last value

#### Scenario: Diver selects departure station via long-press on map

- **WHEN** the diver long-presses on a station marker on the map
- **THEN** that station becomes the current departure station
- **AND** the selected station is visually highlighted on the map
- **AND** the next manual save will create a leg from the selected station

#### Scenario: Active departure station is visually distinct

- **WHEN** a departure station is set
- **THEN** the map renders that station with a distinct highlight (orange ring, larger touch target for gloved use)
- **AND** other stations retain their normal appearance

#### Scenario: Station switch blocked when unsaved distance exists

- **WHEN** the diver long-presses a station on the map to switch
- **AND** distance has been measured since the last save
- **THEN** the switch is blocked
- **AND** a warning "Save measured section before switching stations" is displayed

### Requirement: Measurement blocked before first station

The system SHALL prevent distance measurement until at least one station has been saved, since legs require a departure station.

#### Scenario: Wheel rotation before first station

- **WHEN** the wheel rotation sensor detects movement
- **AND** no stations have been saved yet
- **THEN** the distance is not accumulated
- **AND** a warning "Save a station before measuring" is displayed on the main screen
