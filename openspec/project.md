# Project Context

## Purpose

CaveDiveMap is a cross-platform (iOS & Android) cave diving survey application designed for underwater cave surveying. It measures distance, heading, and depth using:

- A magnetometer to detect wheel rotations (magnet-based distance measurement)
- Compass for heading data
- Manual depth adjustments via buttons on waterproof case

The app creates survey data points that can be exported as CSV or Therion format and visualized as a live 2D map during dives.

## Tech Stack

- **Language**: Dart 3.10+
- **Framework**: Flutter 3.38+
- **Platforms**: iOS 12.0+, Android 8.0+ (API 26+)
- **State Management**: Provider pattern with ChangeNotifier services
- **Data Storage**: Drift (type-safe SQLite wrapper) + SharedPreferences
- **Hardware**: 3D-printed wheel device with 8mm magnet, rubber band clamp
- **Export Formats**: CSV, Therion survey format
- **Python Tools**: PointCloud2Map.py for 3D point cloud analysis

### Key Flutter Dependencies

- `sensors_plus 7.0.0` - Magnetometer access
- `flutter_compass 0.8.1` - Compass heading
- `drift 2.30.0` + `sqlite3_flutter_libs` - SQLite database
- `shared_preferences 2.5.4` - Simple key-value storage
- `provider 6.1.5` - State management
- `share_plus` - Export functionality
- `path_provider` - File system access

### Migration History

- **Original**: Swift iOS app (2024) - archived in `archive/swift-ios-app/`
- **Current**: Flutter cross-platform app (2025) - active development in `flutter-app/`
- **App Store**: Original iOS version still available (ID: 6743342160)

## Project Conventions

### Code Style

- Dart standard conventions (lowerCamelCase for variables, UpperCamelCase for classes)
- Immutable models with `final` fields
- Descriptive variable names (e.g., `dynamicDistanceInMeters`)
- Commented code for hardware-specific workarounds
- Document complex algorithms (especially magnetometer logic)

### Architecture Patterns

- **Provider Pattern**: Services extend `ChangeNotifier` for reactive state
- **Service Layer**: Separate services for storage, sensors, and export
- **Data Models**: Immutable data classes with Drift table definitions
- **Screen Components**: Separate files for each major screen
- **Widget Composition**: Reusable widgets in `widgets/` directory
- **Navigation**: Simple push/pop navigation with named routes

### File Organization

```
flutter-app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── survey_data.dart   # Survey point model + Drift table
│   │   └── settings.dart      # App settings model
│   ├── services/              # Business logic
│   │   ├── storage_service.dart      # Drift + SharedPreferences persistence
│   │   ├── magnetometer_service.dart # Distance measurement
│   │   ├── compass_service.dart      # Heading tracking
│   │   └── export_service.dart       # CSV/Therion export
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable components
│   └── utils/                 # Helper functions
├── pubspec.yaml               # Dependencies
├── android/                   # Android platform code
└── ios/                       # iOS platform code
```

Additional project directories:
- `archive/swift-ios-app/` - Original iOS implementation (reference)
- `tools/` - Python utilities for data analysis
- `openspec/` - Spec-driven development documentation

### Testing Strategy

- Unit tests for services and models
- Widget tests for UI components
- Integration tests for full workflows
- Real-world testing required due to hardware magnetometer dependency
- Test both iOS and Android platforms

### Git Workflow

- Main branch: `main`
- Credits: Original Swift code by ChatGPT (2024), Flutter migration with AI assistance (2025)

## Domain Context

### Cave Diving Survey Workflow

1. **Automatic Points**: Generated each wheel rotation (magnet detection)
   - Captures: point number, compass heading, total distance from start, depth
2. **Manual Points**: Added by diver at tie-off points
   - Includes additional measurements: left, right, up, down (passage dimensions)
3. **Live Map View**: Reference during dive (2D top-down projection)
4. **Post-Dive**: Export data

### Data Model: SurveyData

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

**Drift Persistence**: Model uses Drift table definitions with type-safe SQL queries and automatic serialization.

**Archived Swift Model** (reference only):

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

### Magnetometer-Based Distance Measurement

- Wheel diameter/circumference determines distance per rotation
- App detects peak magnetic field as magnet passes sensor
- Cumulative distance tracking from survey start
- Logic in `MagnetometerService` (Flutter) or `MagnetometerViewModel` (archived Swift)
- Requires calibration for accurate measurements
- Uses `sensors_plus` package for sensor access (Flutter)

