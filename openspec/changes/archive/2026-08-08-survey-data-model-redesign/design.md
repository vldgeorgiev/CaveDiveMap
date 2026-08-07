## Context

The app currently uses a single Drift (SQLite) table `SurveyDataTable` for all data points. See proposal.md for motivation. The current schema stores heading, distance (cumulative), depth, LRUD, and rtype ('manual'|'auto') on every row. The from→to relationship is implicit: consecutive array indices.

Key existing components:
- `SurveyData` model class and Drift table definition in `lib/models/survey_data.dart`
- `StorageService` manages persistence via Drift + SharedPreferences
- `MagnetometerService` creates data points (both manual and auto)
- `CaveMapPainter` renders stations and passage walls using `_getManualPoints()` filter
- `ExportService` generates CSV and Therion output
- `SurveyDataDebugScreen` displays data table

## Goals / Non-Goals

**Goals:**
- Replace single-table model with Station, SurveyLeg, AutoPoint tables
- Enable branching survey topology via explicit from→to legs
- Clean manual-only station numbering (1, 2, 3...)
- Migrate existing data without loss
- Update all consumers (map, table, export, import)

**Non-Goals:**
- Branch selection UI (long-hold to select departure station) — separate change
- Per-departure-direction LRUD — LRUD stays on station per Therion convention
- Multi-survey support within one database — future work
- Auto-point visualization or analytics

## Decisions

### D1: Three Drift tables replace one

**Choice**: Separate `StationsTable`, `SurveyLegsTable`, `AutoPointsTable` in Drift.

**Rationale**: Clean separation of concerns. Stations are identity+location, legs are topology, auto-points are debug data. Drift's code generation handles joins and foreign keys.

**Alternative considered**: Keep one table, add `from_station` column — rejected because auto-points would still pollute the station table and branching queries would be awkward.

### D2: Per-leg distance, not cumulative

**Choice**: `SurveyLegsTable.distance` stores the length of that single leg.

**Rationale**: Cumulative distance is ambiguous in a branching survey (cumulative along which path?). Per-leg is the atomic measurement. Cumulative can be computed by summing along any path.

**Alternative considered**: Store both — rejected as redundant and error-prone on branches.

### D3: Heading on leg, not station

**Choice**: `SurveyLegsTable.heading` stores the compass bearing of travel.

**Rationale**: Heading describes direction between two points, not a location. A junction station has no single heading — it has one per departing leg.

### D4: LRUD on leg

**Choice**: `SurveyLegsTable` carries left, right, up, down columns. Station has no LRUD.

**Rationale**: LRUD is measured when saving a section (arriving at the to-station). Storing it on the leg simplifies the data table (one row has all data for a survey shot: from, to, distance, heading, LRUD). For Therion export (which expects LRUD per station), the first connected leg's LRUD is used. At a junction with multiple departures, each leg carries its own LRUD — no ambiguity about which set belongs to which direction.

### D5: Current departure station in SharedPreferences

**Choice**: Store the active departure station ID in SharedPreferences (key: `currentDepartureStationId`).

**Rationale**: Lightweight, survives app restart, consistent with existing pattern for `pointCounter`. No need for a DB table for a single scalar value.

### D6: Schema migration via Drift's migration API

**Choice**: Use Drift's `MigrationStrategy.onUpgrade` to create new tables and migrate data in a single transaction.

**Rationale**: Drift's migration is transactional and well-tested. Legacy SurveyData rows are converted in-place: manual → Station + legs between consecutive manuals, auto → AutoPoint. The old table is dropped after migration.

**Alternative considered**: Export-reimport — rejected as fragile and loses auto-point data.

### D7: Station number counter separate from DB auto-increment

**Choice**: `StationsTable.id` is Drift auto-increment (internal). `StationsTable.number` is a separate integer managed by the app counter in SharedPreferences.

**Rationale**: Display number must be sequential among manual stations only. DB auto-increment would include gaps if rows are ever deleted. The SharedPreferences counter is the source of truth for the next display number.

## Risks / Trade-offs

- **Migration failure** → Mitigation: Run migration in a transaction; on failure, roll back and keep legacy table. Log the error for debugging.
- **Performance with joins** → Low risk: cave surveys have hundreds of stations, not millions. Drift handles this scale trivially.
- **Breaking existing CSV exports** → Mitigation: Version the CSV format. Import can detect old format by header and offer to convert.
- **Auto-point table grows unbounded** → Acceptable: auto-points are debug data. A future cleanup/purge feature can be added if needed.

## Migration Plan

1. Add new tables (`StationsTable`, `SurveyLegsTable`, `AutoPointsTable`) alongside existing `SurveyDataTable`
2. Increment Drift schema version
3. In `onUpgrade`: query all legacy rows, create Station/Leg/AutoPoint records, drop legacy table
4. Update `StorageService` API to expose Station/Leg/AutoPoint operations
5. Update all consumers (MagnetometerService, CaveMapPainter, ExportService, screens)
6. Test with both fresh install (no migration) and upgrade (migration runs)
