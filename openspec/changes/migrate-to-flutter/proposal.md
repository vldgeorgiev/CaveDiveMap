# Proposal: Migrate to Flutter for Cross-Platform Support

**Change ID**: `migrate-to-flutter`  
**Type**: Architecture Migration  
**Status**: Proposed  
**Created**: 2025-12-09

## Summary

Create a new cross-platform CaveDiveMap application using Flutter in a separate repository, enabling deployment on both iOS and Android. The new app will implement core surveying functionality while temporarily excluding AR/3D visualization features (VisualMapper). The existing Swift/SwiftUI iOS app will remain functional and published during the transition, then archived after the Flutter version is stable.

## Motivation

### Current State Problems

1. **Platform Lock-In**: iOS-only limits potential user base (many cave divers use Android devices)
2. **Code Duplication**: Supporting Android would require maintaining two separate codebases
3. **Market Limitation**: Unable to serve Android-dominated markets
4. **Development Velocity**: Changes must be implemented twice for dual-platform support

### Benefits of Flutter Migration

1. **Single Codebase**: Write once, deploy to iOS and Android
2. **Sensor Support**: Excellent magnetometer and compass access on both platforms
3. **Native Performance**: Critical for real-time 50Hz magnetometer readings
4. **Development Speed**: Hot reload and unified codebase accelerate iteration
5. **Market Expansion**: Reach Android users (>70% global smartphone market)
6. **Maintenance**: Single codebase reduces long-term maintenance burden

### Success Criteria

- [ ] Core surveying functionality works on both iOS and Android
- [ ] Magnetometer-based distance measurement maintains accuracy
- [ ] Compass heading accuracy matches current iOS implementation
- [ ] Data export (CSV/Therion) produces identical output
- [ ] 2D map visualization with gestures (pan, zoom, rotate)
- [ ] Button customization system preserved for underwater usability
- [ ] Performance: <50ms sensor processing latency
- [ ] Existing iOS survey data can be migrated to new format

## Scope

### In Scope

- Magnetometer service and peak detection algorithm
- Compass/heading service with calibration
- Automatic survey point generation
- Manual survey point entry with cyclic parameter editing
- Data persistence (Hive instead of UserDefaults)
- CSV and Therion export functionality
- 2D map visualization with custom painting
- Button customization system
- Settings and calibration UI
- Data reset functionality
- Share functionality for exports
- Platform-specific UI adaptation (Material/Cupertino)

### Out of Scope (Phase 2)

- AR/3D visualization (VisualMapper)
- Point cloud rendering
- RealityKit/ARKit features
- Camera integration
- Advanced 3D passage modeling

### Repository Strategy

- **New Repository**: `CaveDiveMap-Flutter` (separate from current repo)
- **Old Repository**: `CaveDiveMap` remains active during transition
- **Archive Plan**: Swift code moved to `archive/` folder after Flutter version is stable and proven
- **Independence**: Both apps can coexist on App Store during transition period

### Dependencies

- None (standalone implementation in new repository)

## Technical Approach

### Technology Stack

- **Framework**: Flutter 3.38+ (stable as of Dec 2025)
- **Language**: Dart 3.10+
- **State Management**: Provider 6.1.5+
- **Storage**: Hive 2.2.3 (or Isar 4.x for future enhancements)
- **Sensors**: sensors_plus 7.0.0, flutter_compass 0.8.1
- **Build System**: Flutter build tools (iOS: Xcode, Android: Gradle)

### Architecture Migration

**From (Swift/SwiftUI MVVM):**
```
SwiftUI Views → ViewModels → DataManager (UserDefaults)
```

**To (Flutter Provider Pattern):**
```
Flutter Widgets → Services (ChangeNotifier) → StorageService (Hive)
```

### Key Mappings

| iOS/Swift | Flutter | Plugin/Package |
|-----------|---------|----------------|
| CoreMotion magnetometer | MagnetometerEvent | sensors_plus |
| CoreLocation heading | CompassEvent | flutter_compass |
| UserDefaults | Box<T> | hive |
| @StateObject/@ObservedObject | ChangeNotifier + Provider | provider |
| NavigationStack | Navigator 2.0 | built-in |
| Share sheet | Share.share() | share_plus |
| CustomPaint | CustomPainter | built-in |

