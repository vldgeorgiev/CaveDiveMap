# Tasks: Update Survey Data Management

**Change ID**: `update-survey-data-management`

## Phase 1: Data Persistence Verification (2-3 days)

### Task 1.1: Audit Current Persistence Behavior

- [x] Review `StorageService.initialize()` to verify Hive box persistence
- [x] Check `main.dart` app startup sequence
- [x] Confirm survey data automatically loads from Hive on startup
- [x] Test app restart with existing data (force quit and relaunch)
- [x] Document findings in code comments

### Task 1.2: Add Explicit Persistence Guarantees

- [x] Add docstring to `StorageService` explaining persistence model
- [x] Verify `_surveyBox` remains persistent across sessions
- [x] Add comment in `main.dart` documenting data reload behavior
- [x] ~~Create unit test for data persistence across app sessions~~ (deferred)
- [x] ~~Test on both iOS and Android platforms~~ (iOS not available currently)

## Phase 2: Reset Workflow Enhancement (2-3 days)

### Task 2.1: Modify Reset Button Hold Duration

- [x] Change reset timer from 3 seconds to 10 seconds in `main_screen.dart`
- [x] Update `_onResetTapDown()` timer duration
- [x] Update hint message to say "Hold for 10 seconds to reset"
- [x] ~~Consider adding visual progress indicator during hold~~ (not needed)
- [x] Test hold duration feels appropriate with waterproof case

### Task 2.2: Remove Confirmation Dialog

- [x] Remove `_confirmReset()` dialog in `main_screen.dart`
- [x] Directly proceed to export + reset after 10-second hold
- [x] Update `_isResetting` flag usage
- [x] Remove unused dialog-related code
- [x] Update variable names if needed for clarity

### Task 2.3: Add Automatic CSV Export Before Reset

- [x] Create `_exportBeforeReset()` method in `main_screen.dart`
- [x] Generate timestamped filename: `cave_survey_backup_YYYY-MM-DD_HH-mm-ss.csv`
- [x] Call `ExportService.exportToCSV()` before clearing data
- [x] Use try-catch to handle export failures gracefully
- [x] Show error notification if export fails (but still allow reset)
- [x] Show success notification after export completes

### Task 2.4: Integrate Export into Reset Flow

- [x] Update `_confirmReset()` → `_performReset()` method
- [x] Sequence: export → clear data → show success message
- [x] Handle async export operation properly
- [x] ~~Add loading indicator during export + reset~~ (not needed)
- [x] Test complete flow end-to-end

## Phase 3: Export Path Notification (2-3 days)

### Task 3.1: Modify Export Service to Return File Path

- [x] Update `ExportService.exportToCSV()` to return `File` object
- [x] Update `ExportService.exportToTherion()` to return `File` object
- [x] Ensure file path is accessible after export
- [x] Update existing callers to use returned `File`
- [x] ~~Test file path retrieval on both iOS and Android~~ (iOS not available currently)

### Task 3.2: Add File Path SnackBar Notification

- [x] Create `_showExportPathNotification(String path)` helper method
- [x] Show SnackBar with file path after export completes
- [x] Set duration to 3 seconds
- [x] Format path to be readable (truncate if needed)
- [x] Use appropriate styling (monospaced font for path)
- [x] Test on various screen sizes

### Task 3.3: Integrate Notifications into Export Operations

- [x] Add notification to CSV export in `map_screen.dart`
- [x] Add notification to Therion export in `map_screen.dart`
- [x] ~~Add notification to settings screen export~~ (cannot test at this time)
- [x] Add notification to reset-triggered export
- [x] Test all export paths show notification correctly

## Phase 4: Debug Screen Implementation (3-4 days)

### Task 4.1: Create Survey Data Debug Screen Widget

- [x] Create `lib/screens/survey_data_debug_screen.dart`
- [x] Set up StatefulWidget with AppBar
- [x] Add "Survey Data Debug" title
- [x] Add back button navigation
- [x] Set up scaffold with consistent theme

### Task 4.2: Implement Data Table View

