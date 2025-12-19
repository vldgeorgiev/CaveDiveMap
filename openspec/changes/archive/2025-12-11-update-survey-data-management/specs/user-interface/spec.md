# Capability: User Interface

**Change**: `update-survey-data-management`  
**Capability ID**: `user-interface`  
**Type**: Modified Capability

## MODIFIED Requirements

### Requirement: Reset Button Behavior (REQ-UI-001)

The application SHALL require a 10-second continuous hold on the reset button to trigger data reset, replacing the previous 3-second hold with confirmation dialog.

**Previous**: 3-second hold → confirmation dialog → reset  
**Modified**: 10-second hold → automatic export → reset (no confirmation)

**Priority**: MUST  
**Verification**: Hold reset button for various durations, verify behavior

#### Scenario: Reset requires full 10-second hold

**Given** user is on the main screen  
**When** user presses and holds the reset button for 10 seconds  
**Then** reset operation SHALL be triggered  
**And** CSV export SHALL happen automatically  
**And** survey data SHALL be cleared  
**And** no confirmation dialog SHALL appear

#### Scenario: Early release cancels reset

**Given** user is on the main screen  
**When** user presses and holds the reset button for 5 seconds  
**And** user releases the button  
**Then** reset operation SHALL NOT be triggered  
**And** data SHALL remain unchanged  
**And** brief hint SHALL show: "Hold for 10 seconds to reset"

#### Scenario: Visual feedback during hold

**Given** user is on the main screen  
**When** user presses and holds the reset button  
**Then** visual feedback SHALL indicate hold progress (optional)  
**Or** at minimum, button state SHALL change to show "pressed"  
**And** feedback SHALL continue for full 10-second duration

#### Scenario: Reset completes with success message

**Given** user successfully holds reset for 10 seconds  
**When** reset and export complete  
**Then** success message SHALL display: "Data exported and reset successfully"  
**Or** similar confirmation message  
**And** point counter SHALL reset to 1  
**And** distance counter SHALL reset to 0.0 meters

### Requirement: Reset Success Notification (REQ-UI-002)

The application SHALL display clear success notification after reset completes, indicating both export success and data clearing.

**Previous**: Generic "Data reset successfully" message  
**Modified**: Include export confirmation in message

**Priority**: SHOULD  
**Verification**: Trigger reset, verify notification clarity

#### Scenario: Success notification includes export status

**Given** reset operation completes successfully  
**When** notification is displayed  
**Then** message SHALL mention export completion  
**And** message SHALL mention data clearing  
**And** notification SHALL be visible for at least 3 seconds  
**And** notification SHALL use success color (green)

#### Scenario: Error notification if export fails

**Given** reset operation is triggered  
**And** automatic CSV export fails  
**When** reset completes  
**Then** notification SHALL indicate export failure  
**And** notification SHALL indicate data was still cleared  
**And** notification SHALL use warning color (orange/yellow)

## ADDED Requirements

### Requirement: Survey Data Debug Screen (REQ-UI-003)

The application SHALL provide a debug screen displaying all collected survey data in tabular format for inspection and verification purposes.

**Priority**: SHOULD  
**Verification**: Navigate to debug screen, verify data display

#### Scenario: Access debug screen from settings

**Given** user is on the Settings screen  
**When** user taps "Debug: Survey Data" option  
**Then** system SHALL navigate to Survey Data Debug Screen  
**And** screen SHALL load within 1 second  
**And** screen SHALL display survey data table

#### Scenario: Debug screen displays all survey parameters

**Given** user is on Survey Data Debug Screen  
**And** survey contains 50 data points  
**When** screen renders  
**Then** table SHALL display columns:
- Record # (point number)
- Distance (meters, 2 decimal places)
- Azimuth (degrees, 1 decimal place)
- Depth (meters, 2 decimal places)
- Left (meters, 2 decimal places)
- Right (meters, 2 decimal places)
- Up (meters, 2 decimal places)
- Down (meters, 2 decimal places)
- Type (auto or manual)
**And** all 50 points SHALL be visible (scrollable)

#### Scenario: Debug screen handles empty data

**Given** survey contains no data points  
**When** user navigates to debug screen  
**Then** screen SHALL display "No survey data collected yet"  
**Or** empty table with headers only  
**And** screen SHALL not crash or show error

#### Scenario: Debug screen performance with large datasets

**Given** survey contains 1000 data points  
**When** user navigates to debug screen  
**Then** screen SHALL load within 2 seconds  
**And** scrolling SHALL be smooth (>30 FPS)  
**And** table SHALL use virtualization/lazy loading  
**And** memory usage SHALL remain reasonable (<100MB increase)

#### Scenario: Table displays numeric values with proper formatting

