## 1. Data Model & Database Schema

- [x] 1.1 Define `Station` model class with fields: id, number, depth, timestamp
- [x] 1.2 Define `SurveyLeg` model class with fields: id, fromStationId, toStationId, distance, heading, left, right, up, down, timestamp
- [x] 1.3 Define `AutoPoint` model class with fields: id, distance, heading, depth, timestamp
- [x] 1.4 Create Drift table definitions: `StationsTable`, `SurveyLegsTable`, `AutoPointsTable`
- [x] 1.5 ~Skipped~ — no migration needed per user decision
- [x] 1.6 ~Skipped~ — no migration needed per user decision

## 2. Storage Service

- [x] 2.1 Add Station CRUD operations to StorageService (insert, getAll, getById, delete, deleteAll)
- [x] 2.2 Add SurveyLeg CRUD operations to StorageService (insert, getAll, getByStationId, delete, deleteAll)
- [x] 2.3 Add AutoPoint CRUD operations to StorageService (insert, getAll, deleteAll)
- [x] 2.4 Add `currentDepartureStationId` to SharedPreferences (get/set/clear)
- [x] 2.5 Replace manual-station counter logic: `pointCounter` now counts only stations
- [x] 2.6 Remove legacy `SurveyData` / `SurveyDataTable` references from StorageService after migration is in place

## 3. Measurement & Save Flow

- [x] 3.1 Update MagnetometerService to create AutoPoint records (no station number, separate table)
- [x] 3.2 Update manual save flow: create Station, then create SurveyLeg (with LRUD) from current departure station to new station
- [x] 3.3 After save, set `currentDepartureStationId` to the newly created station
- [x] 3.4 On app startup, restore `currentDepartureStationId` from SharedPreferences
- [x] 3.5 Block distance measurement when no stations exist yet (show warning on main screen)

## 4. Map Rendering

- [x] 4.1 Update CaveMapPainter to consume `List<Station>` + `List<SurveyLeg>` instead of `List<SurveyData>`
- [x] 4.2 Compute station positions by traversing the leg graph (from→to with heading + distance) instead of iterating a flat list
- [x] 4.3 Draw LRUD passage walls using leg LRUD + leg heading for L/R orientation
- [x] 4.4 Display station numbers from `Station.number` (manual-only, sequential)
- [x] 4.5 Verify plan view and elevation view both work with branching topology

## 5. Data Table Screen

- [x] 5.1 Update SurveyDataDebugScreen to show Station records (number, depth) in the stations table
- [x] 5.2 Show SurveyLeg records with LRUD columns (from, to, distance, heading, L, R, U, D)
- [x] 5.3 Remove auto-point display from main table

## 6. Active Station Selection

- [x] 6.1 Add hit-testing to detect long-press on station markers in CaveMapPainter (large touch area for gloved use)
- [x] 6.2 On long-press hit, set `currentDepartureStationId` to the tapped station and reset `departureDistance`
- [x] 6.3 Highlight the active departure station on the map with orange ring (14px radius, 4px stroke)
- [x] 6.4 Pass `currentDepartureStationId` from StorageService into CaveMapPainter
- [x] 6.5 Block station switch if distance has been measured since last save (show warning)

## 7. Export

- [x] 7.1 Update CSV export to output stations (number, depth) and legs (from, to, dist, heading, LRUD) as separate sections
- [x] 7.2 Update Therion export to use explicit from→to station numbers from SurveyLeg records
- [x] 7.3 Update Therion export to handle branching surveys (junction station appears as from-station in multiple legs)
- [x] 7.4 Update Therion LRUD block to use first connected leg's LRUD per station

## 8. Import

- [x] 8.1 Implement CSV parser for `[Stations]`/`[Legs]` section format in ExportService
- [x] 8.2 Wire import into settings screen with file picker, confirmation dialog, and ID remapping
- [x] 8.3 Set departure station to last imported station after import

## 8. Cleanup & Testing

- [x] 8.1 Remove legacy `SurveyData` model class and `SurveyDataTable` Drift definition
- [x] 8.2 Update existing tests to use new model types
- [x] 8.3 ~Skipped~ — no migration needed per user decision
- [x] 8.4 Add unit tests for branching topology (station with multiple outgoing legs)
- [x] 8.5 Run Drift code generation (`flutter pub run build_runner build`)
