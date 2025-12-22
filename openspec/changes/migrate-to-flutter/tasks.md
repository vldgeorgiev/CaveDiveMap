# Implementation Tasks: Migrate to Flutter

**Change ID**: `migrate-to-flutter`  
**Repository**: New repository `CaveDiveMap-Flutter` (separate from current repo)

## Phase 0: Repository Setup (0.5 weeks)

### New Repository Creation

- [x] ~~Create new GitHub repository: `CaveDiveMap-Flutter`~~ (Using main repo with flutter-app folder instead)
- [x] Initialize with README explaining it's the Flutter rewrite
- [x] Add LICENSE (match original repo)
- [ ] Set up branch protection rules (main branch)
- [ ] Add collaborators from original project
- [x] Create initial commit with empty Flutter project structure

### Documentation

- [x] Copy relevant documentation from Swift repo to Flutter repo
- [x] Update README with Flutter-specific setup instructions
- [x] Document repository relationship (link to original iOS repo)
- [x] Add archive/README.md explaining historical context
- [x] Update AGENTS.md with Flutter architecture

## Phase 1: Foundation & Core Services (2-3 weeks)

### Project Setup

- [x] Initialize Flutter project with `flutter create cavedivemapf` (Flutter 3.38+)
- [x] Configure iOS deployment target (iOS 12.0+)
- [x] Configure Android minimum SDK (API 26 / Android 8.0+)
- [x] Set up project structure (lib/models, lib/services, lib/screens, lib/widgets)
- [x] Add dependencies to pubspec.yaml (sensors_plus 7.0.0, flutter_compass 0.8.1, Draft, provider 6.1.5, share_plus)
- [ ] Configure app icons and splash screens for both platforms
- [x] Set up code signing for iOS (new bundle ID: com.cavedivemap.flutter, different from Swift app's CaveDiveMap)
- [x] Configure Android build.gradle with unique application ID (com.cavedivemap.flutter)
- [ ] Update app name to distinguish from Swift version during transition (e.g., "CaveDiveMap 2.0" or "CaveDiveMap Flutter")

### Data Models
- [x] Create `SurveyData` model matching Swift SavedData struct
- [x] Add Draft TypeAdapter for SurveyData serialization
- [x] Create `Settings` model for app configuration
- [ ] Create `ButtonSettings` model for UI customization
- [ ] Add Draft TypeAdapter for ButtonSettings
- [ ] Write unit tests for model serialization/deserialization

### Storage Service
- [x] Implement `StorageService` class
- [x] Initialize Draft and open boxes
- [x] Implement `saveSurveyPoint(SurveyData)` method
- [x] Implement `getAllSurveyData()` method
- [x] Implement point counter tracking methods
- [x] Implement `clearAllData()` method
- [x] Implement settings persistence (loadSettings/saveSettings)
- [ ] Implement button settings persistence methods
- [ ] Write unit tests for all storage operations

### Magnetometer Service
- [x] Create `MagnetometerService` class extending ChangeNotifier
- [x] Implement sensor stream subscription using sensors_plus
- [x] Port peak detection algorithm from Swift MagnetometerViewModel
- [x] Implement threshold management
- [x] Implement wheel circumference configuration
- [x] Add magnetic field strength tracking
- [x] Implement distance calculation logic
- [x] Add revolution counter
- [x] Implement start/stop monitoring methods
- [x] Add depth adjustment methods
- [ ] Write unit tests for peak detection algorithm
- [ ] Benchmark sensor performance on test devices

### Compass Service
- [x] Create `CompassService` class extending ChangeNotifier
- [x] Implement compass stream subscription using flutter_compass
- [x] Track current heading and accuracy
- [x] Implement calibration status tracking
- [x] Add accuracy indicator logic (<20° = good)
- [x] Implement start/stop listening methods
- [x] Handle permission requests (via flutter_compass)
- [ ] Write unit tests for compass service
- [ ] Test heading accuracy on physical devices

### Export Service
- [x] Create `ExportService` class
- [x] Implement `exportToCSV(List<SurveyData>)` method
- [x] Implement `exportToTherion(List<SurveyData>)` method
- [x] CSV format matches Swift implementation
- [x] Therion format matches Swift implementation
- [x] Add file writing functionality using path_provider
- [x] Integrate share_plus for share sheet functionality
- [ ] Write tests comparing output to Swift version

## Phase 2: User Interface & Data Entry (2 weeks)

### Main Screen
- [x] Create `MainScreen` widget (ContentView equivalent)
- [x] Add Provider consumers for MagnetometerService and CompassService
- [x] Implement heading display with accuracy indicator
- [x] Implement distance display
- [x] Implement magnetic field strength indicator
- [x] Add settings navigation button
- [x] Add control buttons (Save Manual Point, View Map, Reset Survey)
- [x] Implement reset confirmation dialog
- [x] Add depth adjustment buttons (+/-)
- [x] Implement point number display
- [ ] Add calibration toast notifications
- [ ] Handle automatic point saving on revolution count change
- [ ] Test on both iOS and Android

### Save Data Screen
- [x] Create `SaveDataScreen` widget (SaveDataView equivalent)
- [x] Display current point number, distance, heading, depth
- [x] Implement cyclic parameter selection (left, right, up, down)
- [x] Create increment/decrement buttons
- [x] Implement parameter adjustment logic
- [x] Add cycle parameter button (tap to switch)
- [x] Add save button with data validation
- [x] Display all dimensions in grid view
- [ ] Implement hold-to-repeat functionality (0.5s threshold)
- [ ] Add customizable button positioning
- [ ] Test tap vs hold gesture recognition
- [ ] Test on both platforms with different screen sizes

### Button Customization System
- [ ] Create `ButtonCustomizationSettings` class (singleton or service)
- [ ] Implement position and size properties for all buttons
- [ ] Add persistence to Draft/SharedPreferences
- [ ] Create `CustomizableButton` widget
- [ ] Implement drag-to-reposition functionality
- [ ] Implement pinch-to-resize functionality (or sliders)
- [ ] Create `ButtonCustomizationScreen` for editing
- [ ] Add screen selector (Main Screen vs Save Data Screen)
- [ ] Add button selector (which button to customize)
- [ ] Add reset to defaults functionality
- [ ] Test underwater simulation (large finger taps)

### Settings Screen
- [x] Create `SettingsScreen` widget
- [x] Add survey name configuration
- [x] Add wheel circumference input
- [x] Add peak threshold configuration
- [x] Add CSV export button
- [x] Add Therion export button
- [x] Add about dialog with app information
- [x] Add GitHub link
- [x] Implement settings persistence
- [ ] Add magnetometer axis selection
- [ ] Add calibration section with guided flow
- [ ] Implement guided calibration timer (figure-eight motion)
- [ ] Add button customization navigation
- [ ] Test settings persistence across app restarts

## Phase 3: Visualization & Export (1 week)

### Map Canvas Widget

- [x] Create `CaveMapPainter` class extending CustomPainter
- [x] Implement coordinate transformation (distance + heading → x,y)
- [x] Draw survey centerline path
- [x] Implement passage profile rendering for manual points (left/right walls)
- [x] Add conversion factor (meters to pixels with scale)
- [x] Apply scale, rotation, offset transformations
- [x] Add grid background
- [ ] Add north arrow indicator (compass overlay implemented instead)
- [ ] Optimize rendering for large datasets (>500 points)
- [ ] Test on both platforms

### Map View Screen

- [x] Create `MapScreen` widget (NorthOrientedMapView equivalent)
- [x] Add GestureDetector for pan, zoom
- [x] Implement pinch-to-zoom gesture
- [x] Add compass overlay widget
- [x] Add scale indicator
- [x] Add stats overlay (points, distance)
- [x] Add reset view button
- [ ] Implement two-finger rotation gesture
- [ ] Add fit-to-screen on initial load
- [ ] Implement double-tap to exit (using accelerometer)
- [ ] Test gesture conflicts and smoothness

### Compass Overlay Widget

- [x] Create compass overlay widget
- [x] Display north indicator with heading
- [ ] Add north indicator (N/S/E/W labels)
- [ ] Make semi-transparent for visibility
- [ ] Position in top-right corner
- [ ] Test visibility in various map scenarios

## Phase 4: Polish & Platform Adaptation (1 week)

### iOS-Specific
- [ ] Implement Cupertino-styled buttons and navigation where appropriate
- [ ] Test on iPhone 12, 13, 14, 15 models
- [ ] Verify App Store compliance
- [ ] Configure Info.plist for sensor/location permissions
- [ ] Add permission request descriptions
- [ ] Test in waterproof case (button accessibility)
- [ ] Optimize for iOS notch/Dynamic Island

### Android-Specific
- [ ] Implement Material Design 3 components
- [ ] Test on Pixel, Samsung, OnePlus devices (varied sensors)
- [ ] Configure AndroidManifest.xml for permissions
- [ ] Handle runtime permission requests
- [ ] Test background sensor restrictions (Android 12+)
- [ ] Optimize for different screen sizes and densities
- [ ] Test hardware button mappings (volume buttons as depth adjust)

### Performance Optimization
- [ ] Profile sensor update performance (DevTools)
- [ ] Optimize map canvas rendering (repaint only when needed)
- [ ] Reduce unnecessary notifyListeners() calls
- [ ] Implement sensor data throttling if needed
- [ ] Test battery consumption during 30-minute survey
- [ ] Ensure UI remains at 60fps during sensor updates
- [ ] Test with 1000+ survey points

### Accessibility & UX
- [ ] Add accessibility labels to all buttons
- [ ] Test with screen readers (iOS VoiceOver, Android TalkBack)
- [ ] Implement haptic feedback for button taps (underwater confirmation)
- [ ] Add loading indicators where appropriate
- [ ] Implement error handling and user-friendly error messages
- [ ] Add onboarding tutorial for first-time users
- [ ] Test in bright sunlight (screen visibility)

## Phase 5: Testing & Migration (1 week)

### Data Migration

- [ ] Create Swift script to export UserDefaults to JSON
- [ ] Create Dart migration script to import JSON to Draft
- [ ] Test migration with real survey data from Swift app
- [ ] Add first-launch import flow in Flutter app (user selects JSON file)
- [ ] Test migration failure scenarios and rollback
- [ ] Create user documentation for manual data transfer
- [ ] Add "Import from iOS App" button in Flutter app settings

### Testing
- [ ] Write widget tests for all major screens
- [ ] Write integration tests for end-to-end survey flow
- [ ] Test on minimum supported devices (iOS 12.0, Android 8.0)
- [ ] Test on latest devices (iOS 18, Android 15)
- [ ] Conduct real underwater test with waterproof case
- [ ] Compare CSV output byte-for-byte with Swift version
- [ ] Test with 10+ actual cave surveys
- [ ] Beta test with 20 cave divers

### Documentation
- [ ] Update README with Flutter setup instructions
- [ ] Document new architecture in openspec/project.md
- [ ] Create migration guide for existing users
- [ ] Update AGENTS.md with Flutter conventions
- [ ] Document platform-specific considerations
- [ ] Create troubleshooting guide
- [ ] Record video tutorial for new features

### App Store Preparation

- [ ] Update App Store screenshots (both platforms)
- [ ] Write app descriptions emphasizing cross-platform support
- [ ] Create promotional graphics
- [ ] Prepare release notes for version 2.0 (or new app listing)
- [ ] Decide: New app listing OR update existing iOS app with Flutter version
- [ ] Submit to Apple App Store review (new bundle ID if separate app)
- [ ] Submit to Google Play Store review (first Android release)
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Link to Swift app in Flutter app description for existing users

## Phase 6: Archive Original Swift Code (Post-Release, 3-6 months)

### Swift Code Archival (Original CaveDiveMap Repository)

- [ ] Confirm Flutter version is stable (3-6 months of production use)
- [ ] Confirm <1% crash rate on both platforms
- [ ] Confirm positive user feedback and adoption
- [ ] Create `archive/` directory in original CaveDiveMap repository
- [ ] Move all `cave-mapper/` Swift source files to `archive/swift-ios-app/`
- [ ] Move Xcode project files to archive
- [ ] Update main README to indicate Swift version is archived
- [ ] Add README in archive explaining historical context
- [ ] Keep OpenSpec documentation and migration plan in main directory
- [ ] Update repository description to indicate Flutter as primary
- [ ] Create final release tag for Swift version before archiving
- [ ] Optional: Keep Swift version available for AR features until Flutter AR mature

## Post-Release

### Monitoring
- [ ] Set up analytics for usage patterns
- [ ] Monitor crash reports for platform-specific issues
- [ ] Track sensor accuracy metrics
- [ ] Gather user feedback on Android experience
- [ ] Monitor battery usage reports

### Future Enhancements (Phase 2)
- [ ] Investigate Flutter AR plugins for VisualMapper replacement
- [ ] Add Bluetooth sensor support for Android
- [ ] Implement cloud backup (optional)
- [ ] Add collaborative survey features
- [ ] Integrate with cave survey databases

## Completion Criteria

All tasks marked complete AND:
- [ ] Zero critical bugs in beta testing
- [ ] <5% crash rate on both platforms
- [ ] Positive feedback from 80%+ of beta testers
- [ ] Performance benchmarks met (see proposal.md)
- [ ] App Store and Play Store approval received
- [ ] Migration guide published
- [ ] Support documentation complete
