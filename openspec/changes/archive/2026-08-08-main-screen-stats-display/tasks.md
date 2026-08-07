## 1. Update Stats Overlay Widget

- [x] 1.1 In `map_screen.dart` `_buildStatsOverlay()`, replace the "Stations: $stationCount" line with "Stations: <active> / <total>" where active is the latest station number and total is `stations.length`
- [x] 1.2 Replace the "Distance: ${totalDistance.toStringAsFixed(1)} m" line with "Distance: <lastLeg> / <total> m" showing last leg distance and cumulative distance
- [x] 1.3 Remove the "Legs: ${legs.length}" line (now redundant)

## 2. Edge Cases

- [x] 2.1 Handle empty legs list — show "Distance: 0.0 / 0.0 m" when no legs exist
- [x] 2.2 Handle empty stations list — show "Stations: 0 / 0" when no stations exist

## 3. Verification

- [x] 3.1 Verify overlay displays correctly with an active survey containing multiple stations and legs
- [x] 3.2 Verify overlay displays correctly with an empty survey
