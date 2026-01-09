# Design Document: Migrate Swift UI to Flutter

**Change ID**: migrate-swift-ui-to-flutter  
**Author**: AI Assistant  
**Date**: 2025-12-09

## Overview

This document outlines the technical architecture and design decisions for migrating the Swift iOS app's UI patterns to the Flutter cross-platform implementation. The goal is to achieve visual and functional parity while adapting to Flutter's widget-based architecture and Material Design principles.

## Architecture Decisions

### 1. Layout Strategy: Stack-Based Positioning

**Problem**: Swift uses `ZStack` with `.offset()` modifiers to position circular buttons at custom locations on screen. Flutter doesn't have a direct equivalent.

**Options Considered**:
1. **Positioned within Stack**: Use `Stack` widget with `Positioned` children
2. **Transform.translate**: Use Transform widget to offset buttons
3. **CustomMultiChildLayout**: Create custom layout delegate
4. **Floating overlays**: Use Overlay widget with OverlayEntry

**Decision**: Use `Stack` with `Positioned` widgets

**Rationale**:
- Most similar to SwiftUI's ZStack conceptually
- Positioned allows explicit x/y positioning relative to Stack
- Simple to implement and understand
- Good performance for small number of widgets (4-6 buttons)
- Easy to animate and adjust dynamically

**Implementation Details**:
```dart
Stack(
  children: [
    // Background content (sensor data display)
    Column(...),
    
    // Positioned buttons
    Positioned(
      left: screenWidth / 2 + buttonConfig.offsetX,
      top: screenHeight / 2 + buttonConfig.offsetY,
      child: CircularActionButton(...),
    ),
  ],
)
```

**Trade-offs**:
- ✅ Simple and readable
- ✅ Direct control over positioning
- ✅ Easy to debug
- ⚠️ Manual calculation of screen center
- ⚠️ Need to handle screen size changes
- ❌ More verbose than Transform

### 2. Button Customization: Service + ChangeNotifier

**Problem**: Need to persist button configurations (size, offsetX, offsetY) and make them reactive so UI updates when settings change.

**Options Considered**:
1. **ChangeNotifier service**: Extend ChangeNotifier, use Provider
2. **Riverpod StateNotifier**: Use Riverpod for state management
3. **Bloc pattern**: Use flutter_bloc for event-driven state
4. **GetX**: Use GetX reactive state management

**Decision**: ChangeNotifier service with Provider

**Rationale**:
- Consistent with existing app architecture (already using Provider)
- Simple and lightweight for this use case
- ChangeNotifier perfect for settings that change infrequently
- Easy integration with Hive for persistence
- No additional dependencies needed

**Implementation Details**:
```dart
class ButtonCustomizationService extends ChangeNotifier {
  final StorageService _storage;
  
  ButtonConfig mainSaveButton = ButtonConfig.defaultMainSave();
  // ... other buttons
  
  Future<void> loadSettings() async {
    mainSaveButton = await _storage.loadButtonConfig('main_save') 
        ?? ButtonConfig.defaultMainSave();
    notifyListeners();
  }
  
  Future<void> updateButton(String key, ButtonConfig config) async {
    // Update in-memory
    // Save to storage
    // Notify listeners
  }
}
```

**Trade-offs**:
- ✅ Familiar pattern for team
- ✅ Integrates with existing Provider setup
- ✅ Simple testing
- ⚠️ Need to manage loading state
- ❌ Slightly more boilerplate than Riverpod

### 3. Tap vs Long-Press Detection: GestureDetector

**Problem**: Need to distinguish between tap (increment by 1) and long-press (rapid increment by 10). Standard `onTap` and `onLongPress` fire independently and don't prevent tap after long-press.

**Options Considered**:
1. **GestureDetector with manual timing**: Use onTapDown/onTapUp with Timer
2. **InkWell with custom handling**: Extend InkWell behavior
3. **Custom GestureRecognizer**: Subclass TapGestureRecognizer
4. **Third-party package**: Use hold_down_button or similar

**Decision**: GestureDetector with manual Timer-based detection

