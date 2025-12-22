# Capability: Cross-Platform Architecture

**Change**: `migrate-to-flutter`  
**Capability ID**: `cross-platform-architecture`  
**Type**: New Capability

## ADDED Requirements

### Requirement: Flutter Framework (REQ-CROSS-001)

The application SHALL be built using Flutter 3.38+ with Dart 3.10+ to enable single-codebase deployment to both iOS and Android platforms.

**Priority**: MUST  
**Verification**: Compile and run application on both iOS and Android devices

#### Scenario: Compile for iOS

**Given** Flutter SDK 3.38+ is installed  
**And** Xcode is configured for iOS development  
**When** developer runs `flutter build ios --release`  
**Then** the build succeeds without errors  
**And** the resulting IPA can be installed on iPhone running iOS 12.0+

#### Scenario: Compile for Android

**Given** Flutter SDK 3.38+ is installed  
**And** Android SDK is configured  
**When** developer runs `flutter build apk --release`  
**Then** the build succeeds without errors  
**And** the resulting APK can be installed on Android device running API 26+ (Android 8.0+)

### Requirement: Magnetometer Service (REQ-CROSS-002)

The application SHALL provide a cross-platform magnetometer service that works identically on iOS and Android with 50Hz update rate.

**Priority**: MUST  
**Verification**: Compare sensor readings between iOS and Android devices

#### Scenario: Magnetometer initialization on iOS

**Given** application is launched on iPhone with magnetometer  
**When** user starts surveying  
**Then** magnetometer service initializes successfully  
**And** sensor updates are received at 50Hz (±5Hz)  
**And** peak detection algorithm matches Swift implementation accuracy (>95%)

#### Scenario: Magnetometer initialization on Android

**Given** application is launched on Android device with magnetometer  
**When** user starts surveying  
**Then** magnetometer service initializes successfully  
**And** sensor updates are received at 50Hz (±5Hz)  
**And** peak detection algorithm achieves >95% accuracy

#### Scenario: Peak detection accuracy

**Given** magnetometer is monitoring at 50Hz  
**And** measurement wheel completes 10 rotations  
**When** comparing detected peaks to actual rotations  
**Then** detection accuracy is >95%  
**And** false positive rate is <5%  
**And** missed peak rate is <5%

### Requirement: Compass Service (REQ-CROSS-003)

The application SHALL provide compass/heading service on both platforms with accuracy indicator.

**Priority**: MUST  
**Verification**: Test heading accuracy against known compass values

#### Scenario: Compass heading on iOS

**Given** application is running on iPhone  
**And** user has granted location permissions  
**When** compass service is started  
**Then** magnetic heading is provided within ±2° of Swift implementation  
**And** heading accuracy is calculated and displayed  
**And** accuracy indicator shows green when error <20°

#### Scenario: Compass heading on Android

**Given** application is running on Android device  
**And** user has granted location permissions  
**When** compass service is started  
**Then** magnetic heading updates at minimum 1Hz  
**And** heading accuracy is calculated and displayed  
**And** accuracy indicator shows green when error <20°

### Requirement: Data Storage (REQ-CROSS-004)

The application SHALL use Draft for cross-platform data persistence, storing survey points and application settings.

**Priority**: MUST  
**Verification**: Verify data persists across app restarts on both platforms

#### Scenario: Save survey point on iOS

**Given** application is running on iPhone  
**When** a new survey point is saved  
**Then** data is persisted to Draft box  
**And** data survives application restart  
**And** data can be retrieved with all fields intact

#### Scenario: Save survey point on Android

**Given** application is running on Android device  
**When** a new survey point is saved  
**Then** data is persisted to Draft box  
**And** data survives application restart  
**And** data can be retrieved with all fields intact

#### Scenario: Storage performance

**Given** survey contains 1000 data points  
**When** application loads all points  
**Then** load time is <500ms  
**And** save operation completes in <50ms

### Requirement: Export Compatibility (REQ-CROSS-005)

The application SHALL export CSV and Therion files with identical format to the Swift implementation.

