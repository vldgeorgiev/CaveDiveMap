# Archive: Swift iOS App

This directory contains the original Swift/iOS implementation of CaveDiveMap, archived as of December 9, 2025.

## Contents

- **swift-ios-app/**: Complete Swift iOS application source code
  - `cave-mapper/`: Main iOS app source
  - `cave-mapper.xcodeproj/`: Xcode project
  - `cave-mapperTests/`: Unit tests
  - `cave-mapperUITests/`: UI tests
  - `3d_print_stl/`: 3D printer files for measurement wheel

## Status

- **Last Active Version**: App Store ID 6743342160
- **Archived Date**: December 9, 2025
- **Reason**: Replaced by Flutter cross-platform version in `flutter-app/`
- **Maintenance**: No longer actively developed

## Historical Context

This Swift iOS app pioneered magnetometer-based underwater cave survey measurement. Key innovations:

- 3D-printed wheel with magnet for distance measurement
- Waterproof case button customization
- Real-time 2D map visualization during dives
- AR/3D post-dive visualization (VisualMapper)
- CSV and Therion export formats

## Accessing the Code

The Swift code remains available for reference:

- Sensor logic: `swift-ios-app/cave-mapper/MagnetometerViewModel 2.swift`
- Data model: `swift-ios-app/cave-mapper/DataManager.swift`
- Map rendering: `swift-ios-app/cave-mapper/NorthOrientedMapView.swift`
- AR visualization: `swift-ios-app/cave-mapper/VisualMapper.swift`

## Relationship to Flutter App

The Flutter implementation in `flutter-app/` replicates core functionality:

- ✅ Magnetometer distance measurement
- ✅ Compass heading tracking
- ✅ Manual depth adjustment
- ✅ Survey data storage (Hive vs UserDefaults)
- ✅ CSV/Therion export
- ✅ 2D map visualization
- ⏳ AR/3D visualization (future)

## Building the Archived App

Requires:

- macOS with Xcode 14+
- iOS 12.0+ deployment target
- Swift 5.5+

```bash
cd swift-ios-app
open cave-mapper.xcodeproj
# Build and run in Xcode
```

## References

- Original README: See parent directory `README.md`
- Project documentation: `../openspec/project.md`
- Migration plan: `../openspec/changes/migrate-to-flutter/`
