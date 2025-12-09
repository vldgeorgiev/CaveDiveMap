# Design Decisions: Migrate to Flutter

**Change ID**: `migrate-to-flutter`  
**Implementation Strategy**: New Flutter app in separate repository (`CaveDiveMap-Flutter`)

## Repository Architecture

### Separate Repository Strategy

**Selected**: Create new `CaveDiveMap-Flutter` repository

**Rationale**:

1. **Risk Mitigation**: Existing iOS users unaffected during development
2. **Independent Releases**: Flutter app can iterate rapidly without impacting Swift version
3. **Clean Architecture**: Start with fresh project structure optimized for Flutter
4. **Rollback Safety**: Swift app remains fully functional if Flutter version encounters issues
5. **Version Control**: Clear git history separation between platforms
6. **Team Collaboration**: Enables parallel development on both versions during transition

**Repository Structure**:

- **`CaveDiveMap`** (existing): Swift iOS app, eventually archived
- **`CaveDiveMap-Flutter`** (new): Flutter cross-platform app

**Archival Plan**:

- After 3-6 months of stable Flutter production use (<1% crash rate, positive feedback)
- Swift code moved to `archive/swift-ios-app/` in original repository
- OpenSpec documentation remains in main directory
- Final Swift release tag created before archiving
- AR features may remain in Swift until Flutter AR ecosystem matures

## Technology Choices

### Why Flutter Over Alternatives

**Selected**: Flutter 3.38+ with Dart 3.10+

**Rationale**:
1. **Latest Stable**: Flutter 3.38 released December 2025 with improved performance and stability
2. **Sensor Performance**: Native-level performance for 50Hz magnetometer readings via platform channels
3. **Single Codebase**: Reduces maintenance from O(2n) to O(n) development effort
4. **Mature Ecosystem**: sensors_plus 7.0.0 (397k downloads) and flutter_compass 0.8.1 (60k downloads) are production-ready
5. **Development Velocity**: Hot reload enables rapid iteration on UI and sensor logic
6. **Cross-Platform Canvas**: CustomPainter works identically on iOS/Android for map rendering
7. **Strong Typing**: Dart 3.10's type system similar to Swift, reduces migration errors

**Rejected Alternatives**:
- React Native: Bridge overhead unsuitable for real-time sensor data
- Xamarin/MAUI: Smaller ecosystem, less mature sensor support
- Native (Swift + Kotlin): 2x development effort, synchronization complexity

### State Management: Provider

**Selected**: Provider 6.1.5 package

**Rationale**:
1. **Simplicity**: App has straightforward state flow (sensors → UI)
2. **Performance**: ChangeNotifier is efficient for this use case
3. **Familiarity**: Similar to Swift's ObservableObject pattern
4. **No Boilerplate**: Minimal setup compared to BLoC or Redux
5. **Flutter Integration**: Recommended by Flutter team for small-to-medium apps
6. **Stability**: Version 6.1.5 is mature and widely adopted (1.8M downloads, 10.9k likes)

**Alternatives Considered**:
- Riverpod: More powerful but overkill for this app's complexity
- BLoC: Unnecessary ceremony for sensor data streaming
- GetX: Magic strings and global state unsuitable for maintainable code

### Storage: Hive

**Selected**: Hive 2.2.3 (NoSQL key-value/document database)

**Rationale**:
1. **Type Safety**: TypeAdapter ensures compile-time guarantees
2. **Performance**: 10-100x faster than SharedPreferences for complex objects
3. **No Native Code**: Pure Dart, no platform channel overhead
4. **Lazy Loading**: Can handle 10,000+ survey points efficiently
5. **Encryption**: Built-in AES-256 support for future encrypted surveys
6. **Migration Path**: Easy to migrate from UserDefaults JSON
7. **Proven**: 1.09M downloads, 6.2k likes on pub.dev

**Note**: Consider migrating to Isar 4.x in future for queries and multi-isolate support (same publisher)

**Alternatives Considered**:
- SharedPreferences: Too slow for large survey datasets (>100 points)
- SQLite (sqflite): Unnecessary complexity for simple key-value needs
- ObjectBox: Requires build_runner, adds compilation complexity

### Sensor Libraries

**Selected**: 
- `sensors_plus 7.0.0` (magnetometer, gyroscope, accelerometer, barometer)
- `flutter_compass 0.8.1` (compass/heading)

**Rationale**:
1. **Community Standard**: Most popular sensor packages in Flutter ecosystem
2. **Active Maintenance**: sensors_plus updated 2 months ago, supports Flutter 3.19+
3. **Platform Parity**: Consistent API across iOS and Android
4. **Performance**: Direct platform channel to native sensors (no middleware)
5. **Proven**: sensors_plus has 397k downloads (Flutter Favorite), flutter_compass has 60k downloads
6. **Requirements**: Flutter >=3.19.0, Dart >=3.3.0, iOS >=12.0, Android API >=26

**Alternatives Considered**:
- Native platform channels: Would require maintaining iOS and Android implementations
- motion_sensors: Less popular, inconsistent updates

