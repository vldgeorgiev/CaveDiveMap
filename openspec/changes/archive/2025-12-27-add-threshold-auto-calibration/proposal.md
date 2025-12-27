# Proposal: Add Threshold Auto-Calibration

**Change ID**: `add-threshold-auto-calibration`  
**Type**: Feature Addition  
**Status**: Proposed  
**Created**: 2025-12-26

## Summary

Add an auto-calibration feature for the threshold rotation detection algorithm that guides users through a two-step calibration process to automatically determine optimal min/max magnetic field thresholds. This eliminates the need for manual threshold tuning, improving user experience and detection accuracy.

## Motivation

### Current State Problems

1. **Manual Threshold Configuration**: Users must manually enter min/max thresholds without guidance
2. **Trial and Error**: Finding optimal thresholds requires experimentation and understanding of magnetic field units (μT)
3. **Device Variations**: Different phones and magnet placements require different threshold values
4. **Poor User Experience**: New users struggle to configure thresholds correctly, leading to missed rotations or false positives
5. **No Feedback**: Users don't know if their chosen thresholds are appropriate for their setup

### Benefits of Auto-Calibration

1. **Zero-Knowledge Operation**: Users don't need to understand magnetic field measurements
2. **Guided Process**: Clear step-by-step instructions for calibration
3. **Optimal Thresholds**: Algorithm automatically calculates appropriate values with safety margins
4. **Device-Specific**: Calibration adapts to specific phone magnetometer characteristics
5. **Setup-Specific**: Adapts to magnet strength and wheel positioning
6. **Better Accuracy**: Properly calibrated thresholds reduce false positives and missed detections

### Success Criteria

- [ ] Calibration button visible only when threshold algorithm is selected
- [ ] Two-step calibration process with clear on-screen instructions
- [ ] Records maximum magnetic field magnitude during "far rotation" step
- [ ] Records minimum magnetic field magnitude during "close rotation" step
- [ ] Automatically calculates min/max thresholds with 10 μT safety margins
- [ ] Updates settings with calculated thresholds
- [ ] Calibration results persist across app restarts
- [ ] Calibration can be re-run at any time to adjust for changes

## Scope

### In Scope

- Calibration UI flow in settings screen (threshold mode only)
- Calibration service/logic to track min/max magnetic field values
- Two-step calibration process with user instructions
- Real-time magnetic field display during calibration
- Automatic threshold calculation with safety margins
- Persistence of calibrated thresholds
- Visual feedback during calibration steps
- Cancel/restart calibration capability

### Out of Scope

- Auto-calibration for PCA algorithm (already self-calibrating)
- Background calibration or continuous auto-adjustment
- Machine learning-based calibration
- Multi-magnet calibration
- Historical calibration data tracking
- Calibration sharing between users

### Dependencies

- Existing magnetometer service and threshold detection (REQ-MAG-008, REQ-MAG-009)
- Settings persistence via `StorageService`
- Real-time magnetometer data access

## Technical Approach

### Calibration Algorithm

**Step 1: Far Calibration (Maximum Field)**
1. User rotates wheel with magnet as far as possible from phone
2. User performs figure-8 motion to capture various orientations
3. App records magnetic field magnitude for 5-10 seconds
4. App identifies maximum magnitude value (`maxField`)

**Step 2: Close Calibration (Minimum Field)**
1. User rotates wheel with magnet as close as possible to phone
2. User performs figure-8 motion to capture various orientations
3. App records magnetic field magnitude for 5-10 seconds
4. App identifies minimum magnitude value (`minField`)

**Threshold Calculation**

```dart
range = recordedMinField - recordedMaxField  // far baseline - close peak
margin = range * 0.15  // 15% of range (adaptive to signal strength)
calculatedMin = recordedMaxField + margin
calculatedMax = recordedMinField - margin

// Validation
if (calculatedMax - calculatedMin < 20.0) {
  error: "Insufficient separation between far and close positions"
}
```

**Example**:
- Detected far (baseline max) = 200 μT
- Detected close (peak min) = 800 μT  
- Range = 600 μT, Margin = 90 μT (15%)
- Result: `minThreshold` = 290 μT, `maxThreshold` = 710 μT