**Rationale**:
- Full control over timing threshold (0.5s)
- Can implement exact Swift behavior (tap if <0.5s, hold if >=0.5s)
- No dependencies
- Clear logic flow
- Easy to clean up timers

**Implementation Details**:
```dart
Timer? _holdTimer;
Timer? _repeatTimer;
bool _isHolding = false;

GestureDetector(
  onTapDown: (_) {
    _holdTimer = Timer(Duration(milliseconds: 500), () {
      // Threshold crossed, enter hold mode
      _isHolding = true;
      _startRepeatTimer();
    });
  },
  onTapUp: (_) {
    if (!_isHolding) {
      // Tap (released before 0.5s)
      _incrementByOne();
    }
    _cleanup();
  },
  onTapCancel: () {
    _cleanup();
  },
  child: CircularActionButton(...),
)

void _startRepeatTimer() {
  _repeatTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
    _incrementByTen();
  });
}

void _cleanup() {
  _holdTimer?.cancel();
  _repeatTimer?.cancel();
  _isHolding = false;
}
```

**Trade-offs**:
- ✅ Exact behavior match with Swift
- ✅ No dependencies
- ✅ Clear state machine
- ⚠️ Need careful timer cleanup
- ⚠️ Must test edge cases (rapid tap, hold then move finger)

### 4. Theme Management: ThemeData Extensions

**Problem**: Need to define and apply consistent colors and typography across all screens.

**Options Considered**:
1. **ThemeData extensions**: Extend ThemeData with custom properties
2. **Static constants class**: Create AppColors and AppTextStyles classes
3. **Theme package**: Use google_fonts or custom theme package
4. **Code generation**: Use build_runner to generate theme

**Decision**: Static constants with ThemeData integration

**Rationale**:
- Simple and explicit
- No magic or hidden behavior
- Easy to find color/style definitions
- Can still use ThemeData.of(context) where needed
- Portable (copy constants to new project easily)

**Implementation Details**:
```dart
// lib/utils/theme_extensions.dart
class AppColors {
  static const actionSave = Colors.green;
  static const actionMap = Colors.blue;
  static const actionIncrement = Colors.orange;
  static const actionReset = Colors.red;
  // ...
}

class AppTextStyles {
  static const largeTitle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  // ...
}

// Usage
Text('12.45', style: AppTextStyles.largeTitle.copyWith(color: AppColors.primary));
```

**Trade-offs**:
- ✅ Simple and explicit
- ✅ Easy to modify
- ✅ No dependencies
- ✅ Type-safe
- ⚠️ Need to manually apply (no automatic theming)
- ❌ More verbose than ThemeData extensions

### 5. Map Gestures: RawGestureDetector

**Problem**: Need to support simultaneous pan, zoom, and rotate gestures on map view.

**Options Considered**:
1. **GestureDetector with scale**: Use ScaleGestureDetector for pan/zoom/rotate
2. **RawGestureDetector**: Use individual recognizers with custom arena resolution
3. **InteractiveViewer**: Use built-in InteractiveViewer widget
4. **Custom gesture library**: Use flutter_gesture or similar

**Decision**: GestureDetector with ScaleGestureDetector (simplest)

**Rationale**:
- ScaleGestureDetector handles pan, zoom, and rotate in one gesture
- Built-in, no dependencies
- Simple API with scale, focalPoint, and rotation
- Good performance
- Standard Flutter pattern

**Implementation Details**:
```dart
GestureDetector(
  onScaleStart: (details) {
    _startScale = _currentScale;
    _startRotation = _currentRotation;
  },
  onScaleUpdate: (details) {
    setState(() {
      _currentScale = _startScale * details.scale;
      _currentRotation = _startRotation + details.rotation;
      _offset += details.focalPointDelta;
    });
  },
  child: CustomPaint(
    painter: CaveMapPainter(
      scale: _currentScale,
      rotation: _currentRotation,
      offset: _offset,
    ),
  ),
)
```

**Trade-offs**:
- ✅ Simple, one gesture handler
- ✅ Built-in support for all three gesture types
- ✅ Good performance
- ⚠️ Less fine-grained control than RawGestureDetector
- ❌ Can't easily customize gesture recognition logic

