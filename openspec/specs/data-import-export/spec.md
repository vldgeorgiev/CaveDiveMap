# data-import-export Specification

## Purpose

Define requirements for importing and exporting survey data in multiple formats, enabling data portability, backup, sharing, and integration with external cave surveying tools.
## Requirements
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
- **AND** the first line is `encoding  utf-8`
- **AND** centerline contains `walls on` directive
- **AND** centerline uses `units length depth meters`
- **AND** centerline uses `units compass degrees`
- **AND** centerline contains a `date YYYY.MM.DD` line derived from the first station's timestamp
- **AND** centerline data line is `data diving from to length compass fromdepth todepth`
- **AND** each leg row uses the from-station and to-station numbers from the SurveyLeg record
- **AND** leg length is the per-leg distance stored on the SurveyLeg
- **AND** compass is the heading stored on the SurveyLeg
- **AND** fromdepth and todepth are the depth values of the from-station and to-station respectively
- **AND** a second centerline block uses `data dimensions station left right up down` using the first connected leg's LRUD per station
- **AND** file is saved to platform-specific accessible location
- **AND** file name is based on survey name with `.th` extension

#### Scenario: Therion export with branching survey

- **WHEN** survey contains a junction station with multiple outgoing legs
- **THEN** all legs are included in the export with correct from→to references
- **AND** the junction station appears as the from-station in multiple leg rows
- **AND** Therion format correctly represents the branching topology

#### Scenario: Therion export with depth changes

- **WHEN** survey includes depth changes between stations
- **THEN** `fromdepth` equals the depth of the from-station
- **AND** `todepth` equals the depth of the to-station
- **AND** depth values are expressed in meters

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

#### Scenario: Empty CSV file

- **WHEN** user imports CSV with no stations
- **THEN** error message "No stations found in CSV file" is displayed
- **AND** import is cancelled

#### Scenario: User cancels file selection

- **WHEN** user opens import dialog and cancels without selecting file
- **THEN** import is cancelled silently
- **AND** no error is shown

### Requirement: Export File Paths

The system SHALL save exported files to platform-specific accessible locations for easy user access.

#### Scenario: Android export file location

- **WHEN** data is exported on Android device
- **THEN** file is saved to /storage/emulated/0/Documents/CaveDiveMap
- **AND** directory is created if it doesn't exist
- **AND** file is accessible via Files app and file managers

#### Scenario: iOS export file location

- **WHEN** data is exported on iOS device
- **THEN** file is saved to Documents/CaveDiveMap directory
- **AND** directory is created if it doesn't exist
- **AND** file is accessible via Files app

#### Scenario: Export file path displayed

- **WHEN** export completes successfully
- **THEN** snackbar notification shows complete file path
- **AND** notification uses monospace font for readability
- **AND** notification color matches export format (CSV or Therion)

### Requirement: File Naming Convention

The system SHALL generate timestamped file names for exports to prevent overwrites.

#### Scenario: CSV export file naming

- **WHEN** user exports CSV
- **THEN** file name format is: [SurveyName]_YYYY-MM-DD_HH-MM-SS.csv
- **AND** survey name is taken from settings
- **AND** timestamp reflects export time

#### Scenario: Therion export file naming

- **WHEN** user exports Therion format
- **THEN** file name format is: [SurveyName]_YYYY-MM-DD_HH-MM-SS.th
- **AND** survey name matches Therion survey header

### Requirement: Share Functionality

The system SHALL provide native platform share dialogs for exported files.

#### Scenario: User shares CSV file

- **WHEN** exportAndShareCSV method is called
- **THEN** CSV file is created
- **AND** platform share dialog is opened with file attached
- **AND** share subject is "Survey Data: [filename]"
- **AND** user can share via messaging, email, cloud storage, etc.

#### Scenario: User shares Therion file

- **WHEN** exportAndShareTherion method is called
- **THEN** Therion file is created
- **AND** platform share dialog is opened with file attached
- **AND** share subject is "Therion Survey: [surveyname]"

### Requirement: Settings Screen Integration

The system SHALL provide import and export controls in the Settings screen.

#### Scenario: Settings screen export buttons

- **WHEN** user opens Settings screen
- **THEN** Survey Configuration section displays two export buttons side-by-side
- **AND** "Export CSV" button has purple color (actionExportCSV)
- **AND** "Export Therion" button has teal color (actionExportTherion)
- **AND** buttons have file_download and map icons respectively

#### Scenario: Settings screen import button
#### Scenario: Settings screen import button

- **WHEN** user opens Settings screen
- **THEN** "Import CSV" button is displayed below export buttons
- **AND** button spans full width of section
- **AND** button has green color (actionSave)
- **AND** button has file_upload icon
- **WHEN** user taps import button
- **THEN** import CSV workflow is initiated

