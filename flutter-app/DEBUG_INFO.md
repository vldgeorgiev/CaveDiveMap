# PCA Rotation Detection - Debug Information (Updated)

## Critical Issues Found

Based on your logs, I've identified several problems:

1. **Recording not starting properly** - Despite calling startRecording(), state stays in "listening only"
2. **Planarity consistently too low** - Even while rotating with magnet, planarity is 0.013-0.615 (need >0.3)
3. **Rotation count oscillating** - Going backward/forward (15→14→15→16→17→16...) instead of incrementing
4. **False positives** - Detecting rotations when phone is stationary without wheel

## New Debug Build

I've added much more detailed logging to diagnose these issues:

### Main Screen Initialization
```
[MAIN_SCREEN] initState called
[MAIN_SCREEN] PostFrameCallback executing
[MAIN_SCREEN] Algorithm set to: RotationAlgorithm.pca
[MAIN_SCREEN] Called startRecording()
```

### Service State Tracking
```
[MAG] startRecording() called | _isRecording=false | _isListening=true
[MAG] 🔴 Started recording | Algorithm: RotationAlgorithm.pca | Initial distance: 0.00 m
[MAG] 🔄 PCA detector reset
[MAG] startRecording() complete | _isRecording=true
```

### Enhanced PCA Metrics (every 50 samples)
```
[PCA] Quality: 68.7% | Planarity: 0.412 (✓) | Signal: 15.32 μT² (✓) | Valid: ✓ | Rotations: 0
[PCA-EIGENVALUES] λ1=15.32 λ2=8.45 λ3=2.11 | Ratio: λ2/λ1=0.551 | Baseline: (23.1, -5.4, 42.3) μT | Window: 100/100 samples
```

**What these mean:**