**Alternative**: If ScaleGestureDetector doesn't provide enough control, fall back to RawGestureDetector with PanGestureRecognizer, ScaleGestureRecognizer, and RotationGestureRecognizer.

### 6. Compass Overlay: Custom Painter

**Problem**: Need to draw a north-pointing compass that rotates opposite to map rotation.

**Options Considered**:
1. **Transform.rotate on Icon**: Rotate existing compass icon
2. **CustomPainter**: Draw compass with Canvas API
3. **AnimatedBuilder**: Animated rotation of static widget
4. **Image asset**: Rotate PNG/SVG compass image

**Decision**: Transform.rotate on Icon widget

**Rationale**:
- Simplest implementation
- Good performance (GPU-accelerated)
- No custom drawing code needed
- Material Icons has good compass/arrow icons
- Easy to adjust size and color

**Implementation Details**:
```dart
Widget build(BuildContext context) {
  return Positioned(
    top: 16,
    right: 16,
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.opacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Transform.rotate(
        angle: -mapRotation, // Rotate opposite to map
        child: Icon(
          Icons.navigation,
          color: Colors.white,
          size: 32,
        ),
      ),
    ),
  );
}
```

**Trade-offs**:
- ✅ Very simple
- ✅ Good performance
- ✅ Built-in icon looks good
- ⚠️ Less customization than CustomPainter
- ❌ Limited to available icons

### 7. Circular Buttons: Container with BoxDecoration

**Problem**: Need to create circular buttons with custom colors, sizes, and icons.

**Options Considered**:
1. **FloatingActionButton**: Use FAB with custom styling
2. **Container with BoxDecoration**: Use Container(decoration: BoxDecoration(shape: circle))
3. **ClipOval with ElevatedButton**: Clip rectangular button to circle
4. **Custom painter**: Draw button with Canvas

**Decision**: Container with BoxDecoration

**Rationale**:
- Full control over size, color, shadow
- Simple to implement
- No widget styling constraints (unlike FAB)
- Works well with GestureDetector for custom tap handling
- Easy to add shadows and borders

**Implementation Details**:
```dart
GestureDetector(
  onTap: onTap,
  onTapDown: onTapDown,
  // ... tap handling
  child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(
          color: Colors.black.opacity(0.25),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Icon(
      icon,
      color: Colors.white,
      size: size * 0.35,
    ),
  ),
)
```

**Trade-offs**:
- ✅ Full control
- ✅ Simple code
- ✅ Easy to customize
- ⚠️ Need to manually add Material ripple effect (if desired)
- ❌ No built-in accessibility features (must add manually)

### 8. Data Persistence: Hive for Button Settings

**Problem**: Need to persist button customization settings locally.

**Options Considered**:
1. **SharedPreferences**: Key-value pairs (already used for some settings)
2. **Hive**: NoSQL database (already used for survey data)
3. **SQLite**: Relational database
4. **JSON files**: Store in app documents directory

**Decision**: Hive (consistent with existing architecture)

**Rationale**:
- Already using Hive for survey data
- Type-safe with TypeAdapters
- Fast and efficient
- Good for structured data (ButtonConfig objects)
- Consistent with project's storage strategy

**Implementation Details**:
```dart
// ButtonConfig model with Hive annotations
@HiveType(typeId: 2)
class ButtonConfig {
  @HiveField(0)
  final double size;
  
  @HiveField(1)
  final double offsetX;
  
  @HiveField(2)
  final double offsetY;
}

// Storage
class StorageService {
  static const String _buttonSettingsBox = 'buttonSettings';
  
  Future<void> saveButtonConfig(String key, ButtonConfig config) async {
    final box = await Hive.openBox(_buttonSettingsBox);
    await box.put(key, config);
  }
  
  Future<ButtonConfig?> loadButtonConfig(String key) async {
    final box = await Hive.openBox(_buttonSettingsBox);
    return box.get(key);
  }
}
```