## Architecture Decisions

### Service Layer Pattern

**Decision**: Use service classes (extending ChangeNotifier) instead of ViewModels

**Structure**:
```
Widgets (UI)
   ↓ Provider.of / Consumer
Services (Business Logic + State)
   ↓ Direct calls
Storage (Persistence)
```

**Rationale**:
1. **Clear Separation**: Services encapsulate single responsibilities
2. **Testability**: Can mock services easily in widget tests
3. **Reusability**: Services can be used by multiple screens
4. **Provider Integration**: ChangeNotifier works seamlessly with Provider

**Trade-offs**:
- Services are stateful (unlike pure functions)
- Must carefully manage dispose() to prevent memory leaks

### Data Model: Immutable vs Mutable

**Decision**: Use immutable data classes with copyWith methods

```dart
class SurveyData {
  final int recordNumber;
  final double distance;
  // ... other fields
  
  const SurveyData({required this.recordNumber, ...});
  
  SurveyData copyWith({int? recordNumber, ...}) => SurveyData(...);
}
```

**Rationale**:
1. **Thread Safety**: Immutable objects safe for sensor callbacks
2. **Predictability**: No unexpected mutations
3. **Hive Compatibility**: Works well with Hive's object storage
4. **Debugging**: Easier to track state changes

**Trade-offs**:
- Slightly more verbose than mutable objects
- Requires copyWith boilerplate (can use code generation if needed)

### Navigation: Navigator 2.0 vs 1.0

**Decision**: Use Navigator 1.0 (imperative routing)

**Rationale**:
1. **Simplicity**: App has simple navigation (5 screens, no deep linking)
2. **Developer Familiarity**: Easier for contributors to understand
3. **Less Boilerplate**: Navigator 1.0 sufficient for this use case
4. **Migration Path**: Can upgrade to Navigator 2.0 later if needed

**Trade-offs**:
- No declarative routing
- Manual route management

### Sensor Data Flow

**Decision**: Stream-based processing with debouncing

```dart
magnetometerEvents
  .listen((event) {
    // Process immediately for peak detection
    _detectPeak(calculateMagnitude(event));
    
    // Debounce UI updates
    if (_shouldUpdateUI()) {
      notifyListeners();
    }
  });
```

**Rationale**:
1. **Responsiveness**: Peak detection happens immediately (critical for accuracy)
2. **Performance**: UI updates throttled to 60fps max
3. **Battery**: Reduces unnecessary repaints
4. **Accuracy**: No missed peaks due to UI throttling

**Trade-offs**:
- More complex than naive implementation
- Requires careful testing of throttle timing

## Platform-Specific Decisions

### UI Adaptation Strategy

**Decision**: Shared widgets with platform-specific overrides

```dart
// Shared widget with conditional styling
Widget buildButton() {
  return Platform.isIOS
    ? CupertinoButton(...)
    : ElevatedButton(...);
}
```

**Rationale**:
1. **Code Reuse**: 90%+ of UI logic is identical
2. **Native Feel**: Users expect platform conventions
3. **Maintainability**: Single widget tree, easier to update
4. **Performance**: Minimal overhead from platform checks

**Alternatives Considered**:
- Fully separate UI files: Too much duplication
- Force Material on iOS: Poor user experience
- Force Cupertino on Android: Inconsistent with platform

### Permission Handling

**Decision**: Request permissions on-demand with explanations

**Flow**:
1. User opens app
2. On sensor start, check permissions
3. If denied, show explanation dialog
4. Request permission
5. Handle permanent denial gracefully

**Rationale**:
1. **User Trust**: Explains why permissions needed before asking
2. **Platform Guidelines**: Follows iOS and Android best practices
3. **Graceful Degradation**: App explains limitations if denied

### Android Sensor Diversity

**Decision**: Adjustable thresholds with device profiles

**Approach**:
1. Default thresholds work for most devices
2. Settings allow manual adjustment
3. Add device-specific profiles for common phones (Samsung, Pixel)
4. Provide calibration wizard to auto-detect thresholds

**Rationale**:
1. **Flexibility**: Handles sensor variance across manufacturers
2. **User Control**: Advanced users can fine-tune
3. **Scalability**: Can add more profiles based on user feedback

## Performance Decisions

### Map Rendering Optimization

**Decision**: Use RepaintBoundary and shouldRepaint

```dart
class MapCanvas extends CustomPainter {
  @override
  bool shouldRepaint(MapCanvas oldDelegate) {
    return surveyPoints != oldDelegate.surveyPoints ||
           scale != oldDelegate.scale ||
           rotation != oldDelegate.rotation ||
           offset != oldDelegate.offset;
  }
}
```

**Rationale**:
1. **60fps Target**: Only repaint when actually needed
2. **Battery**: Reduces GPU usage
3. **Responsiveness**: Gestures remain smooth

### Sensor Update Rate

**Decision**: 50Hz (20ms) magnetometer updates with 60Hz UI updates

