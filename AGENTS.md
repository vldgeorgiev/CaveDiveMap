<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

---

## CaveDiveMap - AI Assistant Instructions

## Project Overview

**CaveDiveMap** is a cross-platform (iOS & Android) cave diving survey application that measures underwater cave passages using:

- **Magnetometer-based distance measurement**: A 3D-printed wheel with a magnet rotates as the diver moves along the guideline
- **Compass heading**: Magnetic heading from device sensors
- **Manual depth control**: Adjustable via waterproof case buttons
- **Data export**: CSV and Therion cave survey formats
- **Live visualization**: 2D map view during dives

### Key Technical Details

- **Platform**: Cross-platform (Flutter 3.38+, Dart 3.10+)
- **Hardware**: iOS/Android phone in waterproof case + 3D-printed measurement wheel device
- **Architecture**: Provider pattern with ChangeNotifier services
- **Storage**: Hive (NoSQL key-value database)
- **Original iOS Version**: Archived in `archive/swift-ios-app/` (App Store ID: 6743342160)

## Project Structure

```text
CaveDiveMap/
├── flutter-app/              # Active Flutter cross-platform app
│   ├── lib/
│   │   ├── models/           # Data models (SurveyData, Settings)
│   │   │   ├── survey_data.dart
│   │   │   └── settings.dart
│   │   ├── services/         # Core services
│   │   │   ├── storage_service.dart      # Hive persistence
│   │   │   ├── magnetometer_service.dart # Distance measurement
│   │   │   ├── compass_service.dart      # Heading tracking
│   │   │   └── export_service.dart       # CSV/Therion export
│   │   └── screens/          # UI screens (to be implemented)
│   ├── pubspec.yaml          # Flutter dependencies
│   └── README.md             # Flutter setup instructions
├── archive/                  # Archived Swift iOS app
│   ├── README.md             # Archive documentation
│   └── swift-ios-app/        # Original iOS implementation
│       ├── cave-mapper/      # Swift source files
│       └── cave-mapper.xcodeproj/
├── tools/                    # Python utilities
│   └── PointCloud2Map.py     # Point cloud analysis
├── openspec/                 # Spec-driven development
│   ├── AGENTS.md             # OpenSpec workflow guide
│   ├── project.md            # Detailed project context
│   ├── specs/                # Capability specifications
│   └── changes/              # Active change proposals
│       └── migrate-to-flutter/  # Flutter migration plan
└── Manual/                   # Screenshots and documentation
```

## Data Model

**SurveyData** (both automatic and manual points):

```dart
class SurveyData {
  final int recordNumber;      // Sequential point ID
  final double distance;       // Cumulative meters from start
  final double heading;        // Magnetic degrees
  final double depth;          // Meters (manually adjusted)
  final double left;           // Passage width left (manual points only)
  final double right;          // Passage width right
  final double up;             // Passage height up
  final double down;           // Passage height down
  final String rtype;          // "auto" or "manual"
}
```

**Original Swift Model** (archived in `archive/swift-ios-app/`):

```swift
struct SavedData: Codable {
    let recordNumber: Int
    let distance: Double
    let heading: Double
    let depth: Double
    let left: Double
    let right: Double
    let up: Double
    let down: Double
    let rtype: String
}
```

## Core Capabilities

### 1. Distance Measurement (Magnetometer-based)

- Wheel with magnet attached to dive case
- Magnetometer detects peaks as wheel rotates
- Distance calculated from wheel circumference
- Automatic point generation each rotation

### 2. Manual Survey Points

- Added at tie-off points or key locations
- Diver inputs passage dimensions (left/right/up/down)
- Cyclic parameter editing interface (tap button to switch parameter)
- Press-and-hold for rapid increment/decrement

### 3. Data Export

- **CSV**: All fields for general use
- **Therion**: Cave survey software format
- Share via iOS share sheet

### 4. Map Visualization

- **Live 2D Map**: Reference during dive
  - Touch gestures: pan, zoom, rotate
  - North-oriented compass overlay
  - Wall profile drawing from manual points
- **AR/3D View**: Future enhancement (original Swift version in archive)

### 5. Button Customization

- Reposition and resize all interface buttons
- Essential for underwater usability with thick waterproof case
- Separate layouts for main screen and save data view
- Persists to local storage

## Development Guidelines

### When Working with Flutter Code