**Trade-offs**:
- ✅ Consistent with existing code
- ✅ Type-safe
- ✅ Fast
- ⚠️ Need to register TypeAdapter
- ❌ Slightly more setup than SharedPreferences

## Component Design

### Reusable Widgets

#### 1. CircularActionButton
**Purpose**: Reusable circular button with icon, color, and glove-friendly gesture handling.

**Props**:
- `double size`: Button diameter (default: 90px)
- `Color color`: Background color
- `IconData icon`: Icon to display
- `VoidCallback? onTap`: Tap callback
- `VoidCallback? onLongPress`: Long-press callback
- `VoidCallback? onTapDown`: Tap down callback (for custom gesture handling)
- `double slopTolerance`: Movement tolerance in pixels (default: 30px)

**Features**:
- Circular shape with BoxDecoration
- Icon scaled to 35-40% of button size
- Shadow effect
- Optional text label (for "Reset" button)
- StatefulWidget with tap position tracking
- 30px movement tolerance prevents glove-induced tap cancellation
- Automatic tap target expansion to minimum 48x48px

#### 2. PositionedButton
**Purpose**: Wrapper that positions CircularActionButton using ButtonConfig.

**Props**:
- `ButtonConfig config`: Size and offset configuration
- `Widget child`: Button widget to position (usually CircularActionButton)
- `Size screenSize`: Screen dimensions for calculating center

**Features**:
- Calculates absolute position from center + offsets
- Uses Positioned widget
- Updates when config changes (Consumer)

#### 3. MonospacedText
**Purpose**: Text widget with tabular figures for numeric displays.

**Props**:
- `String text`: Text to display
- `double fontSize`: Font size
- `FontWeight fontWeight`: Font weight
- `Color color`: Text color

**Features**:
- Applies FontFeature.tabularFigures()
- Consistent number alignment
- Reusable across screens

#### 4. HeadingAccuracyIndicator
**Purpose**: Shows heading accuracy with color-coded circle.

**Props**:
- `double accuracy`: Accuracy in degrees

**Features**:
- Green circle if accuracy < 20°
- Red circle if accuracy >= 20°
- Shows "Heading error: X.XX"

#### 5. InfoCard
**Purpose**: Rounded card container for grouped information.

**Props**:
- `Widget child`: Card content
- `EdgeInsets? padding`: Optional padding override

**Features**:
- Grey[900] background
- Rounded corners (12px radius)
- Subtle border
- Consistent padding

#### 6. CompassOverlay
**Purpose**: North-pointing compass for map view.

**Props**:
- `double mapRotation`: Current map rotation in radians

**Features**:
- Positioned in top-right
- Semi-transparent black background
- White compass icon
- Rotates opposite to map

## State Management Flow

### Button Customization Flow
```
User Interaction (Slider)
  ↓
ButtonCustomizationScreen.setState()
  ↓
ButtonCustomizationService.updateButton()
  ↓
StorageService.saveButtonConfig()
  ↓
ButtonCustomizationService.notifyListeners()
  ↓
MainScreen rebuilds (Consumer)
  ↓
PositionedButton uses new config
```

### Sensor Data Flow
```
Sensor Hardware
  ↓
MagnetometerService/CompassService (streams)
  ↓
Service updates internal state
  ↓
Service.notifyListeners()
  ↓
MainScreen rebuilds (Consumer)
  ↓
UI shows updated values
```

### Manual Point Save Flow
```
User adjusts parameters (tap/long-press)
  ↓
SaveDataScreen.setState() (local state)
  ↓
User taps Save button
  ↓
Create SurveyData object
  ↓
StorageService.saveSurveyPoint()
  ↓
MagnetometerService.incrementPointNumber()
  ↓
Navigate back to MainScreen
  ↓
Show success SnackBar
```

## Performance Considerations

### 1. Real-Time Sensor Updates
**Challenge**: Sensor data updates ~50Hz, could cause excessive rebuilds.

