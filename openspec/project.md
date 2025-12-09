# Project Context

## Purpose

CaveDiveMap is an iOS application designed for underwater cave surveying. It measures distance, heading, and depth using:

- A magnetometer to detect wheel rotations (magnet-based distance measurement)
- Compass for heading data
- Manual depth adjustments via buttons on waterproof case

The app creates survey data points that can be exported as CSV or Therion format and visualized as a live 2D map during dives.

## Tech Stack

- **Language**: Swift
- **Frameworks**: SwiftUI, RealityKit, ARKit, CoreLocation, CoreMotion
- **Platform**: iOS (iPhone with waterproof case)
- **Hardware**: 3D-printed wheel device with 8mm magnet, rubber band clamp
- **Data Storage**: UserDefaults for persistence
- **Export Formats**: CSV, Therion survey format
- **Python Tools**: PointCloud2Map.py for 3D point cloud analysis

## Project Conventions

### Code Style

- Swift standard conventions
- Use `@State` and `@ObservedObject` for state management
- `@StateObject` for view model initialization
- Singleton pattern for shared settings (e.g., `ButtonCustomizationSettings.shared`)
- Monospaced digits for numeric displays
- SwiftUI declarative UI patterns

### Architecture Patterns

- **MVVM**: View models (e.g., `MagnetometerViewModel`) handle business logic
- **Data Layer**: `DataManager` static class for UserDefaults persistence
- **Settings Management**: Singleton `ButtonCustomizationSettings` with automatic persistence
- **Navigation**: NavigationStack for view hierarchy
- **Modular Views**: Separate views for different screens (ContentView, SaveDataView, SettingsView, etc.)

### File Organization

- Main app code: `cave-mapper/` directory
- Swift source files at root of cave-mapper
- Assets in `Assets.xcassets/`
- 3D assets in `3d assets/` subdirectory
- Python utilities in `tools/` at project root
- 3D print files in `3d_print_stl/`

### Testing Strategy

- UI tests in `cave-mapperUITests/`
- Unit tests in `cave-mapperTests/`
- Real-world testing required due to hardware magnetometer dependency

### Git Workflow

- Main branch: `main`
- Repository owner: f0xdude
- Credits: Code originally written by ChatGPT per README

## Domain Context

### Cave Diving Survey Workflow

1. **Automatic Points**: Generated each wheel rotation (magnet detection)
   - Captures: point number, compass heading, total distance from start, depth
2. **Manual Points**: Added by diver at tie-off points
   - Includes additional measurements: left, right, up, down (passage dimensions)
3. **Live Map View**: Reference during dive (2D top-down projection)
4. **Post-Dive**: Export data via iOS share sheet

### Data Model: SavedData

```swift
struct SavedData: Codable {
    let recordNumber: Int
    let distance: Double      // meters, cumulative
    let heading: Double        // magnetic degrees
    let depth: Double          // meters
    let left: Double           // meters, passage width
    let right: Double          // meters, passage width
    let up: Double             // meters, passage height
    let down: Double           // meters, passage height
    let rtype: String          // "auto" or "manual"
}
```

### Magnetometer-Based Distance Measurement

- Wheel diameter/circumference determines distance per rotation
- App detects peak magnetic field as magnet passes
- Cumulative distance tracking from survey start
- Requires calibration for accurate measurements

### Key Views

- **ContentView**: Main screen with magnetometer data, distance, heading accuracy indicator
- **SaveDataView**: Manual data point entry with cyclic parameter editing (depth, left, right, up, down)
- **NorthOrientedMapView**: 2D cave profile visualization with touch gestures (zoom, pan, rotate)
- **VisualMapper**: AR-based 3D visualization using RealityKit/ARKit
- **SettingsView**: Configuration including button customization
- **ButtonCustomizationView**: UI for repositioning/resizing interface buttons

## Important Constraints

### Hardware Dependencies

- Requires iPhone with magnetometer (CoreLocation heading services)
- Waterproof case must have accessible buttons for depth adjustment
- 3D-printed wheel device must be properly attached
- 8mm magnet must be securely mounted in wheel

### Environmental Limitations

- Underwater usage (waterproof case required)
- Magnetometer accuracy affected by metallic objects
- Heading accuracy indicator (green <20° error, red ≥20° error)
- Compass drift considerations (gravity-only world alignment to avoid systematic drift)

### iOS Platform Requirements

- CoreLocation permissions for compass
- ARKit/RealityKit for 3D visualization
- iOS share sheet for data export
- UserDefaults for data persistence (consider backup implications)

### Data Export Formats

- **CSV**: Standard format with all fields
- **Therion**: Cave survey software format
- Both accessible via iOS share capabilities

## External Dependencies

### Apple Frameworks

- **CoreLocation**: Magnetometer and compass data (CLLocationManager, CLHeading)
- **CoreMotion**: Motion detection (double-tap to exit views)
- **RealityKit/ARKit**: 3D point cloud visualization
- **SwiftUI**: All UI components
- **UIKit**: Color system, activity view controller (share sheet)

### Third-Party Services

- **App Store**: Published as "CaveDiveMap" (ID: 6743342160)
- **Thingiverse**: 3D print files (thing:6950056)

### Python Dependencies (for PointCloud2Map.py)

- numpy
- matplotlib
- shapely
- scipy
- plyfile

## Special Features

### Button Customization System

- Users can reposition and resize all interface buttons
- Settings persist across app launches
- Separate configurations for main screen and save data view
- Essential for underwater usability with waterproof case

### Calibration

- Magnetometer calibration required for accurate heading
- User-triggered calibration flow
- Accuracy feedback via visual indicator

### Data Management

- Point number auto-increments and persists
- Last depth/distance values carried forward to manual points
- Reset all data functionality
- No cloud sync (local UserDefaults only)

## Future Considerations

- Point cloud data integration (PointCloud2Map.py suggests 3D visualization work in progress)
- Wall contour detection from point clouds
- Alpha shape algorithms for passage boundary detection
- Yellow centerline vs. wall point segmentation
- Multiple view projections (top, side)
