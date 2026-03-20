## Context
Underwater interaction in gloves introduces two failure modes not common in dry use:
1. phantom/duplicate touches from water pressure and capacitive noise,
2. small involuntary pointer drift while a user intends to press one control.

Current implementation already includes movement slop in `UnderwaterActionButton`, but touch hardening is not consistent across in-dive screens. Main/Save Data controls and Map overlay controls use different interaction code paths, and customization can still create controls that are too small or too close.

## Goals / Non-Goals
- Goals:
- Reduce accidental activations from noisy touches.
- Keep intentional taps fast and reliable while allowing small movement.
- Standardize touch behavior across Main, Save Data, and Map overlay controls.
- Keep user customization but enforce safe underwater layout limits.
- Non-Goals:
- Full visual redesign of non-dive screens.
- Platform-level touch-driver changes.
- Changes to magnetometer or map rendering algorithms.

## Decisions
- Decision: Standardize in-dive controls on one hardened interaction primitive.
  Rationale: A single control primitive avoids behavior drift between screens and centralizes tuning for underwater usage.

- Decision: Use rounded-rectangle paddle controls as a global fixed style for in-dive actions.
  Rationale: Paddles provide larger effective hit area and clearer directional boundaries than circles at similar footprint, and a single style reduces configuration complexity underwater.

- Decision: Add an intent-filter state machine before action dispatch.
  Parameters (initial defaults):
  - Stable press threshold: `>= 100ms`
  - Allowed drift while armed: `<= 35px`
  - Post-activation cooldown: `250ms`
  - Pointer policy: ignore secondary pointers while one control is active
  Rationale: This directly addresses ghost taps and jitter without requiring large gesture changes from the diver.

- Decision: Keep specialized action profiles.
  Profiles:
  - `singleTap`: Save/Map/Cycle/Camera/export
  - `pressAndRepeat`: increment/decrement (`initialDelay ~500ms`, `repeat ~100-150ms`)
  - `holdToConfirm`: Reset (`6s` with progress feedback)
  Rationale: High-frequency and destructive actions need different safety/latency tradeoffs.

- Decision: Enforce safe customization constraints.
  Rules:
  - Minimum button size for in-dive controls: `72px`
  - Maximum button size unchanged (`150px`)
  - Minimum spacing between control bounds: `12px`
  - No overlap allowed when dragging or loading saved layouts
  Rationale: Prevents user-defined layouts that are difficult to operate with gloves.

- Decision: Prevent map canvas gesture handling while touching overlay controls.
  Rationale: Avoids accidental map pan/zoom when user targets export or mode controls.

## Alternatives Considered
- Alternative: Keep circles and only increase slop tolerance.
  Rejected because this does not address ghost repeats, multi-pointer noise, or tiny/overlapping customized layouts.

- Alternative: Disable all customization and hardcode control positions.
  Rejected because case hardware differs by device and customization is necessary for real-world underwater mounting.

- Alternative: Require long-hold for all actions.
  Rejected because it would slow normal operation too much during active surveying.

## Risks / Trade-offs
- Added activation filtering may slightly increase tap latency; initial thresholds are intentionally conservative and should be tuneable.
- Layout sanitization for existing saved configurations can move controls from prior positions; migration messaging should explain this.
- Enforcing one control shape removes a customization option and may affect users who prefer legacy round controls.

## Migration Plan
1. Add load-time sanitization for saved button configs.
2. Clamp any size below `72px` up to `72px`.
3. Resolve overlaps deterministically (preserve highest-priority controls, move others to nearest valid position).
4. Persist sanitized configs immediately after load.

## Open Questions
- Should we expose touch-filter tuning in settings or keep values fixed initially?
- Should export actions require additional confirmation while in an active dive session?
