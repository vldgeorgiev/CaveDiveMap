# Button Customization Redesign

## Overview

The button customization interface has been redesigned from a slider-based approach to an intuitive **drag-and-drop visual interface**. This significantly improves the user experience, especially for underwater use with waterproof cases.

## What Changed

### Previous Approach (Slider-Based)
- Selected one button at a time from a dropdown/segmented control
- Adjusted size, X position, and Y position using 3 separate sliders
- Small preview area showing only the selected button
- Required precise numerical adjustments

### New Approach (Drag-and-Drop)

- **Full-screen edit mode** for unrestricted button positioning
- **All 4 buttons visible simultaneously** in the editor
- **Drag any button** across the entire screen to reposition
- **Tap to select** a button for size adjustment
- **Real-time visual feedback** with selection highlights
- **Center crosshair guide** for positioning reference

## Key Features

### 0. Full-Screen Edit Mode

- **Tap the preview area** to enter full-screen editor
- **Entire screen available** for button positioning (no constraints)
- **Exit button** in top-right corner to return to normal view
- **Immersive editing** with minimal UI chrome

### 1. Interactive Preview Area

- Large full-screen preview showing all buttons for current screen
- Background with center crosshair for positioning reference
- All buttons are live and interactive

### 2. Drag-to-Reposition

- Simply drag any button to move it around the screen
- Visual scale animation during drag (10% larger)
- Positions clamped to screen bounds automatically
- Updates saved immediately on drag end

### 3. Tap-to-Select

- Tap any button to select it for size adjustment
- Selected button shows:
  - Bright border highlight (cyan)
  - Label below button with name
- Tap again to deselect

### 4. Size Adjustment

- Size slider only appears in bottom panel when a button is selected
- Shows: "Size: 80" with icon and selected button name
- Real-time updates as slider moves
- Range: 40-150 pixels

### 5. Screen Switching

- Toggle between "Main Screen" and "Save Data" layouts
- Shows 4 different buttons for each screen
- Selection cleared when switching screens

## Files Changed

### New Files
- `lib/widgets/draggable_button_customizer.dart` - Draggable button wrapper widget

### Modified Files
- `lib/screens/button_customization_screen.dart` - Complete redesign of UI
- `openspec/changes/migrate-swift-ui-to-flutter/tasks.md` - Updated task descriptions

## Technical Implementation

### DraggableButtonCustomizer Widget
```dart
// Key features:
- Converts between center-based offsets and absolute screen positions
- Uses GestureDetector for pan and tap detection
- AnimatedScale for visual feedback during drag
- Clamps positions to prevent buttons going off-screen
- Shows selection state with border and label
```

### ButtonCustomizationScreen Layout

```text
┌─────────────────────────────┐
│ Screen Selector             │  (Main Screen / Save Data)
│ Instructions Bar            │  (Tap to enter full-screen)
├─────────────────────────────┤
│                             │
│   Preview Box               │  (Tap to enter full-screen)
│   [Fullscreen Icon]         │
│                             │
├─────────────────────────────┤
│ Size Slider (if selected)   │
│ Reset All to Defaults       │
└─────────────────────────────┘

When in Full-Screen Mode:
┌─────────────────────────────┐
│ [Instructions] [Close]      │  (Top bar, semi-transparent)
│                             │
│                             │
│   All 4 Buttons             │  (Entire screen available)
│   + Crosshair Guide         │  (Drag anywhere!)
│                             │
│                             │
│ [Size Slider] [Button Name] │  (Bottom bar, semi-transparent)
└─────────────────────────────┘
```

## Benefits

### For Users
- **Intuitive**: Drag-and-drop is more natural than numerical sliders
- **Faster**: See all buttons at once, no switching between selections
- **Visual**: Immediate feedback of button positions relative to each other
- **Context-aware**: See actual layout while customizing

### For Underwater Use
- **Easier with thick gloves**: Dragging is easier than precise slider adjustments
- **Better spatial awareness**: See all buttons in context
- **Faster adjustments**: No need to switch between buttons to compare positions
- **Visual reference**: Crosshair helps with symmetrical positioning

## Migration Notes

- All existing button configurations remain compatible
- No data migration needed
- Settings persist in Hive database as before
- Button positions stored as center-based offsets (unchanged)

## Future Enhancements

Possible improvements:
- Snap-to-grid for aligned positioning
- Copy button position to mirror position
- Preset layouts (corners, edges, center)
- Rotation gestures for button arrangement
- Undo/redo for position changes
