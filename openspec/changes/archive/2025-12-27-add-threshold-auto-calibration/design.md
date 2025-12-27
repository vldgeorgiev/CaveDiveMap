# Design: Threshold Auto-Calibration

**Change ID**: `add-threshold-auto-calibration`

## Architecture Overview

The auto-calibration feature consists of three main components:

```
┌─────────────────────────┐
│  SettingsScreen         │
│  - Calibrate button     │
│  - Shows only in        │
│    threshold mode       │
└───────────┬─────────────┘
            │ navigates to
            ↓
┌─────────────────────────────────────────┐
│  ThresholdCalibrationScreen             │
│  - Step 1: Far position recording       │
│  - Step 2: Close position recording     │
│  - Real-time magnitude display          │
│  - Result display & apply               │
└───────────┬─────────────────────────────┘
            │ uses
            ↓
┌─────────────────────────────────────────┐
│  ThresholdCalibrationService            │
│  - State machine                        │
│  - Magnitude recording                  │
│  - Threshold calculation                │
└───────────┬─────────────────────────────┘
            │ reads from
            ↓
┌─────────────────────────────────────────┐
│  MagnetometerService                    │
│  - Provides magnitude stream            │
└─────────────────────────────────────────┘
```

## State Machine

```
                    startFarCalibration()
    IDLE ────────────────────────────────────→ RECORDING_FAR
     ↑                                              │
     │                                              │ Timer completes (10s)
     │                                              ↓
     │                                         FAR_COMPLETE
     │                                              │
     │                                              │ startCloseCalibration()
     │                                              ↓
     │ cancel()                              RECORDING_CLOSE
     │ at any time                                  │
     │                                              │ Timer completes (10s)
     │                                              ↓
     │                                        CLOSE_COMPLETE
     │                                              │
     │                                              │ calculateThresholds()
     │                                              ↓
     │                                         CALCULATING
     │                                              │
     │                                              ├─→ ERROR (insufficient separation)
     │                                              │      │
     │                                              │      │ retry()
     │                                              │      └─────→ IDLE
     │                                              │
     │                                              ↓
     └────────── applyThresholds() ───────── COMPLETE
```

## Data Flow

### Recording Phase

```
MagnetometerService (50Hz)
  │
  │ magnitude updates
  ↓
ThresholdCalibrationService
  │
  ├─→ Update _currentMagnitude (for UI display)
  │
  ├─→ Add to _calibrationSamples list
  │
  └─→ Track min/max values
       - In RECORDING_FAR: update _recordedMax
       - In RECORDING_CLOSE: update _recordedMin
```

### Calculation Phase

```
ThresholdCalibrationService.calculateThresholds()
  │
  ├─→ Extract maxField from _recordedMax (far samples)
  │
  ├─→ Extract minField from _recordedMin (close samples)
  │
  ├─→ Calculate:
  │    calculatedMin = minField + safetyMargin (10 μT)
  │    calculatedMax = maxField - safetyMargin (10 μT)
  │
  ├─→ Validate:
  │    separation = calculatedMax - calculatedMin
  │    if separation < 40 μT → ERROR
  │
  └─→ Return {calculatedMin, calculatedMax}
```

## Service API

### ThresholdCalibrationService

```dart
class ThresholdCalibrationService extends ChangeNotifier {
  // State
  CalibrationState get state;
  double get currentMagnitude;
  double get recordedMaxField;
  double get recordedMinField;
  double get calculatedMinThreshold;
  double get calculatedMaxThreshold;
  int get recordingTimeRemaining; // seconds
  String? get errorMessage;

  // Actions
  void startFarCalibration();
  void startCloseCalibration();
  void calculateThresholds();
  void applyThresholds(Settings settings, StorageService storage);
  void cancel();
  void reset();
  void retry();
}

enum CalibrationState {
  idle,
  recordingFar,
  farComplete,
  recordingClose,
  closeComplete,
  calculating,
  complete,
  error,
}
```

## UI Components

### ThresholdCalibrationScreen Layout