1. **State Management**:
   - Use `Provider` package for state management
   - Services extend `ChangeNotifier` (similar to Swift's `ObservableObject`)
   - Use `Consumer<T>` or `context.watch<T>()` to rebuild on state changes
   - Singleton services via `Provider` at app root

2. **Data Persistence**:
   - Use `Hive` for survey data storage (NoSQL key-value)
   - Type-safe with `TypeAdapter` for `SurveyData` model
   - Lazy loading for efficient handling of large datasets
   - No cloud sync or external storage

3. **Navigation**:
   - Use `Navigator.push()` for simple navigation
   - Named routes for main screens
   - Back button via `Navigator.pop()`

4. **Sensor Usage**:
   - `sensors_plus` package for magnetometer access
   - `flutter_compass` package for heading
   - Stream-based API for real-time sensor data
   - Calibration flow required for accurate heading

### When Working with Archived Swift Code

**Location**: `archive/swift-ios-app/`

1. **State Management**:
   - Use `@State` for local view state
   - Use `@StateObject` for view model initialization
   - Use `@ObservedObject` for shared/passed view models
   - Singletons use `.shared` pattern

2. **Data Persistence**:
   - All persistence goes through `DataManager` static methods
   - UserDefaults for both survey data and settings

3. **Navigation**:
   - `NavigationStack` for view hierarchy
   - Environment `presentationMode` for dismissal
   - Double-tap gesture (via CoreMotion) for quick exit from map views

4. **Sensor Usage**:
   - `CLLocationManager` for compass/magnetometer
   - Calibration flow required for accurate heading
   - Heading accuracy indicator (green <20° error)

### When Adding Features

1. **Check for existing specs**: Run `openspec list --specs` and review `openspec/specs/`
2. **Create proposal if needed**: Use OpenSpec workflow for substantial changes
3. **Follow MVVM pattern**: Separate business logic into view models
4. **Test underwater scenarios**: Consider waterproof case button accessibility

### Code Style

- Dart standard conventions (lowerCamelCase for variables, UpperCamelCase for classes)
- Immutable models with `final` fields
- Descriptive variable names (e.g., `dynamicDistanceInMeters`)
- Commented code for hardware-specific workarounds (e.g., magnetometer drift notes)

## Common Tasks

### Adding New Survey Data Fields

1. Update `SurveyData` model in `flutter-app/lib/models/survey_data.dart`
2. Update Hive `TypeAdapter` for serialization
3. Update CSV export in `ExportService`
4. Update UI in relevant screens (if manual input)
5. Update map visualization if needed
6. Create migration for existing Hive data

### Modifying UI Layout

1. Check if button customization covers the need
2. For new buttons: add to `ButtonCustomizationSettings` service
3. Maintain consistent sizing/positioning patterns
4. Test with various screen sizes (iOS and Android)

### Adjusting Magnetometer Logic

- Logic in `MagnetometerService` (Flutter) or `MagnetometerViewModel` (archived Swift)
- Be careful with wheel circumference calculations
- Test calibration flow after changes
- Consider impact on existing survey data

## Important Constraints

### Hardware

- Requires iPhone with magnetometer
- Waterproof case must allow button presses
- 3D-printed wheel must be properly attached
- Magnet (8mm) must be secure in wheel

### Environmental

- Underwater usage only
- Metallic objects affect magnetometer accuracy
- Limited visibility during dives
- Touch precision reduced in waterproof case

### Platform

- iOS 12.0+ (Flutter app)
- Android 8.0+ (API 26+) (Flutter app)
- CoreLocation permissions required
- ARKit requires compatible devices (archived Swift version)
- No offline maps or cached data

## Useful Commands

```bash
# Flutter project (Active development)
cd flutter-app
flutter pub get              # Install dependencies
flutter run                  # Run on connected device
flutter analyze              # Static analysis
flutter test                 # Run unit tests
flutter build ios            # Build iOS app
flutter build apk            # Build Android APK

# Archived Swift project (Reference only)
cd archive/swift-ios-app
xcodebuild -project cave-mapper.xcodeproj -scheme cave-mapper

# OpenSpec workflow
openspec list                    # List active changes
openspec list --specs            # List all capabilities
openspec show <change-id>        # View change details
openspec validate --strict       # Validate all specs

# Python tools
cd tools
python PointCloud2Map.py         # Analyze point cloud data
```

## Resources

- **App Store**: <https://apps.apple.com/bg/app/cavedivemap/id6743342160>
- **3D Print Files**: <https://www.thingiverse.com/thing:6950056>
- **Project Context**: See `openspec/project.md` for comprehensive technical details
- **OpenSpec Guide**: See `openspec/AGENTS.md` for spec-driven development workflow

## Quick Reference

### File Locations

**Flutter App** (Active):

- Main app: `flutter-app/lib/main.dart`
- Data models: `flutter-app/lib/models/survey_data.dart`
- Storage service: `flutter-app/lib/services/storage_service.dart`
- Magnetometer: `flutter-app/lib/services/magnetometer_service.dart`
- Compass: `flutter-app/lib/services/compass_service.dart`
- Export: `flutter-app/lib/services/export_service.dart`
- Settings: `flutter-app/lib/models/settings.dart`

**Archived Swift App** (Reference):

- Main app: `archive/swift-ios-app/cave-mapper/ContentView.swift`
- Data model: `archive/swift-ios-app/cave-mapper/DataManager.swift`
- Settings: `archive/swift-ios-app/cave-mapper/SettingsView.swift`
- Map view: `archive/swift-ios-app/cave-mapper/NorthOrientedMapView.swift`
- 3D view: `archive/swift-ios-app/cave-mapper/VisualMapper.swift`

### Key Classes

**Flutter** (Active):

- `MagnetometerService`: Sensor data and distance calculations
- `CompassService`: Heading tracking
- `StorageService`: Hive database operations
- `ExportService`: CSV/Therion file generation
- `SurveyData`: Survey point data structure
- `Settings`: App configuration

**Swift** (Archived):

- `MagnetometerViewModel`: Sensor data and distance calculations
- `DataManager`: Data persistence and export
- `ButtonCustomizationSettings`: UI configuration
- `SavedData`: Survey point data structure

### State Files

**Flutter**: Hive database in app documents directory

**Swift** (Archived): UserDefaults keys:

- Survey data: `"savedDataKey"`
- Point counter: `"pointNumberKey"`
- Button settings: `"button_*_size/offsetX/offsetY"`
