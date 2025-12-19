# Capability: Data Persistence

**Change**: `update-survey-data-management`  
**Capability ID**: `data-persistence`  
**Type**: Modified Capability

## MODIFIED Requirements

### Requirement: Survey Data Persistence Across App Sessions (REQ-DATA-001)

The application SHALL persist all survey data points to local storage and automatically reload them when the application restarts, ensuring no data loss between sessions.

**Previous**: Survey data persistence behavior was implicit/undefined  
**Modified**: Explicitly defined persistence guarantees and automatic reload behavior

**Priority**: MUST  
**Verification**: Force-quit app with survey data, restart, verify all data present

#### Scenario: Data persists after app restart on iOS

**Given** application has collected 10 survey points  
**And** user is on iOS device  
**When** user force-quits the application  
**And** user relaunches the application  
**Then** all 10 survey points SHALL be loaded automatically  
**And** point counter SHALL resume from last value  
**And** distance measurements SHALL continue from last cumulative value

#### Scenario: Data persists after app restart on Android

**Given** application has collected 20 survey points  
**And** user is on Android device  
**When** user force-quits the application  
**And** user relaunches the application  
**Then** all 20 survey points SHALL be loaded automatically  
**And** point counter SHALL resume from last value  
**And** distance measurements SHALL continue from last cumulative value

#### Scenario: First launch with no existing data

**Given** application is launched for the first time  
**Or** all data has been reset previously  
**When** application initializes storage service  
**Then** survey data list SHALL be empty  
**And** point counter SHALL start at 1  
**And** cumulative distance SHALL be 0.0 meters

### Requirement: Automatic Data Export Before Reset (REQ-DATA-002)

The application SHALL automatically export all survey data to a timestamped CSV file before clearing data during a reset operation, preventing accidental data loss.

**Priority**: MUST  
**Verification**: Trigger reset, verify CSV file created before data cleared

#### Scenario: Reset exports CSV with timestamp

**Given** application has 15 survey points  
**When** user triggers reset after 10-second hold  
**Then** system SHALL export CSV file with filename format `backup_YYYY-MM-DD_HH-mm-ss.csv`  
**And** CSV file SHALL contain all 15 survey points  
**And** CSV file SHALL be created in temporary directory  
**And** file creation SHALL complete before data is cleared

#### Scenario: Reset completes even if export fails

**Given** application has survey data  
**And** file system is full or write-protected  
**When** user triggers reset  
**And** CSV export fails  
**Then** system SHALL display error notification  
**And** system SHALL still clear survey data (user intent honored)  
**And** error message SHALL inform user export failed

#### Scenario: Reset with no data skips export

**Given** application has no survey data (empty state)  
**When** user triggers reset  
**Then** system SHALL skip CSV export step  
**And** system SHALL proceed directly to clear operation  
**And** system SHALL display success message

### Requirement: Export File Path Notification (REQ-DATA-003)

The application SHALL display a brief notification showing the file path of exported CSV or Therion files after successful export operations.

**Priority**: SHOULD  
**Verification**: Export data, verify file path shown for 3 seconds

#### Scenario: CSV export shows file path

**Given** user exports survey data as CSV  
**When** export completes successfully  
**Then** system SHALL display notification with full file path  
**And** notification SHALL be visible for 3 seconds  
**And** file path SHALL be readable (truncated if too long)  
**And** notification SHALL use monospaced font for path

#### Scenario: Therion export shows file path

**Given** user exports survey data as Therion format  
**When** export completes successfully  
**Then** system SHALL display notification with full file path  
**And** notification SHALL be visible for 3 seconds  
**And** file path SHALL be readable (truncated if too long)

#### Scenario: Reset-triggered export shows file path

**Given** user triggers reset with existing data  
**When** automatic CSV export completes  
**Then** system SHALL display notification with backup file path  
**And** notification SHALL indicate this is a backup export  
**And** user SHALL see where backup was saved before data clears

## ADDED Requirements

### Requirement: Data Reload on Startup (REQ-DATA-004)

The application SHALL automatically load all persisted survey data from Hive storage during initialization, before displaying the main screen.

**Priority**: MUST  
**Verification**: Monitor app startup sequence, verify data loaded before UI shown

#### Scenario: Data loads before main screen displays

**Given** application has persisted survey data  
**When** user launches application  
**Then** `StorageService.initialize()` SHALL complete before main screen loads  
**And** survey data SHALL be available in memory  
**And** main screen SHALL display correct point count immediately

#### Scenario: Startup handles corrupted data gracefully

**Given** Hive storage contains corrupted survey data  
**When** user launches application  
**Then** system SHALL catch deserialization errors  
**And** system SHALL log error details  
**And** system SHALL display error message to user  
**And** system SHALL offer option to clear corrupted data  
**And** application SHALL not crash

## Implementation Notes

### Hive Persistence Model

- Survey data stored in Hive box: `survey_data`
- Data automatically persists to disk on write
- No manual flush required (Hive handles this)
- Data survives app termination, device restart, app updates

### Export Filename Format

```
backup_YYYY-MM-DD_HH-mm-ss.csv
Example: backup_2025-12-11_14-30-45.csv
```

### File Path Truncation Logic

If path exceeds 60 characters:
```
/Users/.../CaveDiveMap/temp/file.csv
```

### Error Handling

- Export failures should not block reset operation
- Corrupted data should not crash app
- Missing Hive box should recreate cleanly