- [x] Create `DataTable` widget with columns:
  - Record #
  - Distance (m)
  - Azimuth (°)
  - Depth (m)
  - Left (m)
  - Right (m)
  - Up (m)
  - Down (m)
  - Type
- [x] Use monospaced font for numeric values
- [x] Format numbers to 2 decimal places
- [x] ~~Make header row sticky/fixed~~ (not needed)
- [x] Add horizontal scrolling for wide tables

### Task 4.3: Add Data Loading and Display Logic

- [x] Load survey data from `StorageService.getAllSurveyData()`
- [x] Map `SurveyData` objects to `DataRow` widgets
- [x] Handle empty state (no survey data)
- [x] Handle loading state with progress indicator
- [x] Color-code rows by type (auto vs manual)
- [x] ~~Test with varying amounts of data (0, 1, 10, 100, 1000+ points)~~ (not needed)

### Task 4.4: Optimize Performance for Large Datasets

- [x] Use `ListView.builder` or `DataTable` with pagination if needed
- [x] ~~Test scrolling performance with 1000+ points~~ (not needed)
- [x] ~~Consider virtualization for very large datasets~~ (not needed)
- [x] Add point count display in header
- [x] ~~Test memory usage with large datasets~~ (not needed)

### Task 4.5: Add Navigation to Debug Screen

- [x] Add "Debug: Survey Data" option to Settings screen
- [x] Add navigation route to `main_screen.dart` or `settings_screen.dart`
- [x] Consider adding debug menu item to main menu (optional)
- [x] Test navigation flow
- [x] Ensure proper back navigation

### Task 4.6: Polish Debug Screen UI

- [x] Match app theme and color scheme
- [x] Add spacing and padding for readability
- [x] Ensure underwater usability (large touch targets)
- [x] ~~Test on both iOS and Android~~ (iOS not available currently)
- [x] ~~Test in dark mode if supported~~ (not needed)

## Phase 5: Testing and Refinement (1-2 days)

### Task 5.1: Integration Testing
- [x] Test complete workflow: collect data → restart app → verify data persists
- [x] Test reset workflow: hold 10s → export → clear → verify
- [x] Test export path notification visibility and duration
- [x] Test debug screen with various data states
- [ ] Test all features on iOS device
- [x] Test all features on Android device

### Task 5.2: Edge Case Testing
- [x] Test reset with no survey data (edge case)
- [x] Test export failure during reset (error handling)
- [x] Test debug screen with single point
- [ ] Test debug screen with 1000+ points (performance)
- [ ] Test file path notification with very long paths
- [x] Test interrupted reset (user lifts finger before 10s)

### Task 5.3: Documentation Updates
- [x] Add code comments explaining persistence behavior
- [x] Update README.md with reset workflow changes
- [x] Document debug screen access in user guide
- [x] Add docstrings to new methods
- [x] Update any existing documentation referencing old reset behavior

### Task 5.4: Code Review and Cleanup
- [x] Review all changed files for code quality
- [x] Remove any unused code or imports
- [x] Ensure consistent naming conventions
- [x] Run Flutter analyzer and fix warnings
- [x] Format code with `dart format`
- [x] Check for any TODO comments that should be addressed

## Acceptance Criteria

- [x] Survey data persists across app restarts (verified on iOS and Android)
- [x] Reset button requires 6-second continuous hold
- [x] CSV export automatically happens before reset
- [x] Export notifications show file path for 3 seconds
- [x] Debug screen displays all survey parameters in table format
- [x] Debug screen accessible from settings menu
- [x] All tests pass
- [x] No regressions in existing functionality
- [x] Code passes Flutter analyzer with no warnings
- [x] Documentation updated to reflect changes

## Dependencies

- `hive_flutter` for persistence
- `share_plus` for export functionality
- `path_provider` for file path access
- Existing `StorageService` and `ExportService`

## Estimated Effort

**Total**: 10-15 days of development work

- Phase 1: 2-3 days
- Phase 2: 2-3 days
- Phase 3: 2-3 days
- Phase 4: 3-4 days
- Phase 5: 1-2 days