### Data Migration Strategy

1. Export existing UserDefaults data to JSON
2. Create migration script (Dart or Python)
3. Import JSON into Hive boxes on first launch
4. Provide manual export/import for users

### Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Sensor performance differences | High | Benchmark both platforms early, adjust sampling rates |
| Android magnetometer variations | Medium | Test on multiple devices, adjustable thresholds |
| Data migration failures | Medium | Extensive testing, fallback to manual CSV import |
| Learning curve (Dart/Flutter) | Low | Well-documented, similar to Swift |
| User disruption | Medium | Maintain iOS app during migration, phased rollout |

## Implementation Plan

See `tasks.md` for detailed task breakdown.

**Estimated Timeline**: 6-8 weeks (in new repository)

- Phase 0 (0.5 weeks): Repository setup and project initialization
- Phase 1 (2-3 weeks): Core sensor services and data layer
- Phase 2 (2 weeks): UI screens and data entry
- Phase 3 (1 week): Export, settings, and polish
- Phase 4 (1 week): Testing and platform-specific tweaks
- Phase 5 (1 week): Beta testing and refinement
- Phase 6 (post-release): Archive Swift code in original repo after 3-6 months stability

## Rollout Strategy

### Beta Testing

1. **Internal Testing**: Core team tests on iOS and Android (2 devices each)
2. **Limited Beta**: 10-20 cave divers with diverse devices
3. **Public Beta**: Wider rollout via TestFlight (iOS) and Google Play Beta (Android)

### Release Approach

**Selected Strategy: Separate Apps (Recommended)**
- Create new Flutter app in separate repository (`CaveDiveMap-Flutter`)
- Both apps coexist independently during development and transition
- Swift version remains on App Store unchanged
- Flutter version published as new app or version 2.0 when ready
- Users migrate data manually via export/import
- Swift code archived in `CaveDiveMap/archive/` after Flutter version proven stable

**Benefits**:
- No disruption to existing iOS users
- Clean development environment
- Easy rollback if issues arise
- Both apps can coexist indefinitely if needed
- Clear separation of concerns

**Alternative (Not Recommended)**: In-place migration would risk breaking existing users and complicate development.

## Success Metrics

- [ ] App launches successfully on iOS and Android
- [ ] Magnetometer detects peaks with >95% accuracy vs. Swift version
- [ ] Compass heading within ±2° of Swift version
- [ ] CSV export byte-identical to Swift version (same input data)
- [ ] No crashes during 30-minute survey session
- [ ] UI responsive (<16ms frame time) during sensor updates
- [ ] Battery consumption within 10% of Swift version
- [ ] 50+ successful surveys on production Android devices

## Open Questions

1. Should we maintain Swift codebase for AR features or wait for Flutter AR maturity?
2. Do we need offline map tiles or is custom canvas sufficient?
3. Should Android version support external Bluetooth sensors?
4. What is minimum Android version to support? (recommend Android 8.0+)
5. How to handle waterproof case diversity on Android (100+ models)?

## Alternatives Considered

### React Native

**Pros:**
- JavaScript/TypeScript ecosystem familiar to many
- Large community and packages

**Cons:**
- Performance concerns for 50Hz sensor data
- Less mature sensor plugins
- Bridge overhead for real-time data

**Decision**: Rejected due to performance requirements

### Native Android Development (Kotlin)

**Pros:**
- Best Android performance
- Full platform API access

**Cons:**
- Requires maintaining two codebases (Swift + Kotlin)
- Doubles development effort for features
- Synchronization challenges

**Decision**: Rejected due to maintenance burden

### Xamarin/MAUI

**Pros:**
- C# ecosystem
- .NET MAUI is Microsoft-backed

**Cons:**
- Smaller community than Flutter
- Less mature cross-platform sensor support
- Uncertain long-term Microsoft commitment

**Decision**: Rejected due to ecosystem maturity

## References

- Flutter sensors_plus: https://pub.dev/packages/sensors_plus
- Flutter compass: https://pub.dev/packages/flutter_compass
- Hive documentation: https://docs.hivedb.dev/
- Provider pattern: https://pub.dev/packages/provider
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels
