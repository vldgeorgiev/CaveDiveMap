## 1. Interaction Model
- [x] 1.1 Define shared underwater touch-filter parameters (stable-press, drift tolerance, cooldown, pointer lock) and action profiles (`singleTap`, `pressAndRepeat`, `holdToConfirm`).
- [x] 1.2 Implement a shared hardened in-dive control widget/API so Main, Save Data, and Map overlay controls use the same touch behavior.

## 2. Button Type and Layout
- [x] 2.1 Apply a single global rounded-rectangle paddle shape to all in-dive controls.
- [x] 2.2 Migrate in-dive controls to the shared widget and preserve existing action semantics (including 6s reset hold and +/- repeat behavior).
- [x] 2.3 Prevent map canvas gestures from firing when an overlay control is being touched.

## 3. Customization Safety
- [x] 3.1 Enforce underwater-safe constraints in customization: min size `72px`, max size `150px`, min spacing `12px`, no overlap.
- [x] 3.2 Add load-time migration/sanitization for saved button configs that violate new constraints.

## 4. Validation
- [x] 4.1 Add widget tests for touch filtering: phantom short touch ignored, minor drift accepted, excessive drift canceled, cooldown blocks bounce taps.
- [x] 4.2 Add widget tests for customization constraints and migration clamping/overlap handling.
- [x] 4.3 Add map interaction tests confirming overlay control touches do not pan/zoom the map.
- [x] 4.4 Run `flutter test` and record results for the new interaction tests.
