# Change: Fix Therion Export to Diving Format

## Why

The current Therion export uses `data normal` format with calculated clino (vertical inclination angle), which is wrong for dive surveys. Dive cave surveying tools expect `data diving` format with absolute depth values at each station. Additionally, auto-collected points pollute the exported survey with intermediate GPS/sensor readings that should not appear as survey stations, and station numbering uses raw database IDs instead of a clean sequential index starting at 0.

## What Changes

- Add `encoding  utf-8` declaration at the top of every exported `.th` file
- Switch centerline data type from `data normal from to length compass clino` to `data diving from to length compass fromdepth todepth`
- Add `walls on` directive inside centerline
- Combine units into `units length depth meters` (single line covers both length and depth)
- Add `date` field in centerline, derived from the survey date stored in the first point's timestamp
- Add comment block describing the CSV column origin before the data rows
- **Skip auto points** (`rtype == 'auto'`) — they are intermediate sensor readings, not survey stations
- **Renumber remaining points from 0** — apply a sequential 0-based index to all non-auto points for the exported station names
- Compute leg `fromdepth`/`todepth` directly from the absolute depth field of each non-auto point (no clino calculation needed)
- In the `data dimensions` centerline block, use the same 0-based sequential station index (matching the renumbered centerline stations) — only manual points with LRUD data are listed, as before

## Impact

- Affected specs: `data-import-export`
- Affected code: `flutter-app/lib/services/export_service.dart` (`exportToTherion` method)
- No breaking changes to stored data model or CSV export
