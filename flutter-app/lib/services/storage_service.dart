import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_data.dart';
import '../models/settings.dart';
import '../models/button_config.dart';

/// Storage service for survey data and app settings using Drift + SharedPreferences
///
/// **Persistence Guarantees:**
/// - Survey data persists automatically across app restarts (SQLite via Drift)
/// - Settings and button configs persist via SharedPreferences
/// - Data survives app termination, device restart, and app updates
/// - No manual save/flush required - both storage solutions handle persistence automatically
///
/// **Data Lifecycle:**
/// 1. App startup → `initialize()` → Opens SQLite database and SharedPreferences
/// 2. `_loadSurveyData()` → loads all persisted survey points from database
/// 3. `_loadPointCounter()` → restores point counter state from SharedPreferences
/// 4. Survey continues from last state seamlessly
class StorageService extends ChangeNotifier {
  SurveyDatabase? _database;
  SharedPreferences? _prefs;

  List<SurveyData> _surveyPoints = [];
  int _pointCounter = 1;

  /// Current survey points
  List<SurveyData> get surveyPoints => List.unmodifiable(_surveyPoints);

  /// Next point number
  int get nextPointNumber => _pointCounter;

  /// Initialize Drift database and SharedPreferences
  ///
  /// Opens persistent storage and loads all existing data.
  /// Survey data automatically persists across app restarts.
  Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize Drift database
    _database = SurveyDatabase(await _createDatabaseConnection());

    // Load existing data
    await _loadSurveyData();
    await _loadPointCounter();
  }

  /// Create database connection
  Future<QueryExecutor> _createDatabaseConnection() async {
    if (kIsWeb) {
      // For web, use in-memory database or IndexedDB
      return NativeDatabase.memory();
    }

    // For mobile/desktop, use file-based SQLite
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cave_survey.db'));
    return NativeDatabase(file);
  }

  /// Load survey data from Drift database
  Future<void> _loadSurveyData() async {
    if (_database == null) return;

    final dataList = await (_database!.select(_database!.surveyDataTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.recordNumber, mode: OrderingMode.asc)
          ]))
        .get();

    _surveyPoints = dataList.map((data) => SurveyData.fromDrift(data)).toList();

    notifyListeners();
  }

  /// Load point counter from SharedPreferences
  Future<void> _loadPointCounter() async {
    if (_prefs == null) return;

    _pointCounter = _prefs!.getInt('pointCounter') ?? 1;
  }

  /// Add a new survey point
  Future<void> addSurveyPoint(SurveyData point) async {
    if (_database == null) return;

    await _database!.into(_database!.surveyDataTable).insert(point.toDriftCompanion());

    _surveyPoints.add(point);

    // Update counter if this point number is >= current counter
    if (point.recordNumber >= _pointCounter) {
      _pointCounter = point.recordNumber + 1;
      await _prefs?.setInt('pointCounter', _pointCounter);
    }

    notifyListeners();
  }

  /// Update an existing survey point
  Future<void> updateSurveyPoint(SurveyData point) async {
    if (_database == null) return;

    // Find the record by recordNumber
    final existing = await (_database!.select(_database!.surveyDataTable)
          ..where((t) => t.recordNumber.equals(point.recordNumber)))
        .getSingleOrNull();

    if (existing != null) {
      await (_database!.update(_database!.surveyDataTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(point.toDriftCompanion());

      final index = _surveyPoints.indexWhere(
        (p) => p.recordNumber == point.recordNumber,
      );
      if (index != -1) {
        _surveyPoints[index] = point;
        notifyListeners();
      }
    }
  }

  /// Delete a survey point
  Future<void> deleteSurveyPoint(int recordNumber) async {
    if (_database == null) return;

    await (_database!.delete(_database!.surveyDataTable)
          ..where((t) => t.recordNumber.equals(recordNumber)))
        .go();

    _surveyPoints.removeWhere((p) => p.recordNumber == recordNumber);

    notifyListeners();
  }

  /// Delete all survey points
  Future<void> clearAllSurveyData() async {
    if (_database == null) return;

    await _database!.delete(_database!.surveyDataTable).go();

    _surveyPoints.clear();
    _pointCounter = 1;
    await _prefs?.setInt('pointCounter', _pointCounter);

    notifyListeners();
  }

  /// Alias for clearAllSurveyData (used by UI)
  Future<void> clearAllData() async {
    await clearAllSurveyData();
  }

  /// Save a survey point (alias for addSurveyPoint)
  Future<void> saveSurveyPoint(SurveyData point) async {
    await addSurveyPoint(point);
  }

  /// Get all survey data
  Future<List<SurveyData>> getAllSurveyData() async {
    return List.from(_surveyPoints);
  }

  /// Load settings from SharedPreferences
  Future<Settings> loadSettings() async {
    if (_prefs == null) {
      return Settings();
    }

    final jsonString = _prefs!.getString('settings');
    if (jsonString == null) {
      return Settings();
    }

    try {
      return Settings.fromJsonString(jsonString);
    } catch (e) {
      return Settings();
    }
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings(Settings settings) async {
    if (_prefs == null) return;

    await _prefs!.setString('settings', settings.toJsonString());
    notifyListeners();
  }

  /// Import survey data from JSON (for migration from Swift app)
  Future<void> importFromJson(List<Map<String, dynamic>> jsonData) async {
    if (_database == null) return;

    await clearAllSurveyData();

    for (final json in jsonData) {
      final point = SurveyData.fromJson(json);
      await addSurveyPoint(point);
    }
  }

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (_prefs == null) return defaultValue;

    if (T == String) {
      return _prefs!.getString(key) as T? ?? defaultValue;
    } else if (T == int) {
      return _prefs!.getInt(key) as T? ?? defaultValue;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T? ?? defaultValue;
    } else if (T == bool) {
      return _prefs!.getBool(key) as T? ?? defaultValue;
    }

    return defaultValue;
  }

  /// Set a setting value
  Future<void> setSetting(String key, dynamic value) async {
    if (_prefs == null) return;

    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    }

    notifyListeners();
  }

  /// Get wheel circumference setting (meters)
  double get wheelCircumference {
    return getSetting<double>('wheelCircumference', defaultValue: 0.15) ?? 0.15;
  }

  /// Set wheel circumference
  Future<void> setWheelCircumference(double value) async {
    await setSetting('wheelCircumference', value);
  }

  /// Close storage (cleanup)
  Future<void> close() async {
    await _database?.close();
  }

  // ========== Button Configuration Storage ==========

  /// Save button configuration
  Future<void> saveButtonConfig(String key, ButtonConfig config) async {
    if (_prefs == null) return;
    final json = config.toJson();
    // Store each value separately for reliability
    await _prefs!.setDouble('button_${key}_size', json['size'] as double);
    await _prefs!.setDouble('button_${key}_offsetX', json['offsetX'] as double);
    await _prefs!.setDouble('button_${key}_offsetY', json['offsetY'] as double);
  }

  /// Load button configuration
  Future<ButtonConfig?> loadButtonConfig(String key) async {
    if (_prefs == null) return null;

    final size = _prefs!.getDouble('button_${key}_size');
    final offsetX = _prefs!.getDouble('button_${key}_offsetX');
    final offsetY = _prefs!.getDouble('button_${key}_offsetY');

    if (size == null || offsetX == null || offsetY == null) {
      return null;
    }

    return ButtonConfig(
      size: size,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }
}
