## Why

The map stats overlay currently shows a flat station count and total distance, which doesn't help the diver understand where they are in the survey. Showing leg distance vs total and active station vs total stations gives immediate situational awareness during a dive.

## What Changes

- Replace "Distance: X.X m" with "Distance: <leg> / <total> m" showing the current (last) leg distance alongside cumulative distance
- Replace "Stations: N" with "Stations: <active> / <total>" showing the active (selected/latest) station number alongside total station count
- Remove the separate "Legs: N" line (redundant once station context is visible)

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `map-visualization`: Stats overlay requirements change — display format for distance and station count is updated to show contextual leg/total and active/total values.

## Impact

- `flutter-app/lib/screens/map_screen.dart` — `_buildStatsOverlay()` widget
- No API, dependency, or data-model changes required; all needed data is already available from `stations` and `legs` lists passed into the overlay.