- **λ1, λ2, λ3**: Eigenvalues (variance along each principal component)
  - λ1: Largest variance (rotation plane's major axis)
  - λ2: Medium variance (rotation plane's minor axis)
  - λ3: Smallest variance (perpendicular to rotation plane)
  
- **Ratio λ2/λ1**: How circular vs elliptical the rotation is
  - 1.0 = perfect circle
  - 0.5 = ellipse (major axis 2x minor axis)
  - <0.1 = very elongated (might be linear motion, not rotation)

- **Planarity**: (λ2-λ3)/λ1 - measures how 2D the data is
  - High planarity (>0.3): Data lies in clear 2D plane = good for rotation
  - Low planarity (<0.3): Data is 3D/spherical = bad, PCA can't find rotation plane

- **Baseline**: Earth's magnetic field that's subtracted from readings
  - Should be fairly stable (~25-65 μT total magnitude)
  - If drifting rapidly, baseline removal might be too fast/slow

- **Window fill**: How many samples in sliding window
  - Should show "100/100" when full (1 second @ 100Hz)
  - If not full, PCA won't run

## What Your Logs Revealed

### Problem 1: Not Recording
Your logs show `[MAG] ⚠️ PCA rotation detected but not recording (listening only)` for ALL rotations. This means `_isRecording=false` even though startRecording() was supposedly called. The new logging will show exactly where this is failing.

### Problem 2: Very Low Planarity
Even while rotating with strong magnet (254-1291 μT²), your planarity was terrible:
- Stationary: 0.012-0.466 (expected - no rotation plane)
- With wheel not rotating: 0.003-0.671 (expected - no motion)
- **While rotating**: 0.013-0.615 (TOO LOW! Should be >0.3 consistently)

This suggests one of:
1. **Magnet motion not truly planar** - You might be moving the wheel in/out, not just rotating
2. **Phone orientation changing** - If phone is moving, this corrupts the rotation plane
3. **Baseline removal too aggressive** - Removing too much signal variation
4. **Window too short** - 1 second might not capture enough rotation cycles
5. **Magnet too close** - Saturating the sensor, creating non-linear distortion

### Problem 3: Rotation Count Oscillating
Going 15→14→15→16→17→16 means the phase unwrapper is seeing phase jump around. The unwrapped phase should only increase (or only decrease), never both. Your logs show:
```
Unwrapped: 6437.7°
Unwrapped: 6116.8°  (decreased by 320°!)
```

This is impossible for a real rotation. It means:
1. Phase measurements are wildly inconsistent (planarity too low)
2. Validity gates let bad data through occasionally
3. Phase unwrapper sees false 360° cycles from noise

## What to Test Now

**Install new debug APK:**
```bash
adb install -r /Users/vladimir/Projects/CaveDiveMap/flutter-app/build/app/outputs/flutter-apk/app-debug.apk
```

**Run with full logging:**
```bash
adb logcat | grep -E "\[PCA\]|\[MAG\]|\[MAIN_SCREEN\]"
```

### Test 1: Verify Recording Starts
**Expected output when you open main screen:**
```
[MAIN_SCREEN] initState called
[MAIN_SCREEN] PostFrameCallback executing
[MAIN_SCREEN] Algorithm set to: RotationAlgorithm.pca
[MAG] startRecording() called | _isRecording=false | _isListening=false
[MAG] Not listening, calling startListening()
[MAG] 🎧 Started listening | Algorithm: RotationAlgorithm.pca
[MAG] 🔧 PCA detector initialized and started
[MAG] 🔴 Started recording | Algorithm: RotationAlgorithm.pca | Initial distance: 0.00 m
[MAG] 🔄 PCA detector reset
[MAG] startRecording() complete | _isRecording=true
```

**If you still see "listening only" warnings, capture the exact startup sequence.**

### Test 2: Analyze Eigenvalues During Rotation
While rotating the wheel, watch for the `[PCA-EIGENVALUES]` lines. You should see:

**Good rotation pattern:**
- λ1: Large and varying (10-500 μT²) as magnet passes
- λ2: Medium, should be >30% of λ1 (ratio >0.3)
- λ3: Small, should be <10% of λ1
- Planarity: (λ2-λ3)/λ1 should be >0.3

**Bad pattern (what you're seeing):**
- λ3 too close to λ2 → data is 3D blob, not 2D plane
- λ2 too close to λ1 → data is linear, not circular
- Baseline jumping around → drift removal failing

### Test 3: Check Baseline Stability
Watch the "Baseline" values in `[PCA-EIGENVALUES]` lines:
- Should be relatively stable (±5 μT changes)
- Typical Earth's field: 25-65 μT magnitude
- If jumping >20 μT between samples, baseline removal is broken

## Likely Root Cause

Based on your logs, **the planarity is just too low**. The PCA algorithm is designed for the case where:
1. Magnet moves in a perfect circle around sensor
2. Phone stays completely stationary
3. Magnetic field traces clean 2D ellipse in sensor frame

But your physical setup might have:
1. Wheel wobbling (magnet moves in/out, not just around)
2. Phone slightly moving/vibrating
3. Magnet path not truly circular

**The 0.3 planarity threshold might be too strict for your physical setup.**

## Potential Fixes

If the new logs confirm planarity is always <0.3 during rotation, we have options:

### Option A: Lower Planarity Threshold
Change from 0.3 → 0.15 (accept more 3D motion)

### Option B: Use Different Algorithm
The old threshold algorithm might work better if magnet motion isn't planar

### Option C: Improve Physical Setup
- Mount phone more rigidly
- Ensure wheel spins in perfect plane perpendicular to sensor
- Use stronger magnet to increase λ1 (more signal, higher planarity ratio)

### Option D: Use Magnitude + PCA Hybrid
Use magnitude for detection, PCA only for orientation independence

## What to Send Me

1. **Complete startup log** from app launch through main screen appearing
2. **One full rotation cycle log** showing all PCA-EIGENVALUES during wheel rotation
3. **Your physical setup**:
   - How is phone mounted?
   - What's the magnet size/strength?
   - Does wheel have any wobble?
   - Distance from magnet to sensor?

This will help determine if we need to fix the algorithm or the hardware setup!
- **Quality**: Should be >30% when magnet is near sensor
  - Poor (<30%): Red - magnet too far or data quality issues
  - Fair (30-50%): Orange - marginal signal
  - Good (50-70%): Blue - acceptable
  - Excellent (>70%): Green - ideal conditions

- **Planarity**: Ratio showing how 2D the rotation is (0.0-1.0)
  - ✓ = Pass (>0.3), ✗ = Fail (<0.3)
  - Lower values mean data is more 3D/spherical (bad)
  - Higher values mean data lies in a plane (good)

- **Signal**: Magnetic field strength in μT²
  - ✓ = Pass (>5.0 μT²), ✗ = Fail (<5.0 μT²)
  - Typical Earth's field: ~25-65 μT
  - With magnet nearby: should see much higher values

- **Valid**: Overall gate status
  - ✓ = All 4 gates pass, rotation counting active
  - ✗ = At least one gate failed, no rotation counting

- **Rotations**: Current rotation count

### 3. Rotation Detection (appears immediately when detected)
```
[PCA] 🎯 ROTATION DETECTED! Count: 1 (was 0) | Phase: 182.4° | Unwrapped: 362.1°
[MAG] 🎯 Adding 1 rotation(s): 0 -> 1 | Distance: 0.000 -> 0.263 m
```

**What this tells you**:
- Phase wrapped around from ~180° to ~-180° (360° cycle)
- Unwrapped phase accumulated 360° (one full rotation)
- Distance incremented by wheel circumference (0.263m)

### 4. Warning Messages (if something is wrong)
```
[MAG] ⚠️ PCA rotation callback but detector is null
[MAG] ⚠️ PCA rotation detected but not recording (listening only)
```

## UI Debug Panel

On the main screen (when PCA algorithm is selected), you'll see:

```
🔬 PCA Debug
Detector: ✓       <- Should be ✓ when on main screen
Recording: ✓      <- Should be ✓ when on main screen  
PCA Count: 0      <- Rotation count from PCA detector
Svc Count: 0      <- Rotation count from service (should match)
Quality: 45.2%    <- Signal quality percentage
Raw: (12.3, -5.4, 32.1) μT  <- Raw magnetometer readings
📋 See Flutter logs for detailed metrics
```

## Troubleshooting Guide

### Problem: "Detector: ✗" or "Recording: ✗"
**Cause**: Service not starting properly
**Fix**: Navigate away from main screen and back

### Problem: Quality oscillates rapidly (Poor ↔ Excellent every second)
**Cause**: Window buffer filling/emptying or validity gates too sensitive
**Check logs for**: Rapid changes in planarity or signal strength values

### Problem: Quality stable but no rotations detected
**Possible causes**:
1. **Validity gates too strict**: Check log for which gate is failing (✗)
   - Planarity <0.3: Magnet motion not planar enough
   - Signal <5.0 μT²: Magnet too far or too weak
   - Frequency >5 Hz: Rotating too fast (>300 RPM)
   - Phase motion <0.001 rad/sample: Rotating too slowly

2. **Phase unwrapping issue**: Check if unwrapped phase is accumulating
   - Should see unwrapped phase increase continuously during rotation
   - Should reach ~360° for one full rotation

3. **PCA not detecting rotation plane**: Check planarity values
   - If planarity is very low (<0.2), PCA can't find a clear rotation plane

### Problem: False rotations (counting when not rotating)
**Possible causes**:
1. **Phone movement**: Algorithm detecting phone orientation changes
2. **Magnetic interference**: Other magnets or metal nearby
3. **Validity gates too loose**: Need to increase thresholds

## Test Procedure

1. **Install and open app**
   - Should see `[MAG] Started listening` and `[MAG] Started recording` in logs

2. **Go to Settings** (optional, but useful)
   - Change to "PCA Phase Tracking" algorithm
   - Observe quality indicator and validity gate checks

3. **Return to main screen**
   - Debug panel should show "Detector: ✓" and "Recording: ✓"
   - Quality should be stable (not oscillating wildly)

4. **Hold phone steady WITHOUT magnet**
   - Quality should be Poor/Fair (<50%)
   - Validity should mostly be ✗
   - No rotations should be counted
   - Log should show low signal strength (<5 μT²)

5. **Bring magnet near sensor (stationary)**
   - Quality should increase to Good/Excellent (>50%)
   - Signal strength should increase (>10 μT²)
   - Planarity might still be low (not rotating yet)
   - No rotations should be counted yet

6. **Slowly rotate magnet in plane perpendicular to sensor**
   - Quality should stay Good/Excellent
   - Planarity should increase (>0.3)
   - Validity should show ✓
   - After each complete rotation, should see:
     - `[PCA] 🎯 ROTATION DETECTED!` in log
     - Rotation count increment in UI
     - Distance increase by 0.263m

7. **Test orientation independence**
   - Rotate phone 90°
   - Continue rotating magnet
   - Should still detect rotations

## Expected Log Output (Normal Operation)

```
[MAG] 🎧 Started listening | Algorithm: RotationAlgorithm.pca
[MAG] 🔧 PCA detector initialized and started
[MAG] 🔴 Started recording | Algorithm: RotationAlgorithm.pca | Initial distance: 0.00 m
[MAG] 🔄 PCA detector reset
[PCA] Quality: 15.2% | Planarity: 0.112 (✗) | Signal: 2.35 μT² (✗) | Valid: ✗ | Rotations: 0
[PCA] Quality: 18.4% | Planarity: 0.145 (✗) | Signal: 3.12 μT² (✗) | Valid: ✗ | Rotations: 0
... (magnet brought near) ...
[PCA] Quality: 52.3% | Planarity: 0.289 (✗) | Signal: 12.45 μT² (✓) | Valid: ✗ | Rotations: 0
... (start rotating) ...
[PCA] Quality: 68.7% | Planarity: 0.412 (✓) | Signal: 15.32 μT² (✓) | Valid: ✓ | Rotations: 0
[PCA] Quality: 71.2% | Planarity: 0.438 (✓) | Signal: 16.01 μT² (✓) | Valid: ✓ | Rotations: 0
[PCA] 🎯 ROTATION DETECTED! Count: 1 (was 0) | Phase: 182.4° | Unwrapped: 362.1°
[MAG] 🎯 Adding 1 rotation(s): 0 -> 1 | Distance: 0.000 -> 0.263 m
[PCA] Quality: 69.5% | Planarity: 0.425 (✓) | Signal: 15.78 μT² (✓) | Valid: ✓ | Rotations: 1
```

## What to Report Back

Please capture and share:
1. **Full log output** from app launch through several rotation attempts
2. **Screenshots** of:
   - Main screen debug panel
   - Settings screen with PCA selected (showing quality indicator)
3. **Description** of what you're doing (phone stationary, magnet near, rotating, etc.)
4. **Behavior observed**:
   - Is quality stable or oscillating?
   - Are any rotations counted?
   - Which validity gates are passing/failing?

This information will help diagnose exactly where the algorithm is failing!