**Given** survey contains data with various measurements  
**When** debug screen renders  
**Then** distance values SHALL show 2 decimal places (e.g., 12.45 m)  
**And** azimuth values SHALL show 1 decimal place (e.g., 245.5°)  
**And** LRUD values SHALL show 2 decimal places  
**And** numbers SHALL use monospaced font for alignment  
**And** zero values SHALL display as "0.00" not blank

#### Scenario: Table distinguishes between auto and manual points

**Given** survey contains both auto and manual points  
**When** debug screen renders  
**Then** manual points SHALL be visually distinct (different color/background)  
**Or** Type column SHALL clearly show "auto" vs "manual"  
**And** manual points SHALL display non-zero LRUD values  
**And** auto points SHALL show LRUD as 0.00

#### Scenario: Debug screen header is sticky/fixed

**Given** user is on debug screen with 100+ points  
**When** user scrolls down the table  
**Then** column headers SHALL remain visible at top  
**And** headers SHALL not scroll out of view  
**And** data alignment with headers SHALL be maintained

#### Scenario: Table supports horizontal scrolling

**Given** debug screen is displayed on narrow device  
**And** table is wider than screen  
**When** user swipes horizontally  
**Then** table SHALL scroll to reveal hidden columns  
**And** scrolling SHALL be smooth  
**And** Record # column MAY be sticky (optional enhancement)

### Requirement: Debug Screen Navigation (REQ-UI-004)

The application SHALL provide clear navigation to the Survey Data Debug Screen from the Settings menu.

**Priority**: SHOULD  
**Verification**: Navigate to settings, verify debug option present

#### Scenario: Debug option appears in Settings menu

**Given** user is on Settings screen  
**When** screen renders  
**Then** "Debug: Survey Data" option SHALL be visible  
**And** option SHALL have appropriate icon (table/list icon)  
**And** option SHALL be in Development or Advanced section

#### Scenario: Back navigation from debug screen

**Given** user is on Survey Data Debug Screen  
**When** user taps back button  
**Or** user swipes back (iOS)  
**Then** system SHALL return to Settings screen  
**And** settings scroll position SHALL be preserved

### Requirement: Export Path Notification Display (REQ-UI-005)

The application SHALL display export file paths in a readable format with proper truncation for long paths.

**Priority**: SHOULD  
**Verification**: Export file with various path lengths, verify display

#### Scenario: Short file path displays fully

**Given** export path is less than 60 characters  
**When** export completes  
**Then** notification SHALL show full file path  
**And** path SHALL be readable without truncation

#### Scenario: Long file path is truncated intelligently

**Given** export path is greater than 60 characters  
**When** export completes  
**Then** notification SHALL truncate path in middle  
**And** format SHALL be: `/start/.../end/filename.csv`  
**And** filename SHALL always be visible  
**And** truncation SHALL use ellipsis (...)

#### Scenario: Path uses monospaced font

**Given** export notification is displayed  
**Then** file path SHALL use monospaced font  
**And** path SHALL be distinguishable from other text  
**And** path SHALL be easy to read

## Implementation Notes

### Debug Screen UI Components

- Use `DataTable` widget or custom `ListView.builder`
- Sticky headers via `slivers` or package
- Monospaced font: `Courier`, `Monaco`, or `RobotoMono`
- Color coding: Use `AppColors` theme constants

### Reset Button Hold Timer

```dart
Timer? _resetHoldTimer;

void _onResetTapDown() {
  _resetHoldTimer = Timer(const Duration(seconds: 10), () {
    _performReset();
  });
}

void _onResetTapUp() {
  _resetHoldTimer?.cancel();
  _resetHoldTimer = null;
}
```

### File Path Truncation

```dart
String truncatePath(String path, int maxLength) {
  if (path.length <= maxLength) return path;
  
  final parts = path.split('/');
  final filename = parts.last;
  final start = parts.take(2).join('/');
  
  return '$start/.../$filename';
}
```

### Debug Screen Table Structure

```dart
DataTable(
  columnSpacing: 16,
  headingRowHeight: 40,
  dataRowHeight: 36,
  columns: [
    DataColumn(label: Text('#')),
    DataColumn(label: Text('Dist (m)')),
    DataColumn(label: Text('Azim (°)')),
    // ... more columns
  ],
  rows: surveyData.map((point) => DataRow(
    cells: [
      DataCell(Text('${point.recordNumber}')),
      DataCell(Text('${point.distance.toStringAsFixed(2)}')),
      // ... more cells
    ],
  )).toList(),
)
```

### Navigation Structure

```
Settings Screen
  └─ Debug Section
       └─ Survey Data → SurveyDataDebugScreen
```

### Visual Feedback Options

1. **Progress bar** below reset button (10-second fill)
2. **Color change** of button (red intensifying)
3. **Haptic feedback** at hold start (optional)
4. **Text countdown** "8... 7... 6..." (optional)

Minimum: Button visual state change (pressed appearance)