### Calibration State Machine

```
IDLE → START_FAR → RECORDING_FAR → START_CLOSE → RECORDING_CLOSE → CALCULATE → COMPLETE
  ↓                                                                              ↓
  ←←←←←←←←←←←←←←←←←←←←←←←←←←←← CANCEL ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

### UI Components

1. **Settings Screen Addition**: "Calibrate Thresholds" button (visible only in threshold mode)
2. **Calibration Dialog/Screen**: Full-screen modal with:
   - Step indicator (Step 1/2)
   - Instruction text
   - Real-time magnetic field magnitude display
   - Progress indicator (5-10 second countdown)
   - "Next" / "Cancel" buttons
   - Visual feedback (color-coded magnitude bar)

### Data Model Updates

**Settings Model** (no changes needed - uses existing `minPeakThreshold` and `maxPeakThreshold`)

**New Calibration Service**:
```dart
class ThresholdCalibrationService extends ChangeNotifier {
  CalibrationState _state;
  double _currentMagnitude;
  double _recordedMin;
  double _recordedMax;
  List<double> _calibrationSamples;
  Timer? _recordingTimer;
}
```

### Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| User confusion during calibration | Medium | Clear step-by-step instructions with illustrations |
| Insufficient field separation | Medium | Validation check, error message with retry option |
| Accidental calibration cancellation | Low | Confirmation dialog before canceling |
| Poor phone orientation during figure-8 | Medium | Instructions emphasize importance, accept wide range |
| Magnetic interference during calibration | Low | Retry capability, recommend clear environment |

## Implementation Plan

See `tasks.md` for detailed task breakdown.

**Estimated Timeline**: 1 week

- Phase 1 (2-3 days): Calibration service and state machine
- Phase 2 (2-3 days): UI components and dialog flow
- Phase 3 (1-2 days): Integration with settings and magnetometer service
- Phase 4 (1 day): Documentation and polish

## Open Questions

1. **Recording Duration**: Should each step be time-based (e.g., 10 seconds) or sample-based (e.g., 500 samples)?
   - Recommendation: 10 seconds time-based for consistency across devices
   
2. **Safety Margin**: Is 10 μT an appropriate safety margin, or should it be percentage-based?
   - Recommendation: Start with 10 μT, make configurable later if needed
   
3. **Minimum Separation**: What's the minimum acceptable separation between far and close measurements?
   - Recommendation: Require at least 40 μT separation (2 × safetyMargin × 2)

4. **Visual Guidance**: Should we add illustrations/animations to guide the figure-8 motion?
   - Recommendation: Start with text, add visuals in future iteration if users need it

5. **Re-calibration Prompts**: Should the app suggest re-calibration if detection accuracy drops?
   - Recommendation: Out of scope for initial implementation, add later with telemetry

## Alternatives Considered

### Alternative 1: Automatic Background Calibration
- **Description**: Continuously monitor magnetic field and auto-adjust thresholds
- **Pros**: Zero user intervention, always optimal
- **Cons**: Risk of incorrect calibration from random movements, complex to implement
- **Decision**: Manual calibration preferred for reliability and user control

### Alternative 2: Pre-set Threshold Profiles
- **Description**: Provide preset threshold values for common device/magnet combinations
- **Pros**: Quick setup, no calibration needed
- **Cons**: Device variations make presets unreliable, doesn't adapt to user's setup
- **Decision**: Auto-calibration more robust and user-specific

### Alternative 3: Single-Step Calibration
- **Description**: Record full range in one step and derive thresholds
- **Pros**: Faster calibration
- **Cons**: Harder to ensure both extremes are captured, less reliable
- **Decision**: Two-step process more reliable and easier to follow

## Future Enhancements

- Calibration quality indicator (confidence score)
- Historical calibration data and trending
- Automatic re-calibration suggestions based on detection performance
- Visual animations for figure-8 motion guidance
- Calibration profile export/import for sharing optimal settings
- Advanced mode with manual safety margin adjustment
