# CaveDiveMap

**Cross-platform mobile app** (iOS & Android) for underwater cave surveying using magnetometer-based distance measurement.

> **Note**: This repository now contains the Flutter cross-platform version. The original Swift iOS app is archived in `archive/swift-ios-app/`.

## Overview

## How It Works

**Concept**:
The app uses the magnetometer to detect the proximity of a magnet on a wheel.
The wheel is clamped around the cave diving line and rotates as the diver moves the device forward.
Each rotation the app detects the peak magnetic field value and by knowing the diameter/circumference of the wheel measures the distance traveled along the line.

**Data Captured**:
- Point number
- Compass heading
- Distance (total from the first point)
- Depth (user can adjust via 2 buttons on the dive case)

**Survey Types**:
- **Automatic points**: Created each wheel rotation with distance/heading/depth
- **Manual points**: Added by the diver at each tie-off point with passage dimensions (left/right/up/down)

**Export Formats**:
- CSV (all survey data)
- Therion (cave survey software format)
- Share via mobile share options

**Live Visualization**:
- 2D map view for reference during the dive
- Touch gestures: pan, zoom, rotate
- North-oriented compass overlay
- Wall profiles from manual points

## Current Status

- **Flutter Version** (Cross-platform): Active development in `flutter-app/` - iOS & Android support
- **Swift Version** (iOS only): Archived in `archive/swift-ios-app/` - Available on [App Store](https://apps.apple.com/bg/app/cavedivemap/id6743342160)

## Repository Structure

```text
CaveDiveMap/
├── flutter-app/          # Active Flutter cross-platform app
│   ├── lib/
│   │   ├── models/       # Data models (SurveyData, Settings)
│   │   ├── services/     # Core services (Storage, Magnetometer, Compass, Export)
│   │   └── screens/      # UI screens (Main, SaveData, Settings, Map)
│   └── pubspec.yaml      # Flutter dependencies
├── archive/              # Archived Swift iOS app
│   └── swift-ios-app/    # Original iOS implementation
├── openspec/             # Specification-driven development docs
│   ├── project.md        # Technical project context
│   └── changes/          # Change proposals and specs
├── tools/                # Python utilities (PointCloud2Map.py)
└── Manual/               # Screenshots and documentation
```

## Development Setup

### Flutter App (Current)

**Requirements**:

- Flutter 3.38+ and Dart 3.10+
- iOS: Xcode 14+ (iOS 12.0+ deployment target)
- Android: Android Studio with SDK 26+ (Android 8.0+)

**Install**:

```bash
cd flutter-app
flutter pub get
flutter run
```

**Key Dependencies**:

- `sensors_plus 7.0.0` - Magnetometer/compass access
- `flutter_compass 0.8.1` - Compass heading
- `hive 2.2.3` - Local storage
- `provider 6.1.5` - State management
- `share_plus` - Export functionality

### Archived iOS App

See `archive/README.md` for building the original Swift version.

## Credits

**Original Swift iOS app**: Code entirely written by ChatGPT (2024)
**Flutter migration**: Spec-driven development with AI assistance (2025)

*Developer note: I don't code in Swift or iOS - this project was built entirely through AI collaboration.*

## Hardware Device

**3D Printed Measurement Wheel**:
The app requires a 3D printed device attached to an iPhone dive case. The device contains the measuring wheel and guideline clamp mechanism.

**Design Goals**:

I wanted the device to be fully 3D printable, so you can make it in any place where there is a 3D printer available.
No springs, screws, nuts or other hardware required.

**Non-Printed Parts**:

- Rubber band for keeping the slider gate clamped down/tensioned on the cave line
- Small magnet 8mm in diameter (available in hardware stores)

**Resources**:

- **STL Files**: [Thingiverse](https://www.thingiverse.com/thing:6950056)
- **Dive Case** (iPhone 15): [AliExpress Link](https://hz.aliexpress.com/i/1005005277943648.html)

## Screenshots
![screenshot](Manual/front.jpg)


The example live map view:
![screenshot](Manual/map-view.jpg)
