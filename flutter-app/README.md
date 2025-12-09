# CaveDiveMap Flutter

Cross-platform cave diving survey application for iOS and Android.

## Overview

CaveDiveMap is a cross-platform rewrite of the iOS-only CaveDiveMap application. It uses magnetometer-based distance measurement to survey underwater cave passages.

**Original iOS Repository**: [f0xdude/CaveDiveMap](https://github.com/f0xdude/CaveDiveMap)

## Features

- **Magnetometer-based Distance Measurement**: 3D-printed wheel with magnet rotates as diver moves along guideline
- **Compass Heading**: Magnetic heading from phone sensors
- **Manual Depth Control**: Adjustable via waterproof case buttons
- **Data Export**: CSV and Therion cave survey formats
- **Live Visualization**: 2D map view during dives
- **Cross-Platform**: Works on both iOS and Android

## Requirements

- Flutter 3.38+
- Dart 3.10+
- iOS 12.0+ or Android 8.0+ (API 26)
- Device with magnetometer and compass sensors

## Setup

1. Install Flutter: https://docs.flutter.dev/get-started/install

2. Clone repository:
   ```bash
   git clone https://github.com/f0xdude/CaveDiveMap-Flutter.git
   cd cavedivemap_flutter
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run app:
   ```bash
   flutter run
   ```

## Architecture

### Directory Structure

```
lib/
├── models/          # Data models (SurveyData)
├── services/        # Business logic services
│   ├── storage_service.dart       # Hive persistence
│   ├── magnetometer_service.dart  # Distance measurement
│   ├── compass_service.dart       # Heading tracking
│   └── export_service.dart        # CSV/Therion export
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

### Tech Stack

- **State Management**: Provider (ChangeNotifier pattern)
- **Storage**: Hive (NoSQL key-value database)
- **Sensors**: sensors_plus, flutter_compass
- **Export**: share_plus, path_provider

## Data Migration from iOS App

To transfer survey data from the original iOS app:

1. Export data from iOS app (Settings → Export JSON)
2. Transfer JSON file to Android device
3. In Flutter app: Settings → Import from iOS App
4. Select JSON file

## Hardware

Requires custom 3D-printed measurement wheel:
- **STL Files**: https://www.thingiverse.com/thing:6950056
- **Magnet**: 8mm neodymium magnet
- **Attachment**: Clips to waterproof case

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

## License

[Add license information]

## Links

- Original iOS App: https://apps.apple.com/bg/app/cavedivemap/id6743342160
- 3D Print Files: https://www.thingiverse.com/thing:6950056
- Documentation: See AGENTS.md in original repository