**Solution**:
- Use `Consumer` with specific service types (don't rebuild whole screen)
- Throttle updates to 10-20Hz for UI (display doesn't need 50Hz)
- Use `const` widgets where possible to prevent rebuilds
- Avoid rebuilding positioned buttons on sensor updates (separate Consumer)

### 2. Stack Layout Performance
**Challenge**: Stack with Positioned widgets can be expensive if overused.

**Solution**:
- Limit to 4-6 positioned buttons per screen
- Use RepaintBoundary for positioned buttons
- Profile with Flutter DevTools to identify bottlenecks

### 3. Map Rendering
**Challenge**: CustomPainter redraws entire map on pan/zoom/rotate.

**Solution**:
- Use `shouldRepaint` to skip unnecessary repaints
- Cache computed points when survey data unchanged
- Use Transform instead of re-painting for pan/zoom (if possible)
- Profile with DevTools to optimize

### 4. Timer Cleanup
**Challenge**: Long-press timers could leak if not cleaned up.

**Solution**:
- Always cancel timers in onTapUp and onTapCancel
- Cancel timers in Widget.dispose()
- Use StatefulWidget lifecycle properly
- Test for timer leaks (check Task Manager for background timers)

## Accessibility Considerations

### 1. Semantic Labels
- Add Semantics widget to custom buttons with proper labels
- Example: `Semantics(label: 'Save survey point', child: CircularActionButton(...))`

### 2. Contrast
- Ensure text/icon colors have sufficient contrast with backgrounds
- All buttons use white icons on colored backgrounds (high contrast)

### 3. Touch Target Size
- Minimum button size: 48x48 logical pixels (per Material Design)
- Default button sizes: 90px (optimized for underwater glove use)
- Customization slider range: 40-200px
- Tap target automatically expands to minimum 48x48px even for smaller buttons
- 30px movement tolerance (slop) for glove-friendly tap detection

### 4. Screen Reader Support
- Add semantic labels to all interactive elements
- Test with iOS VoiceOver and Android TalkBack
- Ensure navigation flows are logical

## Testing Strategy

### Unit Tests
- ButtonConfig model serialization/deserialization
- ButtonCustomizationService state updates
- Theme color/style constants

### Widget Tests
- CircularActionButton rendering
- PositionedButton positioning calculations
- MonospacedText font features
- InfoCard styling

### Integration Tests
- End-to-end button customization flow
- Tap vs long-press gesture handling
- Navigation flows (main → save data → settings → customization)
- Map gestures (pan, zoom, rotate)

### Manual Tests
- Visual comparison with Swift app screenshots
- Cross-platform testing (iOS vs Android)
- Different screen sizes (phone, tablet)
- Real device testing with sensors

## Migration Path

### Stage 1: Foundation
Set up theme, models, and services. No UI changes yet.

### Stage 2: Main Screen
Redesign main screen with new layout. Most visible change.

### Stage 3: Other Screens
Update save data, settings, map screens one by one.

### Stage 4: Polish
Refine interactions, animations, and visual details.

### Stage 5: Testing
Comprehensive testing and bug fixes.

## Rollback Plan

If issues arise during migration:
1. Keep backup files (*_old.dart) until migration complete
2. Use git branches for each phase
3. Can revert to previous UI if critical issues found
4. Button customization can be disabled (use default positions)

## Future Enhancements

After initial migration complete:
1. **Button rotation**: Allow angled button placement
2. **Preset layouts**: Pre-defined button arrangements (left-handed, right-handed)
3. **Import/export layouts**: Share button configurations between devices
4. **Visual theme editor**: Customize colors beyond buttons
5. **Animation**: Smooth transitions when switching parameters or screens
6. **Haptic feedback**: Vibration on button press (underwater feedback)

## Conclusion

This design provides a solid foundation for migrating the Swift UI to Flutter while maintaining visual and functional consistency. The architecture decisions prioritize simplicity, maintainability, and performance while adapting to Flutter's patterns and best practices.

Key principles:
- **Consistency**: Use same patterns across all screens
- **Simplicity**: Choose simple solutions over complex when possible
- **Performance**: Profile and optimize based on real measurements
- **Testability**: Write tests for critical paths
- **Maintainability**: Clear code structure and documentation
