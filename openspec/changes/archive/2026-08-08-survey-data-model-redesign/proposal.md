## Why

The current data model stores survey data as a flat sequential list where manual and automatic points share the same numbering and from→to relationships are implicit (array order). This makes it impossible to represent branching cave surveys (e.g., a junction where 3 galleries diverge from one station), and station numbers shown to the diver include auto-points, making them meaningless for correlating with wet notes.

## What Changes

- **BREAKING**: Replace the single `SurveyDataTable` with a normalized schema: `Station`, `SurveyLeg`, and `AutoPoint` tables
- **BREAKING**: Station numbering becomes manual-only (1, 2, 3...) — auto-points get no visible station number
- **BREAKING**: Auto-points move to a separate debug-only table with no station identity
- Explicit `from_station_id → to_station_id` relationship on survey legs enables branching surveys
- `heading` and `distance` move from station to leg (they describe travel between two points, not a location)
- `distance` changes from cumulative-from-start to per-leg
- LRUD stays on station (consistent with Therion format; renderer uses leg heading to orient L/R)
- CSV and Therion export updated to use the new schema, with Therion naturally supporting branching via its `from to` leg format
- CSV import updated to parse new schema or legacy format

## Capabilities

### New Capabilities
- `survey-data-model`: Core data model defining Station, SurveyLeg, and AutoPoint entities with explicit from→to topology supporting linear and branching cave surveys

### Modified Capabilities
- `data-import-export`: Export and import formats updated to reflect the new schema — Therion export uses explicit from→to legs with branching support; CSV export reflects new column structure; CSV import handles new format

## Impact

- **Database**: Complete schema migration — `SurveyDataTable` replaced by three tables. Existing data requires migration (convert sequential points to stations + legs)
- **Services**: `StorageService`, `MagnetometerService` save flow changes to create Station + Leg instead of a single SurveyData record
- **UI**: Map rendering, data table screen, save dialog all consume new model types
- **Export**: `ExportService` Therion and CSV output updated for new schema
- **Import**: CSV import parses new column layout; legacy format support TBD
