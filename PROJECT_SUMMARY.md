# CaveDiveMap - Project Summary

## Executive Summary

CaveDiveMap is a specialized iOS application for underwater cave surveying that combines innovative hardware (3D-printed measurement wheel with magnet) and iPhone sensors to measure cave passages. The app is currently published on the App Store and used by cave divers worldwide.

## What It Does

The application measures three key parameters during underwater cave dives:

1. **Distance**: Using magnetometer-based wheel rotation detection
2. **Heading**: Magnetic compass from iPhone sensors
3. **Depth**: Manual adjustment via waterproof case buttons

Data is collected as survey points (both automatic and manual) and can be exported in CSV or Therion format for cave survey software.

## Key Innovation

The core innovation is the magnetometer-based distance measurement system:

- A 3D-printed wheel with an embedded magnet is clamped to the cave diving guideline
- As the diver moves, the wheel rotates along the line
- The iPhone's magnetometer detects peak magnetic field values with each rotation
- Distance is calculated from wheel circumference × rotation count
- Automatic survey points are generated each complete rotation

## Technical Architecture

### Platform

- iOS application written entirely in Swift/SwiftUI
- MVVM architecture pattern
- UserDefaults for local data persistence
- No cloud sync or external dependencies

### Key Components

| Component | Purpose |
|-----------|---------|
| `ContentView` | Main survey screen with live sensor data |
| `SaveDataView` | Manual point entry with passage dimensions |
| `DataManager` | Data persistence and export logic |
| `MagnetometerViewModel` | Sensor data processing and distance calculation |
| `NorthOrientedMapView` | Live 2D map visualization during dive |
| `VisualMapper` | Post-dive AR/3D visualization with RealityKit |
| `ButtonCustomizationSettings` | Underwater UI customization system |

### Data Model

Each survey point contains:

```swift
struct SavedData: Codable {
    let recordNumber: Int      // Sequential point ID
    let distance: Double       // Cumulative meters from start
    let heading: Double        // Magnetic degrees
    let depth: Double          // Meters
    let left: Double           // Passage width left
    let right: Double          // Passage width right
    let up: Double             // Passage height up
    let down: Double           // Passage height down
    let rtype: String          // "auto" or "manual"
}
```

## Hardware Requirements

### Required

- iPhone with magnetometer (most modern iPhones)
- Waterproof diving case with accessible buttons
- 3D-printed measurement wheel device (STL files provided)
- 8mm magnet for wheel
- Rubber band for line clamp tension

### 3D Printing

All hardware components (except magnet and rubber band) are fully 3D printable:

- No screws, nuts, or other hardware needed
- STL files available at: <https://www.thingiverse.com/thing:6950056>
- Designed for easy fabrication anywhere with a 3D printer

## User Workflow

### During the Dive

1. **Setup**: Attach measurement wheel to guideline, calibrate compass
2. **Automatic Data**: App records point with each wheel rotation
3. **Manual Points**: Diver adds points at tie-offs with passage dimensions
   - Cyclic parameter editing (depth → left → right → up → down)
   - Press-and-hold for rapid adjustment
4. **Live Map**: Reference 2D map view shows progress

### After the Dive

1. **Review**: View 3D/AR visualization of surveyed passage
2. **Export**: Share data as CSV or Therion format
3. **Analysis**: Import into cave survey software or custom tools

## Special Features

### Button Customization

Essential for underwater usability:

- Reposition and resize all interface buttons
- Separate layouts for main screen and manual entry view
- Settings persist across app launches
- Accommodates thick waterproof case limitations

### Compass Calibration

- User-triggered calibration flow
- Real-time accuracy indicator (green <20° error, red ≥20°)
- Heading accuracy affects survey quality

### Data Management

- Point numbers auto-increment and persist
- Last depth/distance values carried forward to new manual points
- Reset all data functionality for new surveys
- All data stored locally in UserDefaults

## Export Formats

### CSV Export

Standard comma-separated format with all fields:

```csv
recordNumber,distance,heading,depth,left,right,up,down,rtype
1,0.00,45.23,5.2,0.0,0.0,0.0,0.0,auto
2,1.57,48.71,5.2,0.0,0.0,0.0,0.0,auto
3,3.14,52.19,5.5,2.1,1.8,3.2,0.8,manual
```

### Therion Format

Compatible with Therion cave survey software for professional cave mapping.

## Visualization Tools

### 2D Map View (NorthOrientedMapView)

- Live map during dive for reference
- Touch gestures: pan, zoom, rotate
- North-oriented compass overlay
- Wall profile rendering from manual point dimensions
- Export buttons for quick data sharing

### 3D/AR View (VisualMapper)

- Post-dive visualization using RealityKit/ARKit
- Point cloud rendering
- Spatial understanding of surveyed passage
- Camera feed integration

### Python Analysis Tool

`PointCloud2Map.py` provides advanced analysis:

- Point cloud parsing from PLY files
- Centerline vs. wall point segmentation (yellow vs. other colors)
- Alpha shape algorithms for passage boundary detection
- Multiple view projections (top, side)
- Matplotlib visualization output

## Development Context

### Original Development

Per README credits: "Code entirely written by ChatGPT. I don't code on SWIFT language or IOS."

The project demonstrates successful AI-assisted development of a specialized domain application.

### Current Status

- **Published**: Available on App Store (ID: 6743342160)
- **Active**: Used by cave diving community
- **Hardware Available**: 3D print files publicly shared
- **Maintained**: Ongoing improvements and feature additions

### Constraints

1. **Hardware-Dependent**: Requires physical measurement device
2. **Environment-Specific**: Underwater usage only
3. **Platform-Locked**: iOS only (no cross-platform support)
4. **Sensor-Limited**: Magnetometer accuracy affected by metallic objects
5. **Local-Only**: No cloud sync or backup features

## Future Opportunities

Based on existing code and tools:

1. **Point Cloud Integration**: Full 3D visualization from dive recordings
2. **Wall Contour Detection**: Automatic passage boundary algorithms
3. **Multi-View Analysis**: Comprehensive 3D passage models
4. **Data Backup**: iCloud or export options for survey data
5. **Collaborative Surveys**: Multi-diver data combination
6. **Therion Integration**: Direct export to survey databases

## OpenSpec Integration

The project now includes OpenSpec for spec-driven development:

- **Location**: `openspec/` directory
- **Project Context**: Comprehensive in `openspec/project.md`
- **Agent Instructions**: Full guidelines in `openspec/AGENTS.md` and `/AGENTS.md`
- **No Active Changes**: Clean slate for future development
- **No Existing Specs**: Ready for capability documentation

### For AI Assistants

When working on this project:

1. Review `/AGENTS.md` for project-specific guidelines
2. Check `openspec/project.md` for comprehensive technical context
3. Use OpenSpec workflow for substantial changes or new capabilities
4. Follow Swift/SwiftUI best practices documented in agent instructions
5. Consider underwater usability in all UI/UX decisions

## Key Takeaways

1. **Innovative Measurement**: Magnetometer-based distance measurement is unique and effective
2. **Practical Design**: 3D-printable hardware makes it accessible worldwide
3. **Purpose-Built**: Specialized for cave diving survey with appropriate constraints
4. **Production-Ready**: Published and actively used application
5. **AI-Generated**: Successful example of AI-assisted specialized app development
6. **Well-Documented**: Now includes comprehensive context for future development

## Quick Start for Developers

```bash
# Clone and open in Xcode
cd /Users/vladimir/Projects/CaveDiveMap
open cave-mapper.xcodeproj

# Review project context
cat openspec/project.md

# Check for active development
openspec list
openspec list --specs

# Build and run (requires Xcode)
xcodebuild -project cave-mapper.xcodeproj -scheme cave-mapper
```

## Resources

- **App Store**: <https://apps.apple.com/bg/app/cavedivemap/id6743342160>
- **3D Print Files**: <https://www.thingiverse.com/thing:6950056>
- **Repository**: f0xdude/CaveDiveMap (main branch)
- **Documentation**: See `/AGENTS.md` and `openspec/` directory
