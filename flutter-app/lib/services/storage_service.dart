import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/survey_data.dart';
import '../models/settings.dart';
import '../models/button_config.dart';

/// Storage service for survey data and app settings using Hive
///
/// **Persistence Guarantees:**
/// - Survey data persists automatically across app restarts
/// - Hive stores data on disk and reloads it on `initialize()`
/// - Data survives app termination, device restart, and app updates
/// - No manual save/flush required - Hive handles persistence automatically
///
/// **Data Lifecycle:**
/// 1. App startup → `initialize()` → Hive opens boxes
/// 2. `_loadSurveyData()` → loads all persisted survey points
/// 3. `_loadPointCounter()` → restores point counter state
/// 4. Survey continues from last state seamlessly
class StorageService extends ChangeNotifier {
  static const String _surveyBoxName = 'survey_data';
  static const String _settingsBoxName = 'app_settings';
  static const String _buttonSettingsBoxName = 'button_settings';

  Box<Map>? _surveyBox;
  Box? _settingsBox;
  Box? _buttonSettingsBox;

  List<SurveyData> _surveyPoints = [];
  int _pointCounter = 1;

  /// Current survey points
  List<SurveyData> get surveyPoints => List.unmodifiable(_surveyPoints);

  /// Next point number
  int get nextPointNumber => _pointCounter;

  /// Initialize Hive and open boxes
  ///
  /// Opens persistent Hive boxes and loads all existing data.
  /// Survey data automatically persists across app restarts.
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ButtonConfigAdapter());
    }

    // Open persistent boxes (data survives app restarts)
    _surveyBox = await Hive.openBox<Map>(_surveyBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _buttonSettingsBox = await Hive.openBox(_buttonSettingsBoxName);

    // Load existing data from disk
    await _loadSurveyData();
    await _loadPointCounter();
  }

  /// Load survey data from storage
  Future<void> _loadSurveyData() async {
    if (_surveyBox == null) return;

    _surveyPoints = _surveyBox!.values
        .map((json) => SurveyData.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    // Sort by record number
    _surveyPoints.sort((a, b) => a.recordNumber.compareTo(b.recordNumber));

    notifyListeners();
  }

  /// Load point counter from settings
  Future<void> _loadPointCounter() async {
    if (_settingsBox == null) return;

    _pointCounter = _settingsBox!.get('pointCounter', defaultValue: 1) as int;
  }

  /// Add a new survey point
  Future<void> addSurveyPoint(SurveyData point) async {
    if (_surveyBox == null) return;

    await _surveyBox!.put(point.recordNumber, point.toJson());
    _surveyPoints.add(point);

    // Update counter if this point number is >= current counter
    if (point.recordNumber >= _pointCounter) {
      _pointCounter = point.recordNumber + 1;
      await _settingsBox?.put('pointCounter', _pointCounter);
    }

    notifyListeners();
  }

  /// Update an existing survey point
  Future<void> updateSurveyPoint(SurveyData point) async {
    if (_surveyBox == null) return;

    await _surveyBox!.put(point.recordNumber, point.toJson());

    final index = _surveyPoints.indexWhere(
      (p) => p.recordNumber == point.recordNumber,
    );
    if (index != -1) {
      _surveyPoints[index] = point;
      notifyListeners();
    }
  }

  /// Delete a survey point
  Future<void> deleteSurveyPoint(int recordNumber) async {
    if (_surveyBox == null) return;

    await _surveyBox!.delete(recordNumber);
    _surveyPoints.removeWhere((p) => p.recordNumber == recordNumber);

    notifyListeners();
  }

  /// Delete all survey points
  Future<void> clearAllSurveyData() async {
    if (_surveyBox == null) return;

    await _surveyBox!.clear();
    _surveyPoints.clear();
    _pointCounter = 1;
    await _settingsBox?.put('pointCounter', _pointCounter);

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

  /// Load settings from storage
  Future<Settings> loadSettings() async {
    if (_settingsBox == null) {
      return Settings();
    }

    final json = _settingsBox!.get('settings');
    if (json == null) {
      return Settings();
    }

    return Settings.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Save settings to storage
  Future<void> saveSettings(Settings settings) async {
    if (_settingsBox == null) return;

    await _settingsBox!.put('settings', settings.toJson());
    notifyListeners();
  }

  /// Import survey data from JSON (for migration from Swift app)
  Future<void> importFromJson(List<Map<String, dynamic>> jsonData) async {
    if (_surveyBox == null) return;

    await clearAllSurveyData();

    for (final json in jsonData) {
      final point = SurveyData.fromJson(json);
      await addSurveyPoint(point);
    }
  }

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }

  /// Set a setting value
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
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
    await _surveyBox?.close();
    await _settingsBox?.close();
    await _buttonSettingsBox?.close();
  }

  // ========== Button Configuration Storage ==========

  /// Save button configuration
  Future<void> saveButtonConfig(String key, ButtonConfig config) async {
    if (_buttonSettingsBox == null) return;
    await _buttonSettingsBox!.put(key, config);
  }

  /// Load button configuration
  Future<ButtonConfig?> loadButtonConfig(String key) async {
    if (_buttonSettingsBox == null) return null;
    return _buttonSettingsBox!.get(key) as ButtonConfig?;
  }
}