### Key Screens

**Flutter Implementation**:

- **Main Screen**: Live magnetometer data, distance, heading, depth controls
- **Save Data Screen**: Manual point entry with cyclic parameter editing (depth → left → right → up → down)
- **Settings Screen**: Configuration and button customization
  - Keep Screen On: Prevents screen dimming during surveys (default: enabled)
  - Fullscreen Mode: Hides system UI bars for immersive experience (default: enabled)
  - Wheel calibration, sensor thresholds, survey naming
  - Export/import functionality
- **Map View Screen**: 2D cave profile visualization with touch gestures (pan, zoom, rotate)

**Archived Swift Implementation** (reference):

- `ContentView`: Main screen with magnetometer data
- `SaveDataView`: Manual data point entry
- `NorthOrientedMapView`: 2D visualization with touch gestures
- `VisualMapper`: AR-based 3D visualization (RealityKit/ARKit)
- `SettingsView`: Configuration including button customization
- `ButtonCustomizationView`: UI for repositioning/resizing interface buttons

## Important Constraints

### Hardware Dependencies

- Requires smartphone with magnetometer (iOS or Android device)
- Waterproof diving case must have accessible buttons for depth adjustment
- 3D-printed wheel device must be properly attached
- 8mm magnet must be securely mounted in wheel

### Environmental Limitations

- Underwater usage (waterproof case required)
- Magnetometer accuracy affected by metallic objects in cave
- Heading accuracy indicator shows compass reliability
- Limited visibility during dives affects UI interaction

### Platform Requirements

**iOS**:

- iOS 12.0+
- Location permissions for compass/magnetometer
- Share capabilities for data export

**Android**:

- Android 8.0+ (API 26+)
- Sensor permissions for magnetometer/compass
- Storage permissions for data export

**Both Platforms**:

- No cloud sync (local storage only)
- SQLite database (via Drift) for data persistence
- Flutter 3.38+ for building

### Data Export Formats

- **CSV**: Standard format with all fields for general use
- **Therion**: Cave survey software format for professional mapping
- Export via platform share capabilities (share sheet on iOS, share intent on Android)

## External Dependencies

### Flutter Packages

- **sensors_plus**: Magnetometer and accelerometer data
- **flutter_compass**: Compass heading with calibration
- **drift**: Type-safe SQLite database wrapper
- **sqlite3_flutter_libs**: SQLite native libraries
- **shared_preferences**: Simple key-value storage
- **provider**: State management and dependency injection
- **share_plus**: Cross-platform sharing functionality
- **path_provider**: Access to file system directories
- **package_info_plus**: App version information

### Platform Services

- **App Store**: Original iOS version published as "CaveDiveMap" (ID: 6743342160)
- **Google Play**: Future Android release
- **Thingiverse**: 3D print files (thing:6950056)

### Python Dependencies (for PointCloud2Map.py)

- numpy
- matplotlib
- shapely
- scipy
- plyfile

## Special Features

### Button Customization

Essential for underwater usability with thick waterproof cases:

- Reposition and resize all interface buttons
- Separate layouts for different screens
- Settings persist via SharedPreferences
- Accommodates limited touch precision underwater

### Compass Calibration

- User-triggered calibration flow
- Real-time accuracy feedback
- Heading accuracy affects survey quality
- Platform-specific calibration UI (iOS vs Android)

### Data Management

- Point numbers auto-increment and persist
- Last depth/distance values carried forward to new manual points
- Reset functionality for starting new surveys
- All data stored locally in SQLite database (via Drift)
- No cloud sync or backup (intentional design decision)
- Configurable UI preferences (fullscreen mode, screen wake lock)

## Service Architecture

### StorageService (Drift + SharedPreferences)

- Manages survey data persistence in SQLite database
- Type-safe SQL queries via Drift code generation
- SharedPreferences for app settings and button configs
- Reactive updates via ChangeNotifier
- Migration support for schema changes

### MagnetometerService

- Processes magnetometer sensor stream
- Detects peak magnetic field values
- Calculates distance from wheel rotations
- Configurable wheel circumference
- Generates automatic survey points

### CompassService

- Provides real-time heading data
- Handles compass calibration state
- Monitors heading accuracy
- Stream-based API for reactive updates

### ExportService