```
┌─────────────────────────────────────────┐
│  AppBar                                 │
│  "Threshold Calibration"     [Cancel]   │
├─────────────────────────────────────────┤
│                                         │
│  Step Indicator                         │
│  [●]─────[○]                           │
│  Step 1     Step 2                      │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Instructions                     │ │
│  │                                   │ │
│  │  Rotate wheel with magnet as FAR  │ │
│  │  as possible from phone.          │ │
│  │                                   │ │
│  │  Move phone in figure-8 motion    │ │
│  │  while rotating the wheel.        │ │
│  └───────────────────────────────────┘ │
│                                         │
│         ┌─────────────────┐            │
│         │   Magnitude     │            │
│         │    125.4 μT     │ (large)    │
│         └─────────────────┘            │
│                                         │
│  ══════════════════ (progress bar)     │
│         8 seconds                       │
│                                         │
│     [Start Recording] (or countdown)    │
│                                         │
│            [Next] (disabled)            │
│                                         │
└─────────────────────────────────────────┘
```

### Result Screen Layout

```
┌─────────────────────────────────────────┐
│  AppBar                                 │
│  "Calibration Results"       [Close]    │
├─────────────────────────────────────────┤
│                                         │
│  ✓ Calibration Complete                │
│                                         │
│  Detected Values:                       │
│  ┌───────────────────────────────────┐ │
│  │ Far Position:      200.5 μT      │ │
│  │ Close Position:    120.3 μT      │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Calculated Thresholds:                 │
│  ┌───────────────────────────────────┐ │
│  │ Min Threshold:     130.3 μT      │ │
│  │ Max Threshold:     190.5 μT      │ │
│  │                                   │ │
│  │ Safety Margin:     10.0 μT       │ │
│  │ Separation:        60.2 μT  ✓    │ │
│  └───────────────────────────────────┘ │
│                                         │
│              [Apply]                    │
│              [Retry]                    │
│                                         │
└─────────────────────────────────────────┘
```

## Algorithm Details

### Safety Margin Rationale

The 10 μT safety margin serves multiple purposes:

1. **Noise Buffer**: Prevents threshold triggers from magnetic field fluctuations
2. **Edge Hysteresis**: Ensures clean state transitions (far ↔ close)
3. **Device Variation**: Accommodates different magnetometer sensitivities
4. **Motion Tolerance**: Allows for imperfect figure-8 motion

### Minimum Separation Requirement

`minSeparation = 40 μT = 2 × (2 × safetyMargin)`

This ensures:
- At least 20 μT between min threshold and detected close position
- At least 20 μT between max threshold and detected far position
- Adequate range for reliable peak detection

### Sample Collection

**Recording Duration**: 10 seconds
**Sample Rate**: 50 Hz (from magnetometer)
**Expected Samples**: ~500 samples per recording step

**Why 10 seconds?**
- Allows multiple wheel rotations (typically 3-5)
- Captures various phone orientations during figure-8
- Long enough for reliable max/min detection
- Short enough to maintain user engagement

### Figure-8 Motion Importance

The figure-8 motion ensures:
1. Multiple orientations of phone relative to Earth's magnetic field
2. Consistent rotation plane detection regardless of phone orientation
3. Captures peak magnitude at various angles
4. Simulates real-world usage conditions

## Error Handling

### Insufficient Separation Error

**Condition**: `calculatedMax - calculatedMin < 40 μT`

**Causes**:
- Magnet not moved far enough between steps
- Magnet too weak
- Magnetometer malfunction

**User Action**:
- Retry calibration
- Ensure greater distance difference (far: 30cm+, close: <10cm)
- Check magnet is properly attached to wheel

### Inverted Values Error

**Condition**: `minField > maxField`

**Causes**:
- User confused far/close steps
- Magnet moved during recording

**User Action**:
- Retry calibration
- Follow instructions carefully
- Keep magnet position stable during each recording

### Timeout Error

**Condition**: No magnetometer updates for >5 seconds during recording

**Causes**:
- Magnetometer service stopped
- Sensor permission denied
- Device malfunction

**User Action**:
- Check sensor permissions
- Restart app
- Try different device

## Performance Considerations

### Memory Usage

- `_calibrationSamples` list: ~500 samples × 8 bytes × 2 steps = ~8 KB
- Cleared after calculation to free memory
- Negligible impact on overall app memory footprint

### CPU Usage

- Magnitude calculation: Already performed by MagnetometerService
- Min/max tracking: O(1) per sample
- Calculation phase: O(n) where n = sample count (~1000), negligible

### UI Responsiveness

- Magnitude display throttled to 10 Hz (update every 100ms)
- Countdown timer updates at 1 Hz
- Prevents UI stutter from 50 Hz updates

## Testing Strategy

