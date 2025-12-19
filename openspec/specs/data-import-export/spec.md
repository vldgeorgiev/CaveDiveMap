# data-import-export Specification

## Purpose

Define requirements for importing and exporting survey data in multiple formats, enabling data portability, backup, sharing, and integration with external cave surveying tools.

## Requirements

### Requirement: CSV Export

The system SHALL export survey data to CSV format with all survey point attributes preserved.

#### Scenario: User exports survey data to CSV

- **WHEN** user selects CSV export option
- **THEN** all survey points are exported to a CSV file
- **AND** CSV includes header: recordNumber,distance,heading,depth,left,right,up,down,rtype,timestamp
- **AND** each row contains one survey point with all fields
- **AND** timestamp is formatted as ISO 8601 string
- **AND** file is saved to platform-specific accessible location (Documents/CaveDiveMap)
- **AND** file name includes survey name and timestamp

#### Scenario: Empty survey data

- **WHEN** user attempts to export with no survey data
- **THEN** error message is displayed: "No survey data to export"
- **AND** no file is created

### Requirement: Therion Export

The system SHALL export survey data to Therion format with centerline and passage dimension data.

#### Scenario: User exports survey data to Therion format

- **WHEN** user selects Therion export option
- **THEN** survey data is exported in Therion .th format
- **AND** file includes survey header with survey name
- **AND** centerline section includes from-to legs with length, compass, and clino
- **AND** dimensions section includes station LRUD data for manual points only
- **AND** file is saved to platform-specific accessible location
- **AND** file name is based on survey name with .th extension

#### Scenario: Therion export with depth changes

- **WHEN** survey includes depth changes between points
- **THEN** clino (inclination) is calculated from depth change and horizontal distance
- **AND** clino is expressed in degrees
- **AND** clino is negative for descending passages

### Requirement: CSV Import

The system SHALL import survey data from CSV files with validation and error handling, and SHALL prevent import when existing survey data is present.

#### Scenario: User attempts import with existing data

- **WHEN** user selects import CSV option
- **AND** existing survey data is present in storage
- **THEN** error message is displayed: "Cannot import: existing survey data found. Please reset survey data before importing."
- **AND** import is cancelled
- **AND** file picker is not opened

#### Scenario: User imports valid CSV file with no existing data

- **WHEN** user selects import CSV option
- **AND** no existing survey data is present
- **THEN** file picker dialog is displayed with CSV filter
- **AND** user can select a CSV file from device storage
- **AND** CSV header is validated against expected format
- **AND** each row is parsed and validated for correct data types
- **AND** imported data is saved to storage
- **AND** success message displays number of imported points

#### Scenario: User confirms import

- **WHEN** CSV file is successfully parsed
- **THEN** confirmation dialog shows number of points to import
- **AND** user can cancel or confirm import
- **WHEN** user confirms import
- **THEN** all imported points are saved to storage
- **AND** success notification is displayed

#### Scenario: Invalid CSV format

- **WHEN** user selects CSV file with invalid header
- **THEN** error message is displayed with expected header format
- **AND** import is cancelled

#### Scenario: Invalid CSV data

- **WHEN** CSV contains rows with incorrect number of columns
- **THEN** error message specifies the problematic line number
- **AND** import is cancelled

#### Scenario: Empty CSV file

- **WHEN** user imports CSV with no data rows
- **THEN** error message "No valid data found in CSV file" is displayed
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