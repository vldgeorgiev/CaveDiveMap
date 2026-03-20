## MODIFIED Requirements

### Requirement: Therion Export

The system SHALL export survey data to Therion diving format, skipping auto-collected points and using sequential 0-based station numbers for all exported stations.

#### Scenario: User exports survey data to Therion format

- **WHEN** user selects Therion export option
- **THEN** survey data is exported in Therion .th format
- **AND** the first line is `encoding  utf-8`
- **AND** file includes `survey <name> -title "<name>"` header
- **AND** centerline contains `walls on` directive
- **AND** centerline uses `units length depth meters`
- **AND** centerline uses `units compass degrees`
- **AND** centerline contains a `date YYYY.MM.DD` line derived from the first non-auto point's timestamp
- **AND** centerline includes a comment block identifying the source file and CSV column layout
- **AND** centerline data line is `data diving from to length compass fromdepth todepth`
- **AND** all points with `rtype == 'auto'` are excluded from the exported stations and legs
- **AND** remaining non-auto points are assigned sequential station numbers starting at 0
- **AND** each leg row contains: `<from-index>  <to-index>  <length>  <compass>  <fromdepth>  <todepth>`
- **AND** `fromdepth` and `todepth` are the absolute depth values of the from- and to-stations respectively
- **AND** leg length is the difference of cumulative distances between consecutive non-auto points
- **AND** compass is the heading recorded at the to-station
- **AND** a second centerline block uses `data dimensions station left right up down` listing LRUD values for manual points only, with station numbers matching the 0-based sequential index
- **AND** file is saved to platform-specific accessible location
- **AND** file name is based on survey name with `.th` extension

#### Scenario: Therion export skips auto points

- **WHEN** survey points include a mix of `rtype == 'auto'` and `rtype == 'manual'` records
- **THEN** only manual points appear as exported stations
- **AND** station numbers form a continuous 0-based sequence with no gaps

#### Scenario: Therion export with depth changes

- **WHEN** survey includes depth changes between consecutive non-auto points
- **THEN** `fromdepth` equals the depth of the from-station
- **AND** `todepth` equals the depth of the to-station
- **AND** depth values are expressed in meters

#### Scenario: Empty survey data

- **WHEN** user attempts to export with no survey data
- **THEN** error message is displayed: "No survey data to export"
- **AND** no file is created
