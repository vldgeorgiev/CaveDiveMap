## MODIFIED Requirements

### Requirement: CSV Export

The system SHALL export survey data to CSV format with stations and legs as separate sections.

#### Scenario: User exports survey data to CSV

- **WHEN** user selects CSV export option
- **THEN** stations are exported under `[Stations]` header with columns: number, depth, timestamp
- **AND** legs are exported under `[Legs]` header with columns: fromStation, toStation, distance, heading, left, right, up, down, timestamp
- **AND** file is saved to platform-specific accessible location (Documents/CaveDiveMap)
- **AND** file name includes survey name and timestamp

#### Scenario: Empty survey data

- **WHEN** user attempts to export with no survey data
- **THEN** error message is displayed: "No survey data to export"
- **AND** no file is created

### Requirement: Therion Export

The system SHALL export survey data to Therion diving format using explicit from→to station references from SurveyLeg records, supporting branching surveys.

#### Scenario: User exports survey data to Therion format

- **WHEN** user selects Therion export option
- **THEN** survey data is exported in Therion .th format
- **AND** centerline data line is `data diving from to length compass fromdepth todepth`
- **AND** each leg row uses the from-station and to-station numbers from the SurveyLeg record
- **AND** leg length is the per-leg distance stored on the SurveyLeg
- **AND** compass is the heading stored on the SurveyLeg
- **AND** fromdepth and todepth are the depth values of the from-station and to-station respectively
- **AND** a second centerline block uses `data dimensions station left right up down` using the first connected leg's LRUD per station
- **AND** file is saved to platform-specific accessible location

#### Scenario: Therion export with branching survey

- **WHEN** survey contains a junction station with multiple outgoing legs
- **THEN** all legs are included in the export with correct from→to references
- **AND** the junction station appears as the from-station in multiple leg rows
- **AND** Therion format correctly represents the branching topology

#### Scenario: Empty survey data

- **WHEN** user attempts to export with no survey data
- **THEN** error message is displayed: "No survey data to export"
- **AND** no file is created

### Requirement: CSV Import

The system SHALL import survey data from CSV files in the `[Stations]`/`[Legs]` section format with validation and error handling.

#### Scenario: User attempts import with existing data

- **WHEN** user selects import CSV option
- **AND** existing survey data is present in storage
- **THEN** error message is displayed: "Cannot import: existing survey data found. Please reset survey data before importing."
- **AND** import is cancelled

#### Scenario: User imports valid CSV file

- **WHEN** user selects import CSV option
- **AND** no existing survey data is present
- **THEN** file picker dialog is displayed with CSV filter
- **AND** stations and legs are parsed from the `[Stations]` and `[Legs]` sections
- **AND** confirmation dialog shows count of stations and legs found
- **AND** on confirmation, stations are saved with new database IDs
- **AND** legs are saved with from→to references mapped to the new station IDs
- **AND** departure station is set to the last imported station

#### Scenario: Invalid CSV format

- **WHEN** user selects CSV file with missing sections or invalid rows
- **THEN** error message is displayed describing the issue
- **AND** import is cancelled

#### Scenario: User cancels file selection

- **WHEN** user opens import dialog and cancels without selecting file
- **THEN** import is cancelled silently
