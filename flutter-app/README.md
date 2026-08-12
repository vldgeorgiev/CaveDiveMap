# CaveDiveMap Flutter

Cross-platform cave diving survey application for iOS and Android.

## Overview

CaveDiveMap is a cross-platform rewrite of the iOS-only CaveDiveMap application. It uses magnetometer-based distance measurement to survey underwater cave passages. Supports branching survey topologies with explicit station-to-station legs.

## Features

- **Magnetometer-based Distance Measurement**: 3D-printed wheel with magnet rotates as diver moves along guideline
- **Station & Leg Model**: Manual stations with sequential numbering; directed legs with distance, heading, and LRUD
- **Branching Surveys**: Switch active station on the map to start a new branch from any existing station
- **Active Station Selection**: Long-press a station on the map to set it as the departure point (large touch target for gloved use)
- **Compass Heading**: Magnetic heading from phone sensors (saved per leg)
- **LRUD Passage Dimensions**: Left, Right, Up, Down measurements stored per leg
- **Data Persistence**: Stations and legs automatically saved to SQLite (Drift)
- **Data Export**: CSV (sectioned format) and Therion cave survey formats
- **Data Import**: CSV import with station/leg reconstruction
- **Live Visualization**: 2D map (plan and elevation views) with passage walls
- **Reset Workflow**: Hold to reset with automatic backup export
- **Debug Screen**: Table view of stations and legs for data verification
- **Configurable UI**: Fullscreen mode and keep screen on settings
- **Cross-Platform**: Works on both iOS and Android

## Requirements

- Flutter 3.38+
- Dart 3.10+
- iOS 12.0+ or Android 8.0+ (API 26)
- Device with magnetometer and compass sensors

## Architecture

### Data Model

```
Station     { id, number, depth, timestamp }
SurveyLeg   { id, fromStationId, toStationId, distance, heading, L, R, U, D, timestamp }
AutoPoint   { id, distance, heading, depth, timestamp }  (debug only)
```

Stations are identity + position. Legs are directed edges carrying all measurement data. AutoPoints are debug-only wheel rotation logs.

### Directory Structure

```
lib/
├── models/          # Data models (Station, SurveyLeg, AutoPoint)
├── services/        # Business logic services
│   ├── storage_service.dart       # Data persistence (Drift DB + SharedPreferences)
│   ├── magnetometer_service.dart  # Wheel rotation detection & leg length
│   ├── compass_service.dart       # Heading tracking
│   └── export_service.dart        # CSV/Therion export & import
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

### Survey Workflow

1. **Save first station**: Before measuring, save an initial station (depth + LRUD)
2. **Measure**: Wheel rotates as you swim, accumulating leg distance
3. **Save next station**: Saves a leg (from → to) with distance, heading, and LRUD
4. **Repeat**: Each save creates a new station and leg from the previous one

### Branching (Split Surveys)

To start a new branch from an existing station:

1. **Long-press** a station marker on the map
2. The orange ring moves to that station (now the active departure point)
3. Save a new station — the leg connects from the selected station

**Guards:**
- Cannot switch if leg distance ≥ 1m (save first)
- Sub-meter residual is silently discarded on switch
- Cannot measure before first station is saved

### Resetting Survey Data

To start a new survey:

1. **Hold Reset Button** for 6 seconds
2. System automatically exports current data to CSV before clearing
3. All stations, legs, and auto-points are removed

### Exporting Data

Export files are saved to accessible locations:

- **Android**: `/storage/emulated/0/Documents/CaveDiveMap/`
- **iOS**: `Documents/CaveDiveMap/`

Export formats:
- **CSV**: Sectioned format with `[Stations]` and `[Legs]` headers
- **Therion**: Cave survey format (.th) with from→to legs and LRUD dimensions

### Importing Data

1. Open **Settings** → tap **Import CSV**
2. Select a CSV file in the sectioned format
3. Confirm the count of stations and legs
4. Data is imported with new database IDs; departure set to last station

### Debug Screen

Open **Settings** → **Debug: Survey Data** to view:
- **Stations table**: #, Depth
- **Legs table**: From, To, Distance, Azimuth, L, R, U, D

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
