# Change: Harden Underwater Touch Controls

## Why
The app is used underwater with gloves and a waterproof case, where touch jitter and phantom contact are common. Current controls include some movement tolerance, but interaction behavior is inconsistent across screens and still allows accidental activations.

## Current Findings
- Main and Save Data controls use a custom in-dive action widget (`UnderwaterActionButton`) with legacy touch filtering defaults that required further hardening.
- Button customization currently allows very small controls (`40px`) and free placement without overlap/spacing guards.
- Map overlay controls (view toggle and export actions) use direct `GestureDetector` taps and do not share the same touch hardening logic.
- Safety behavior is uneven: reset uses long-hold confirmation, while other high-frequency actions can still trigger from noisy contact.

## What Changes
- Add a new underwater touch-controls capability and standardize in-dive controls (Main, Save Data, Map overlay) on one hardened interaction model.
- Use a single global high-area rounded-rectangle paddle shape for in-dive controls.
- Add touch-noise filtering for in-dive controls:
- Stable-press threshold before activation.
- Drift tolerance for small movement while pressed.
- Single-pointer lock while a control is active.
- Post-activation debounce cooldown to suppress bounce/ghost repeats.
- Preserve and strengthen hold-based interactions for critical or repeat actions (`Reset`, `+/-`).
- Enforce underwater-safe customization constraints (minimum size, minimum spacing, and no overlap).
- Migrate existing saved button layouts by clamping undersized controls to the new minimum at load time.

## Impact
- Affected specs: `underwater-touch-controls` (new capability)
- Affected code (planned):
- `flutter-app/lib/widgets/underwater_action_button.dart`
- `flutter-app/lib/widgets/positioned_button.dart`
- `flutter-app/lib/widgets/draggable_button_customizer.dart`
- `flutter-app/lib/screens/main_screen.dart`
- `flutter-app/lib/screens/save_data_screen.dart`
- `flutter-app/lib/screens/map_screen.dart`
- `flutter-app/lib/screens/button_customization_screen.dart`
- `flutter-app/lib/services/button_customization_service.dart`
- `flutter-app/lib/models/button_config.dart`
- Validation impact: add widget/interaction tests for jitter handling, ghost-touch suppression, and customization layout constraints.