**Priority**: MUST  
**Verification**: Byte-level comparison of exported files

#### Scenario: CSV export matches Swift output

**Given** identical survey data in Swift app and Flutter app  
**When** both apps export to CSV  
**Then** CSV files are byte-for-byte identical  
**And** all fields (recordNumber, distance, heading, depth, left, right, up, down, rtype) are present  
**And** numeric precision matches (2 decimal places)

#### Scenario: Therion export matches Swift output

**Given** identical survey data in Swift app and Flutter app  
**When** both apps export to Therion format  
**Then** Therion files are functionally equivalent  
**And** format is compatible with Therion cave survey software

### Requirement: Platform-Specific UI (REQ-CROSS-006)

The application SHALL adapt UI components to platform conventions while maintaining shared business logic.

**Priority**: SHOULD  
**Verification**: Manual UI review on both platforms

#### Scenario: iOS UI styling

**Given** application is running on iPhone  
**When** user navigates through screens  
**Then** buttons use Cupertino style where appropriate  
**And** navigation follows iOS conventions  
**And** UI feels native to iOS users

#### Scenario: Android UI styling

**Given** application is running on Android device  
**When** user navigates through screens  
**Then** buttons use Material Design 3 style  
**And** navigation follows Android conventions  
**And** UI feels native to Android users

### Requirement: Performance Parity (REQ-CROSS-007)

The application SHALL maintain performance comparable to the Swift implementation on iOS, and provide acceptable performance on Android.

**Priority**: MUST  
**Verification**: Benchmark testing

#### Scenario: Sensor processing latency

**Given** application is actively surveying  
**When** magnetometer detects peak  
**Then** processing latency is <50ms  
**And** UI updates within 16ms (60fps)  
**And** no frames are dropped during sensor updates

#### Scenario: Battery consumption

**Given** application is running 30-minute survey session  
**When** comparing battery usage to Swift version on same iPhone  
**Then** Flutter version uses within 10% of Swift version battery  
**And** Android version battery usage is reasonable for sensor-intensive app

#### Scenario: Map rendering performance

**Given** map view displays 500+ survey points  
**When** user pans, zooms, or rotates map  
**Then** frame rate remains at 60fps  
**And** gestures feel smooth and responsive  
**And** map updates without visible lag

### Requirement: Permission Handling (REQ-CROSS-008)

The application SHALL request and handle sensor permissions appropriately on both platforms.

**Priority**: MUST  
**Verification**: Test permission flows on both platforms

#### Scenario: iOS permission request

**Given** application is launched for first time on iPhone  
**When** user starts surveying  
**Then** system prompts for location access (for compass)  
**And** denial is handled gracefully with explanation  
**And** user can re-enable permission from settings

#### Scenario: Android permission request

**Given** application is launched for first time on Android  
**When** user starts surveying  
**Then** system prompts for necessary permissions  
**And** denial is handled gracefully with explanation  
**And** user can re-enable permission from settings  
**And** Android 12+ background restrictions are handled

## MODIFIED Requirements

None (this is a new capability)

## REMOVED Requirements

None (this is a new capability)

## RENAMED Requirements

None (this is a new capability)

---

## Dependencies

- Flutter SDK 3.38+ (stable as of Dec 2025)
- Dart SDK 3.10+
- sensors_plus 7.0.0 (requires Flutter >=3.19.0, iOS >=12.0)
- flutter_compass 0.8.1
- Draft
- provider 6.1.5+
- share_plus (latest)
- path_provider (latest)
- csv (latest for export functionality)

## Migration Notes

This capability replaces the iOS-only Swift/SwiftUI implementation. The Swift codebase will be preserved for AR features (VisualMapper) but core surveying functionality moves to Flutter.

## Testing Strategy

1. Unit tests for all service classes
2. Widget tests for UI components
3. Integration tests for end-to-end flows
4. Physical device testing on minimum 6 devices (3 iOS, 3 Android)
5. Beta testing with 20+ cave divers
6. Performance benchmarking against Swift version
7. Battery consumption testing
8. Waterproof case usability testing
