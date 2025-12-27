# Tasks: Add Threshold Auto-Calibration

**Change ID**: `add-threshold-auto-calibration`  
**Status**: Completed

## Phase 1: Calibration Service (2-3 days)

### Data Models and State

- [x] Create `CalibrationState` enum (idle, recordingFar, farComplete, readyForClose, recordingClose, closeComplete, calculating, complete, error)
- [x] Create `ThresholdCalibrationService` extending `ChangeNotifier`
- [x] Add calibration state properties (current state, recorded min/max, samples buffer)
- [x] Add current magnitude getter for real-time display
- [x] Add calibration result properties (calculated min/max thresholds)

### Calibration Logic

- [x] Implement `startFarCalibration()` method
  - [x] Start 10-second recording timer
  - [x] Subscribe to magnetometer updates
  - [x] Track maximum magnitude value during far position
  - [x] Store all samples for analysis
- [x] Implement `startCloseCalibration()` method
  - [x] Start 10-second recording timer
  - [x] Continue magnetometer subscription
  - [x] Track minimum magnitude value during close position
  - [x] Store all samples for analysis
- [x] Implement `calculateThresholds()` method
  - [x] Extract max from far samples (stored in recordedMinField)
  - [x] Extract min from close samples (stored in recordedMaxField)
  - [x] Apply percentage-based margins (15% of range, configurable to 25%)
  - [x] Validate separation (min 20 μT)
  - [x] Return calculated thresholds or error
- [x] Implement `cancelCalibration()` method
  - [x] Stop recording timer
  - [x] Unsubscribe from magnetometer
  - [x] Reset state to idle
  - [x] Clear recorded data
- [x] Implement `retry()` method to restart calibration

### Testing

- [x] Manual testing with real hardware (70-800 μT range)
- [x] Verified percentage-based margin calculation
- [x] Tested state transitions including readyForClose intermediate state
- [x] Validated threshold calculation with actual magnetometer data

## Phase 2: UI Components (2-3 days)

### Calibration Screen

- [x] Create `ThresholdCalibrationScreen` stateful widget
- [x] Add screen scaffold with app bar and "Cancel" button
- [x] Implement step indicator UI (Step 1/2)
- [x] Add instruction text display area
  - [x] Far step: "Position the wheel with the magnet as FAR as possible from your phone. Then move your phone in a figure-8 motion."
  - [x] Close step: "Position the wheel with the magnet as CLOSE as possible to your phone. Then move your phone in a figure-8 motion."
- [x] Add real-time magnitude display (large text, center screen, default color)
- [x] Add countdown timer display (10 seconds)
- [x] Add "Start" button for step 1
- [x] Add "Start Step 2" button for manual close calibration start
- [x] Add visual progress indicator (circular progress for countdown)

### Visual Feedback

- [x] Implement magnitude display with border (neutral color)
- [x] Add recording indicator (countdown timer)
- [x] Add completion checkmark for each step
- [x] Add error state display with retry button

### Results Display

- [x] Create result summary screen
- [x] Display detected far value
- [x] Display detected close value
- [x] Display calculated thresholds (min/max)
- [x] Display margin percentage
- [x] Display separation value
- [x] Add "Apply" button to save thresholds
- [x] Add "Retry" button to start over
- [x] Show validation error if separation insufficient
- [x] Optimized spacing to avoid scrolling (16px padding, smaller fonts/icons)

## Phase 3: Integration (1-2 days)

### Settings Screen Integration

- [x] Add "Calibrate Thresholds" button in settings
- [x] Show button only when `rotationAlgorithm == RotationAlgorithm.threshold`
- [x] Add helper text explaining calibration
- [x] Add navigation to `ThresholdCalibrationScreen` on button press

### Service Integration

- [x] Register `ThresholdCalibrationService` as ChangeNotifierProxyProvider in main.dart
- [x] Connect calibration service to `MagnetometerService` for uncalibrated magnitude data
- [x] Implement threshold application:
  - [x] Call `settings.updateMinPeakThreshold(calculatedMin)`
  - [x] Call `settings.updateMaxPeakThreshold(calculatedMax)`
  - [x] Save settings via `StorageService`
- [x] Handle magnetometer service state
  - [x] Use uncalibrated magnetometer values during calibration
  - [x] Magnitude updates via Provider pattern

### User Flow

- [x] Implement navigation flow: Settings → Calibration → Results → Settings
- [x] Add cancel button in app bar
- [x] Handle back button during calibration (returns to settings)
- [x] Return to settings with success snackbar after applying thresholds
- [x] Two-step manual start (readyForClose state between steps)

## Phase 4: Documentation and Polish (1 day)

### Documentation

- [x] Update proposal.md with percentage-based margin approach
- [x] Document calibration algorithm in service code comments
- [x] Update example calculations in proposal

### UI Polish

- [x] Refine instruction text for clarity (removed wheel rotation during fig-8)
- [x] Improve error messages (clear, actionable)
- [x] Optimize spacing to fit on screen without scrolling
- [x] Remove color-coding from magnitude display (neutral colors)
- [x] Reduced font sizes and padding for compact layout

### Code Quality

- [x] Add comprehensive code comments
- [x] Ensure consistent error handling
- [x] Add logging for debugging calibration issues
- [x] Run `flutter analyze` (no errors, 90 pre-existing warnings)
- [x] Test on real hardware with actual magnetometer readings

---

**Total Estimated Tasks**: 57  
**Completed**: 57  
**Remaining**: 0

## Implementation Notes

### Key Decisions Made During Implementation

1. **Percentage-Based Margins**: Changed from fixed 10 μT to 15% of range (user tested with 25%)
   - Better scaling for different signal strengths
   - Accounts for sensor delay with large values
   
2. **Variable Naming**: Counter-intuitive but documented
   - `recordedMinField` stores MAX value from far position
   - `recordedMaxField` stores MIN value from close position
   - Named for final threshold calculation, not recording phase
   
3. **Manual Step 2 Start**: Added `readyForClose` state
   - Prevents auto-start of close calibration
   - Gives user time to position magnet correctly
   
4. **UI Optimization**: Multiple iterations to fit without scrolling
   - Padding: 24→16px
   - Icon size: 64→48px
   - Font sizes reduced across board
   - Spacing between elements minimized

5. **Uncalibrated Magnetometer**: Uses raw sensor values
   - More accurate for threshold detection
   - Avoids calibration-on-calibration issues

### Testing Results

- Real hardware test with magnet wheel:
  - Far position: ~70 μT
  - Close position: ~800 μT
  - Range: 730 μT
  - With 25% margin: 252.5 μT min, 617.5 μT max
  - Provides adequate buffer for sensor delay