- Generates CSV format with all survey fields
- Creates Therion-compatible format
- Handles file system operations
- Integrates with platform share capabilities

## Future Considerations

- **3D Visualization**: AR/3D view similar to archived Swift version (RealityKit equivalent in Flutter)
- **Point Cloud Integration**: Full 3D visualization from dive recordings
- **Wall Contour Detection**: Automatic passage boundary algorithms
- **Multi-View Analysis**: Comprehensive 3D passage models
- **Android Platform**: Google Play Store release
- **Data Backup**: Optional cloud sync or export options
- **Collaborative Surveys**: Multi-diver data combination
- **Therion Integration**: Direct export to survey databases

## Development Notes

### Original Development

Per README credits: "Code entirely written by ChatGPT. I don't code on SWIFT language or IOS."

The project demonstrates successful AI-assisted development of a specialized domain application, now migrated from Swift to Flutter for cross-platform support.

### Migration to Flutter (2025)

- Preserves all core functionality from Swift version
- Adds Android platform support
- Modernizes data persistence with Draft
- Uses Provider pattern for cleaner state management
- Maintains underwater usability focus
- Original Swift code archived for reference

### Constraints

1. **Hardware-Dependent**: Requires physical measurement device
2. **Environment-Specific**: Underwater usage only
3. **Sensor-Limited**: Magnetometer accuracy affected by metallic objects
4. **Local-Only**: No cloud sync or backup features (by design)
5. **Manual Depth**: Depth must be manually adjusted (no depth sensor integration)

## Development Workflows

### Common Tasks

#### Adding Survey Data Fields

1. Update `SurveyDataTable` in `flutter-app/lib/models/survey_data.dart`
2. Run `dart run build_runner build` to regenerate Drift code
3. Modify `ExportService` for CSV/Therion export
4. Update relevant UI screens
5. Create data migration if needed
6. Test with existing survey data

#### Modifying UI

1. Check if button customization system covers the need
2. Consider underwater usability (button size, position)
3. Test on both iOS and Android
4. Ensure waterproof case compatibility
5. Maintain consistency with existing patterns

#### Adjusting Sensor Logic

1. Locate logic in `MagnetometerService` or `CompassService`
2. Test calibration flow after changes
3. Verify wheel circumference calculations
4. Consider platform differences (iOS vs Android)
5. Test with real hardware (simulator won't work)

### When to Use OpenSpec

**Create a proposal** for:

- New features or capabilities
- Breaking changes to data model
- Architecture changes
- Sensor algorithm modifications
- Export format changes

**Skip proposal** for:

- Bug fixes (restoring intended behavior)
- UI tweaks and styling
- Documentation updates
- Dependency version bumps (non-breaking)

### Quick Reference

#### File Locations (Active Flutter App)

- Main: `flutter-app/lib/main.dart`
- Models: `flutter-app/lib/models/survey_data.dart`, `settings.dart`
- Services: `flutter-app/lib/services/` (storage, magnetometer, compass, export)
- Screens: `flutter-app/lib/screens/`
- Dependencies: `flutter-app/pubspec.yaml`

#### Archived Swift App (Reference)

- Main app: `archive/swift-ios-app/cave-mapper/ContentView.swift`
- Data model: `archive/swift-ios-app/cave-mapper/DataManager.swift`
- Settings: `archive/swift-ios-app/cave-mapper/SettingsView.swift`
- Map view: `archive/swift-ios-app/cave-mapper/NorthOrientedMapView.swift`
- 3D view: `archive/swift-ios-app/cave-mapper/VisualMapper.swift`

#### Key Commands

```bash
# Flutter development
cd flutter-app
flutter pub get              # Install dependencies
flutter run                  # Run on device/emulator
flutter analyze              # Static analysis
flutter test                 # Run tests
flutter build ios            # Build iOS app
flutter build apk            # Build Android APK

# OpenSpec workflow
openspec list                # List active changes
openspec list --specs        # List capabilities
openspec validate --strict   # Validate specs

# Python tools
cd tools
python PointCloud2Map.py     # Analyze point cloud data
```

## Resources

- **App Store**: <https://apps.apple.com/bg/app/cavedivemap/id6743342160>
- **3D Print Files**: <https://www.thingiverse.com/thing:6950056>
- **Flutter Setup**: See `flutter-app/README.md`
- **Archive Reference**: See `archive/README.md` for Swift version