### Unit Tests

```dart
test('calculateThresholds with valid separation', () {
  final service = ThresholdCalibrationService();
  service._recordedMax = 200.0;
  service._recordedMin = 120.0;
  service.calculateThresholds();
  expect(service.calculatedMinThreshold, 130.0);
  expect(service.calculatedMaxThreshold, 190.0);
  expect(service.state, CalibrationState.complete);
});

test('calculateThresholds with insufficient separation', () {
  final service = ThresholdCalibrationService();
  service._recordedMax = 150.0;
  service._recordedMin = 140.0;
  service.calculateThresholds();
  expect(service.state, CalibrationState.error);
  expect(service.errorMessage, contains('Insufficient separation'));
});
```

### Integration Tests

```dart
testWidgets('complete calibration flow', (tester) async {
  await tester.pumpWidget(TestApp());
  
  // Navigate to calibration
  await tester.tap(find.text('Calibrate Thresholds'));
  await tester.pumpAndSettle();
  
  // Step 1: Far
  await tester.tap(find.text('Start Recording'));
  await tester.pump(Duration(seconds: 10));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  
  // Step 2: Close
  await tester.tap(find.text('Start Recording'));
  await tester.pump(Duration(seconds: 10));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  
  // Apply
  await tester.tap(find.text('Apply'));
  await tester.pumpAndSettle();
  
  // Verify settings updated
  final settings = getSettings();
  expect(settings.minPeakThreshold, greaterThan(0));
  expect(settings.maxPeakThreshold, greaterThan(settings.minPeakThreshold));
});
```

### Manual Testing Checklist

- [ ] Far position: magnet 30cm away, 10 rotations during recording
- [ ] Close position: magnet 5cm away, 10 rotations during recording
- [ ] Verify calculated thresholds are reasonable (min < max, separation > 40)
- [ ] Apply thresholds and test actual rotation detection
- [ ] Cancel calibration mid-way, verify no changes to settings
- [ ] Retry after insufficient separation error
- [ ] Test on both iOS and Android
- [ ] Test with different magnet strengths (if available)

## Future Enhancements

### Calibration Quality Score

```dart
double calculateQualityScore() {
  final separation = recordedMaxField - recordedMinField;
  final sampleVariance = calculateVariance(calibrationSamples);
  final coverageScore = figureEightCoverage(); // detect if full range covered
  
  return (separation / 100.0) * (1.0 - sampleVariance) * coverageScore;
}
```

Display quality as:
- 🟢 Excellent (>0.8)
- 🟡 Good (0.6-0.8)
- 🟠 Fair (0.4-0.6)
- 🔴 Poor (<0.4, suggest retry)

### Adaptive Safety Margin

Instead of fixed 10 μT, calculate margin as percentage:

```dart
final adaptiveMargin = (recordedMaxField - recordedMinField) * 0.1; // 10%
calculatedMin = recordedMinField + adaptiveMargin;
calculatedMax = recordedMaxField - adaptiveMargin;
```

Pros: Scales with actual field range
Cons: More complex, may be less predictable

### Calibration History

Store last 5 calibrations in local storage:

```dart
class CalibrationHistory {
  DateTime timestamp;
  double minThreshold;
  double maxThreshold;
  double qualityScore;
}
```

Use for:
- Trend analysis (magnetometer drift detection)
- Automatic re-calibration suggestions
- Debugging user issues

## Open Implementation Questions

1. **Recording Start Behavior**
   - Option A: Auto-start recording when step is entered (10 second countdown immediately)
   - Option B: User must press "Start Recording" button explicitly
   - **Recommendation**: Option B for user control and preparation

2. **Magnitude Display Precision**
   - 1 decimal place: `125.4 μT`
   - 2 decimal places: `125.43 μT`
   - Integer: `125 μT`
   - **Recommendation**: 1 decimal place for balance of precision and readability

3. **Result Screen Auto-dismiss**
   - Auto-navigate back to settings after successful apply
   - Require user to manually close result screen
   - **Recommendation**: Manual close to allow user to review results

4. **Calibration Reminder**
   - Show reminder if thresholds never calibrated after X days
   - No automatic reminders
   - **Recommendation**: No reminders for V1, add telemetry first

5. **Cancel Confirmation**
   - Always show confirmation dialog
   - Only show if recording has started
   - **Recommendation**: Only show if past IDLE state to avoid annoying users