**Rationale**:
1. **Peak Detection**: 50Hz sufficient to catch magnet peaks
2. **Battery**: Higher rates drain battery without accuracy gain
3. **UI Smoothness**: 60fps (16.67ms) sufficient for visual feedback
4. **Platform Limits**: Some Android devices cap at 50Hz

**Benchmarking**:
- 10Hz: Misses peaks (REJECTED)
- 50Hz: Reliable peak detection (SELECTED)
- 100Hz: No accuracy improvement, worse battery (REJECTED)

## Data Migration Decisions

### Migration Timing

**Decision**: On-demand migration on first app launch

**Flow**:
1. Check for existing Hive data
2. If none, check for migration marker file
3. Prompt user to import from old app
4. User exports JSON from Swift app
5. User imports JSON in Flutter app
6. Validate and convert to Hive

**Rationale**:
1. **User Control**: User decides when to migrate
2. **Safety**: Doesn't auto-delete old app data
3. **Flexibility**: Supports partial migration

**Alternatives Considered**:
- Automatic background migration: Too risky if fails
- Cloud migration: Requires backend infrastructure
- No migration: Forces users to manually re-enter data

### Data Validation

**Decision**: Strict validation during import with error reporting

**Checks**:
- Record number uniqueness
- Distance monotonically increasing
- Heading in range [0, 360)
- Depth >= 0
- Left/right/up/down >= 0
- rtype in ["auto", "manual"]

**Rationale**:
1. **Data Integrity**: Catches corrupted UserDefaults data
2. **User Feedback**: Reports specific errors
3. **Rollback**: Can abort import if validation fails

## Security Decisions

### Data Storage

**Decision**: Unencrypted Hive boxes by default, optional encryption in settings

**Rationale**:
1. **Performance**: Encryption adds overhead
2. **Use Case**: Survey data not typically sensitive
3. **Flexibility**: Users can enable encryption if needed

**Future**: Add encryption for commercial survey data (subscription feature)

### Permissions

**Decision**: Minimal permissions, request only when needed

**Required**:
- Sensors (magnetometer, compass): Core functionality
- Storage: Saving survey data
- Share: Exporting files

**Not Required**:
- Location: Only need compass heading, not GPS
- Camera: Excluded in this phase
- Network: No cloud features

## Testing Strategy

### Test Pyramid

**Unit Tests (70%)**:
- All service logic (magnetometer, compass, storage)
- Data models
- Export functions
- Calculations (distance, heading)

**Widget Tests (20%)**:
- Individual screen rendering
- Button interactions
- Gesture handling
- State updates

**Integration Tests (10%)**:
- End-to-end survey flow
- Data persistence
- Export functionality

**Rationale**: Focus on business logic correctness, UI tested manually

### Physical Device Testing

**Required Devices**:
- iOS: iPhone 12, 14, 15 (different magnetometer hardware)
- Android: Pixel 7, Samsung S22, OnePlus 10 (sensor diversity)

**Test Scenarios**:
- Magnetometer accuracy comparison (Swift vs Flutter)
- Battery consumption (30-minute survey)
- Waterproof case usability
- Bright sunlight visibility
- Cold water simulation (phone in freezer)

## Rollout Strategy

### Phased Release

**Phase 1: Internal Alpha (Week 1)**
- Core team tests on 2 iOS + 2 Android devices
- Fix critical bugs

**Phase 2: Closed Beta (Weeks 2-3)**
- 20 cave divers from community
- Diverse devices and waterproof cases
- Collect feedback on sensor accuracy

**Phase 3: Open Beta (Week 4)**
- TestFlight (iOS) + Play Store Beta (Android)
- Wider testing (100+ users)
- Monitor crash reports

**Phase 4: Production Release (Week 5-6)**
- Gradual rollout (10% → 50% → 100%)
- Monitor metrics
- Swift version remains available

**Rationale**: Catch platform-specific issues early, minimize user disruption

## Documentation Decisions

### Code Documentation

**Decision**: Inline comments for complex algorithms, README for architecture

**Coverage**:
- Peak detection algorithm: Detailed comments
- Coordinate transformations: Math explanations
- Platform-specific workarounds: Why + link to issue

**Rationale**: Code should be self-documenting, comments explain "why" not "what"

### User Documentation

**Decision**: In-app tutorials + external guide

**Components**:
- First-launch onboarding flow
- Contextual help buttons
- Video tutorials on YouTube
- Written guide on website
- Migration guide for existing users

**Rationale**: Multiple learning styles, reduce support burden

## Open Technical Questions

1. **AR Future**: Wait for flutter_arcore/ar_flutter maturity or maintain Swift AR separately?
2. **Offline Maps**: Add cached tiles or keep custom canvas only?
3. **Bluetooth Sensors**: Support external magnetometers (Android advantage)?
4. **Background Surveys**: Allow sensor monitoring with screen off?
5. **Data Format**: Stick with current CSV/Therion or add GPX export?

**Resolution Path**: Defer to Phase 2, gather user feedback from Flutter beta
