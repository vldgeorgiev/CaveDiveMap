# CaveDiveMap

**Cross-platform mobile app** (iOS & Android) for underwater cave surveying using magnetometer-based distance measurement.

## Overview

CaveDiveMap turns your smartphone into a cave survey tool by combining a simple 3D-printed measurement device with the phone's built-in sensors.

**Concept**:

The app uses the magnetometer to detect the proximity of a magnet embedded in a measurement wheel. The wheel is clamped around the cave diving guideline and rotates as the diver moves the device forward. Each rotation triggers a peak in the magnetic field, and by knowing the wheel's circumference, the app calculates the distance traveled along the line.

**Warning**:

The application is still in beta. The concept has been tested multiple times with iPhone 15/16, and Samsung S21/S23. It is reliable in general, but see the section **Limitations** below.

## Features

### Magnetometer Distance Measurement

- Peak detection algorithm identifies each wheel rotation
- Configurable wheel circumference for accurate measurements
- Automatic survey point generation
- Automatic calibration of compass
- Real-time heading accuracy indicator
- **Auto-calibration for threshold detection** - guided two-step process to find optimal min/max thresholds

### Manual Survey Stations

- Add points at tie-off locations with passage dimensions
- Cyclic parameter editing (depth → left → right → up → down)
- Press-and-hold for rapid value adjustment

### Live Visualization

- 2D map view for reference during the dive
- Touch gestures: pan, zoom, rotate
- North-oriented compass overlay
- Wall profiles rendered from manual point dimensions

### Data Captured

- Point number (sequential)
- Compass heading (magnetic degrees)
- Distance (cumulative from start point)
- Depth (manually adjusted via buttons)
- Passage dimensions (left/right/up/down at manual survey stations)

### Data Import and Export

- **CSV**: Complete survey data for spreadsheets and analysis
- **Therion**: Popular cave survey software format
- Share via mobile share options (iOS/Android)
- A CSV file can be imported again, in case the survey has to be resumed

### Button Customization

- Reposition and resize all interface buttons
- Essential for underwater usability with thick waterproof cases
- Settings persist across app launches

## Development Setup

### Flutter App

**Requirements**:

- Flutter 3.38+ and Dart 3.10+
- iOS: Xcode 14+ (iOS 12.0+ deployment target)
- Android: Android Studio with SDK 26+ (Android 8.0+)

**Build**:
Install Flutter: https://docs.flutter.dev/get-started/install

```bash
git clone https://github.com/vldgeorgiev/CaveDiveMap.git
cd flutter-app
flutter pub get
flutter run
```

**Key Dependencies**:

- `sensors_plus 7.0.0` - Magnetometer access
- `flutter_compass 0.8.1` - Compass heading
- `drift` - Local storage database
- `provider 6.1.5` - State management
- `share_plus` - Export functionality

### Archived iOS App

See `archive/README.md` for building the original Swift version (reference only).

## Hardware Device

### 3D Printed Measurement Wheel

The app requires a 3D-printed device attached to a smartphone in a waterproof dive case. The device contains the measuring wheel and guideline clamp mechanism.  The magnet should be positioned to pass as close as possible to the phone sensor.

### Threshold Auto-Calibration

The app includes a guided calibration feature to automatically determine optimal magnetic field thresholds for rotation detection:

**How to calibrate**:
1. Go to **Settings** → **Rotation Algorithm** → Select **"Threshold"**
2. Tap **"Calibrate Thresholds"** button
3. Follow the on-screen instructions:
   - **Step 1**: Position the magnet wheel as **far** as possible from your phone, then move the phone in a figure-8 motion for 10 seconds
   - **Step 2**: Position the magnet wheel as **close** as possible to your phone, then move the phone in a figure-8 motion for 10 seconds
4. Review the calculated thresholds and tap **"Apply"**

**Why calibrate?**
- Different phones have varying magnetometer sensitivity
- Magnet strength and positioning affect detection thresholds
- Auto-calibration eliminates trial-and-error threshold tuning
- The algorithm applies percentage-based safety margins (15-25% of range) to account for sensor delay

**Tip**: Re-run calibration if you change the magnet, modify the 3D printed device, or switch to a different phone.

**Design Goals**:

Fully 3D printable so you can make it anywhere with a 3D printer available. No screws, nuts, springs, or other hardware required.

**Non-Printed Parts**:

- Rubber band (keeps slider gate clamped/tensioned on the cave line)
- Small 8mm diameter magnet (available in hardware stores)

**Resources**:

- **STL Files**: [Thingiverse](https://www.thingiverse.com/thing:6950056)
- **Divevolk Seatouch 4 Plus**: The best [case](https://www.divevolkdiving.com/products/divevolk-seatouch-4max-underwater-iphone-diving-housing-iphone-diving-case-compatiable-for-iphone-12-pro-max-13-pro-13-pro-max) for the current application, because it allows full touch access to the screen. 
- **Dive Case** (iPhone 15): [AliExpress Link](https://hz.aliexpress.com/i/1005005277943648.html)

## Limitations and considerations

There are many models of phones and OS, especially with Android. It is not possible to guarantee the application will work with all of them, or if the results will be reliable. Please test your device on land first to make sure it works as expected.

### Location of phone magnetic sensor

The rotating wheel with the magnet must be as close as possible to the sensor. On iPhone 15 and Samsung S21 and S23 the sensor is in the top left corner, but it may differ on other devices.  
Before printing the 3D parts you have to iddentify the location. To do this, install the application and open the main screen, which shows an inddicator bar and the value of the field magnitude. Place a small magnet next to the phone case and start moving it slowly, until you find the location, which read the largest value. This is where the wheel should be.

### Orientation of phone and auto-calibration

The orientation of the phone can influence the magnitude when the magnet and the Earth's field are combined. In some cases the magnitude values can change considerably, which makes finding proper min/max threshold values problematic. In practice it means that the device may detect the rotations in one orientation, but not in another.

**Solution**: Use the built-in auto-calibration feature (Settings → Calibrate Thresholds) to determine optimal thresholds for your specific device and setup. This accounts for phone-specific magnetometer characteristics and magnet positioning.

Some phones automatically try to compensate for local magnetic fields, such as the magnetic wheel in our case. This compensation is useful for the azimuth reading, but can affect the magnitude readings and min/max thresholds. To overcome this, the application tries to use the uncompensated magnetometer values, if they are available.

### Location of the wheel

The wheel has to be located as close as 
- The magnetic field magnitude values can vary depending on the phone orientation. 

## Screenshots

![Front View](Manual/front.jpg)

Live map view during dive:

![Map View](Manual/map-view.jpg)

## Credits

**Original Swift iOS app**: [https://github.com/f0xdude/CaveDiveMap](https://github.com/f0xdude/CaveDiveMap)
> **Migration Note**: This repository now contains the Flutter cross-platform version. The original Swift iOS app is archived in `archive/swift-ios-app/` and is available on the [App Store](https://apps.apple.com/bg/app/cavedivemap/id6743342160).

## License

See repository for license details.

## Resources

- **App Store**: <https://apps.apple.com/bg/app/cavedivemap/id6743342160>
- **3D Print Files**: <https://www.thingiverse.com/thing:6950056>
- **Flutter App**: See `flutter-app/README.md` for setup details
- **Technical Docs**: See `openspec/project.md` for architecture details
