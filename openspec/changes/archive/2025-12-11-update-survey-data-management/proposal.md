# Proposal: Update Survey Data Management

**Change ID**: `update-survey-data-management`  
**Type**: Feature Enhancement  
**Status**: Proposed  
**Created**: 2025-12-11

## Summary

Enhance the survey data persistence and management system to provide robust data retention across app sessions, improved reset workflow with automatic export, and a new debug visualization screen. This change ensures users never lose collected survey data unintentionally and provides better visibility into collected measurements.

## Motivation

### Current State Problems

1. **Data Persistence Unclear**: Survey data persistence behavior on app restart is not well-defined
2. **Risky Reset**: Users can accidentally lose data without automatic backup
3. **No Data Inspection**: No way to view collected data in detail without exporting
4. **Reset Feedback**: Users may trigger reset accidentally without sufficient protection

### Benefits of Proposed Changes

1. **Data Safety**: Automatic export before reset prevents data loss
2. **Persistent State**: Survey data survives app restarts, providing continuous sessions
3. **Debug Visibility**: Table view allows inspection of all survey parameters
4. **Better UX**: 10-second hold requirement prevents accidental resets
5. **Transparency**: File path hints show users where data is saved

### Success Criteria

- [ ] Survey data persists and reloads automatically on app startup
- [ ] Reset button requires 10-second hold to activate
- [ ] Reset automatically exports CSV with timestamp before clearing data
- [ ] Export operations show brief file path notification
- [ ] Debug screen displays all survey data in table format
- [ ] LRUD (Left/Right/Up/Down) data visible in debug view

## Scope

### In Scope

- Persistent survey data storage (survives app restarts)
- Automatic data reload on app startup
- 10-second hold requirement for reset button
- Automatic CSV export before reset with timestamp filename
- Short-lived notification showing export file path
- New debug screen with table view of survey data
- Table columns: Point #, Distance, Azimuth, Depth, L/R/U/D
- Navigation to debug screen from settings or main menu

### Out of Scope

- Editing survey data in debug screen (read-only)
- Filtering or sorting in debug screen
- Cloud backup or sync
- Multiple survey session management
- Undo/redo for reset operation
- Export format customization in debug screen

### Dependencies

- Existing `StorageService` (Hive-based persistence)
- Existing `ExportService` (CSV export)
- Existing button customization system

## Technical Approach

### Data Persistence Strategy

**Current State:**
- Survey data stored in Hive `survey_data` box
- Data loaded on `StorageService.initialize()`
- Unclear if data persists between sessions

**Proposed State:**
- Explicitly ensure Hive data persists across app restarts
- Automatically reload survey data in `main.dart` initialization
- Document persistence guarantees in code comments

### Reset Workflow Enhancement

**Current:**
```dart
// 3-second hold → confirmation dialog → clear data
```

**Proposed:**
```dart
// 10-second hold → auto-export CSV → clear data (no confirmation)
```

### Export Path Notification

**Implementation:**
```dart
// After export, show SnackBar with file path for 2-3 seconds
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Exported to: /path/to/file.csv'),
    duration: Duration(seconds: 3),
  ),
);
```

### Debug Screen Architecture

**New Widget:** `SurveyDataDebugScreen`

**Layout:**
- Scrollable table with fixed header
- Columns: Record #, Distance (m), Azimuth (°), Depth (m), L/R/U/D (m)
- Color-coded row types (auto vs manual)
- Monospaced numbers for alignment

**Data Flow:**
```
StorageService.getAllSurveyData() → DataTable → Display
```

### File Structure Changes

```
lib/
├── screens/
│   ├── survey_data_debug_screen.dart  [NEW]
│   ├── main_screen.dart               [MODIFIED]
│   └── settings_screen.dart           [MODIFIED]
└── services/
    ├── storage_service.dart           [MODIFIED]
    └── export_service.dart            [MODIFIED]
```

### Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| 10s hold too long underwater | Medium | Document in user manual; configurable in future |
| Export failure during reset | High | Try-catch with error notification, still allow reset |
| Debug screen performance with many points | Medium | Use ListView.builder for lazy loading |
| File path too long for notification | Low | Truncate path with ellipsis in middle |

## Implementation Plan

See `tasks.md` for detailed task breakdown.

**Estimated Timeline**: 1-2 weeks

- Phase 1 (2-3 days): Data persistence verification and documentation
- Phase 2 (2-3 days): Reset workflow enhancement (10s hold + auto-export)
- Phase 3 (2-3 days): Export path notification
- Phase 4 (3-4 days): Debug screen implementation
- Phase 5 (1-2 days): Testing and refinement

## Rollout Strategy

### Testing Checklist

- [ ] Verify data persists after force-quit app
- [ ] Test reset workflow with real 10-second hold
- [ ] Confirm CSV export before reset completes
- [ ] Check file path notification visibility
- [ ] Test debug screen with 0, 1, 100, 1000+ points
- [ ] Verify LRUD data displays correctly
- [ ] Test on both iOS and Android

### Documentation Updates

- Update user manual with new reset behavior
- Document debug screen access path
- Add comments explaining persistence guarantees

### Backward Compatibility

- No breaking changes to data models
- Existing survey data works unchanged
- Old reset behavior replaced (not deprecated)

## Open Questions

1. Should debug screen be accessible from main menu or only settings?
2. Should we add export button directly in debug screen?
3. Should 10-second duration be configurable in settings?

## Alternatives Considered

### Alternative 1: Keep Confirmation Dialog
- **Pros**: Familiar pattern, explicit user choice
- **Cons**: Extra tap underwater with gloves, can still lose data if user declines export
- **Decision**: Rejected - automatic export is safer

### Alternative 2: 5-Second Hold Instead of 10
- **Pros**: Faster for intentional resets
- **Cons**: Higher accidental trigger risk underwater
- **Decision**: Rejected - 10 seconds provides better safety margin

### Alternative 3: Full-Featured Data Editor
- **Pros**: Users can fix mistakes without export/import
- **Cons**: Complex UI, risky data corruption, underwater usability challenges
- **Decision**: Deferred to future enhancement

## References

- Swift iOS app reset behavior: `archive/swift-ios-app/cave-mapper/ContentView.swift` (line 209)
- Current Flutter reset: `flutter-app/lib/screens/main_screen.dart`
- CSV export: `flutter-app/lib/services/export_service.dart`
- Survey data model: `flutter-app/lib/models/survey_data.dart`
