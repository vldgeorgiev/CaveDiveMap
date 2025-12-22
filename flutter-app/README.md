# CaveDiveMap Flutter

Cross-platform cave diving survey application for iOS and Android.

## Overview

CaveDiveMap is a cross-platform rewrite of the iOS-only CaveDiveMap application. It uses magnetometer-based distance measurement to survey underwater cave passages.

## Features

- **Magnetometer-based Distance Measurement**: 3D-printed wheel with magnet rotates as diver moves along guideline
- **Automatic Point Collection**: Auto-saves survey points every 10 wheel rotations (2.63m)
- **Compass Heading**: Magnetic heading from phone sensors (saved with auto-points)
- **Manual Depth Control**: Adjustable via waterproof case buttons
- **Data Persistence**: Survey data automatically saved and persists across app restarts
- **Data Export**: CSV and Therion cave survey formats (saved to Documents/CaveDiveMap)
- **Reset Workflow**: 10-second hold to reset with automatic backup export
- **Debug Screen**: Table view of all survey points for data verification
- **Live Visualization**: 2D map view during dives
- **Configurable UI**: Fullscreen mode and keep screen on settings
- **Cross-Platform**: Works on both iOS and Android

## Requirements

- Flutter 3.38+
- Dart 3.10+
- iOS 12.0+ or Android 8.0+ (API 26)
- Device with magnetometer and compass sensors

## Architecture

### Directory Structure

```
lib/
├── models/          # Data models (SurveyData)
├── services/        # Business logic services
│   ├── storage_service.dart       # Data persistence
│   ├── magnetometer_service.dart  # Distance measurement
│   ├── compass_service.dart       # Heading tracking
│   └── export_service.dart        # CSV/Therion export
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

### Tech Stack

- **State Management**: Provider (ChangeNotifier pattern)
- **Storage**: Drift (type-safe SQLite wrapper) + SharedPreferences for settings
- **Sensors**: sensors_plus, flutter_compass
- **Export**: share_plus, path_provider

## Usage

### Data Collection

1. **Auto Points**: System automatically saves survey points every wheel rotation
   - Includes distance, compass heading, and depth
   - Point counter increments automatically
2. **Manual Points**: Navigate to "Save Data" screen to add manual measurements
   - Enter left, right, up, down dimensions
   - Manual points include all auto-point data plus dimensions
3. **Data Persistence**: All survey data is automatically saved and persists across app restarts

### Resetting Survey Data

To start a new survey:

1. **Hold Reset Button**: Press and hold the reset button for **6 seconds**
2. **Automatic Backup**: System automatically exports current data to CSV before clearing
   - Backup saved to: `Documents/CaveDiveMap/backup_YYYY-MM-DD_HH-mm-ss.csv`
   - Export path shown in notification for 3 seconds
3. **Data Cleared**: All survey points are removed after successful backup

**Note**: No confirmation dialog is shown - the several second hold is the safety mechanism.

### Exporting Data

Export files are saved to accessible locations:

- **Android**: `/storage/emulated/0/Documents/CaveDiveMap/`
  - Accessible via Files app or any file manager
  - Requires storage permission on Android 12 and below
- **iOS**: `Documents/CaveDiveMap/`
  - Accessible via Files app

Export formats:
- **CSV**: Standard format with all survey point data
- **Therion**: Cave survey software format (.th files)

After export, the file path is displayed in a notification for 3 seconds.

### Debug Screen

To view all collected survey data:

1. Open **Settings**
2. Tap **Debug: Survey Data** (under Interface section)
3. View table with all survey points:
   - Record #, Distance, Azimuth, Depth
   - Left, Right, Up, Down dimensions
   - Point type (auto/manual)
   - Color-coded rows by type

## Development

### Running Tests

```bash
flutter test
```

### Building for Release

iOS:
```bash
flutter build ios --release
```

Android:
```bash
flutter build apk --release
```

## Contributing

This project follows the OpenSpec development workflow. See `openspec/` directory in the original repository for specifications and change proposals.

## Links

- Original iOS App: https://apps.apple.com/bg/app/cavedivemap/id6743342160
- 3D Print Files: https://www.thingiverse.com/thing:6950056
