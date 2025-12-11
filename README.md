# CaveDiveMap

**Cross-platform mobile app** (iOS & Android) for underwater cave surveying using magnetometer-based distance measurement.

> **Migration Note**: This repository now contains the Flutter cross-platform version. The original Swift iOS app is archived in `archive/swift-ios-app/` and remains available on the [App Store](https://apps.apple.com/bg/app/cavedivemap/id6743342160).

## Overview

CaveDiveMap turns your smartphone into a cave survey tool by combining a simple 3D-printed measurement device with the phone's built-in sensors.

### How It Works

**Concept**:

The app uses the magnetometer to detect the proximity of a magnet embedded in a measurement wheel. The wheel is clamped around the cave diving guideline and rotates as the diver moves the device forward. Each rotation triggers a peak in the magnetic field, and by knowing the wheel's circumference, the app calculates the distance traveled along the line.

**Data Captured**:

- Point number (sequential)
- Compass heading (magnetic degrees)
- Distance (cumulative from start point)
- Depth (manually adjusted via buttons)
- Passage dimensions (left/right/up/down at manual survey stations)

**Survey Types**:

- **Automatic points**: Created each wheel rotation with distance/heading/depth
- **Manual points**: Added by diver at tie-off stations with passage dimensions

**Export Formats**:

- **CSV**: Complete survey data for spreadsheets and analysis
- **Therion**: Cave survey software format for professional mapping
- Share via mobile share options (iOS/Android)

**Live Visualization**:

- 2D map view for reference during the dive
- Touch gestures: pan, zoom, rotate
- North-oriented compass overlay
- Wall profiles rendered from manual point dimensions

## Current Status

- **Flutter Version** (iOS & Android): Active development in `flutter-app/`
- **Swift Version** (iOS only): Archived in `archive/swift-ios-app/`, still available on [App Store](https://apps.apple.com/bg/app/cavedivemap/id6743342160)

## Repository Structure

```text
CaveDiveMap/
├── flutter-app/          # Active cross-platform Flutter app
│   ├── lib/
│   │   ├── models/       # Data models (SurveyData, Settings)
│   │   ├── services/     # Core services (Storage, Magnetometer, Compass, Export)
│   │   └── screens/      # UI screens (Main, SaveData, Settings, Map)
│   └── pubspec.yaml      # Flutter dependencies
├── archive/              # Archived Swift iOS app (reference)
│   └── swift-ios-app/    # Original iOS implementation
├── openspec/             # Spec-driven development documentation
│   ├── project.md        # Technical project context
│   └── AGENTS.md         # AI development workflow guide
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

- `sensors_plus 7.0.0` - Magnetometer access
- `flutter_compass 0.8.1` - Compass heading
- `hive 2.2.3` - Local storage (NoSQL database)
- `provider 6.1.5` - State management
- `share_plus` - Export functionality

### Archived iOS App

See `archive/README.md` for building the original Swift version (reference only).

## Hardware Device

### 3D Printed Measurement Wheel

The app requires a 3D-printed device attached to a smartphone in a waterproof dive case. The device contains the measuring wheel and guideline clamp mechanism.

**Design Goals**:

Fully 3D printable so you can make it anywhere with a 3D printer available. No screws, nuts, springs, or other hardware required.

**Non-Printed Parts**:

- Rubber band (keeps slider gate clamped/tensioned on the cave line)
- Small 8mm diameter magnet (available in hardware stores)

**Resources**:

- **STL Files**: [Thingiverse](https://www.thingiverse.com/thing:6950056)
- **Dive Case** (iPhone 15): [AliExpress Link](https://hz.aliexpress.com/i/1005005277943648.html)

### Screenshots

![Front View](Manual/front.jpg)

Live map view during dive:

![Map View](Manual/map-view.jpg)

## Features

### Magnetometer Distance Measurement

- Peak detection algorithm identifies each wheel rotation
- Configurable wheel circumference for accurate measurements
- Automatic survey point generation

### Manual Survey Stations

- Add points at tie-off locations with passage dimensions
- Cyclic parameter editing (depth → left → right → up → down)
- Press-and-hold for rapid value adjustment

### Data Export

- **CSV format**: All survey fields for analysis
- **Therion format**: Professional cave survey software compatibility
- Cross-platform sharing (iOS share sheet, Android share intent)

### Button Customization

- Reposition and resize all interface buttons
- Essential for underwater usability with thick waterproof cases
- Settings persist across app launches

### Compass Calibration

- User-triggered calibration flow
- Real-time heading accuracy feedback
- Platform-specific calibration UI (iOS/Android)

## Credits

**Original Swift iOS app**: Code entirely written by ChatGPT (2024)

**Flutter migration**: Spec-driven development with AI assistance (2025)

*Developer note: I don't code in Swift or iOS - this project was built entirely through AI collaboration.*

## License

See repository for license details.

## Resources

- **App Store**: <https://apps.apple.com/bg/app/cavedivemap/id6743342160>
- **3D Print Files**: <https://www.thingiverse.com/thing:6950056>
- **Flutter App**: See `flutter-app/README.md` for setup details
- **Technical Docs**: See `openspec/project.md` for architecture details
- **AI Development**: See `AGENTS.md` for AI assistant instructions
