import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';
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
  CaveSurveyDatabase? _database;
  SharedPreferences? _prefs;

  List<Station> _stations = [];
  List<SurveyLeg> _legs = [];
  List<AutoPoint> _autoPoints = [];
  int _stationCounter = 1;
  int? _currentDepartureStationId;
  double _departureDistance = 0.0;
  bool _needsLegStart = true;

  List<Station> get stations => List.unmodifiable(_stations);
  List<SurveyLeg> get legs => List.unmodifiable(_legs);
  List<AutoPoint> get autoPoints => List.unmodifiable(_autoPoints);
  int get nextStationNumber => _stationCounter;
  int? get currentDepartureStationId => _currentDepartureStationId;
  double get departureDistance => _departureDistance;
  /// True when measurement should be blocked (no departure station, or station just switched)
  bool get needsLegStart => _needsLegStart;

  /// Legacy compatibility — returns stations as the "survey points"
  List<Station> get surveyPoints => stations;

  /// Initialize Drift database and SharedPreferences
  ///
  /// Opens persistent storage and loads all existing data.
  /// Survey data automatically persists across app restarts.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _database = CaveSurveyDatabase(await _createDatabaseConnection());
    await _loadData();
    await _loadStationCounter();
    _currentDepartureStationId = _prefs!.getInt('currentDepartureStationId');
    _departureDistance = _prefs!.getDouble('departureDistance') ?? 0.0;
    // If stations exist and a departure station is set, leg is already started
    _needsLegStart = _stations.isEmpty || _currentDepartureStationId == null;
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

  /// Load all data from Drift database
  Future<void> _loadData() async {
    if (_database == null) return;

    final stationRows = await (_database!.select(_database!.stationsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.number)]))
        .get();
    _stations = stationRows.map((d) => Station.fromDrift(d)).toList();

    final legRows = await _database!.select(_database!.surveyLegsTable).get();
    _legs = legRows.map((d) => SurveyLeg.fromDrift(d)).toList();

    final autoRows = await _database!.select(_database!.autoPointsTable).get();
    _autoPoints = autoRows.map((d) => AutoPoint.fromDrift(d)).toList();

    notifyListeners();
  }

  /// Load station counter from SharedPreferences
  Future<void> _loadStationCounter() async {
    if (_prefs == null) return;
    _stationCounter = _prefs!.getInt('stationCounter') ?? 1;
  }

  // ========== Station CRUD ==========

  Future<int> addStation(Station station) async {
    if (_database == null) return -1;

    final id = await _database!
        .into(_database!.stationsTable)
        .insert(station.toDriftCompanion());

    _stations.add(station.copyWith(id: id));

    if (station.number >= _stationCounter) {
      _stationCounter = station.number + 1;
      await _prefs?.setInt('stationCounter', _stationCounter);
    }

    _needsLegStart = false;
    notifyListeners();
    return id;
  }

  Future<List<Station>> getAllStations() async {
    return List.from(_stations);
  }

  Station? getStationById(int id) {
    try {
      return _stations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteStation(int id) async {
    if (_database == null) return;
    await (_database!.delete(_database!.stationsTable)
          ..where((t) => t.id.equals(id)))
        .go();
    _stations.removeWhere((s) => s.id == id);
    // Also remove legs referencing this station
    await (_database!.delete(_database!.surveyLegsTable)
          ..where(
              (t) => t.fromStationId.equals(id) | t.toStationId.equals(id)))
        .go();
    _legs.removeWhere(
        (l) => l.fromStationId == id || l.toStationId == id);
    notifyListeners();
  }

  // ========== SurveyLeg CRUD ==========

  Future<int> addSurveyLeg(SurveyLeg leg) async {
    if (_database == null) return -1;

    final id = await _database!
        .into(_database!.surveyLegsTable)
        .insert(leg.toDriftCompanion());

    _legs.add(SurveyLeg(
      id: id,
      fromStationId: leg.fromStationId,
      toStationId: leg.toStationId,
      distance: leg.distance,
      heading: leg.heading,
      timestamp: leg.timestamp,
    ));

    notifyListeners();
    return id;
  }

  Future<List<SurveyLeg>> getAllLegs() async {
    return List.from(_legs);
  }

  List<SurveyLeg> getLegsByStationId(int stationId) {
    return _legs
        .where((l) =>
            l.fromStationId == stationId || l.toStationId == stationId)
        .toList();
  }

  Future<void> deleteLeg(int id) async {
    if (_database == null) return;
    await (_database!.delete(_database!.surveyLegsTable)
          ..where((t) => t.id.equals(id)))
        .go();
    _legs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  // ========== AutoPoint CRUD ==========

  Future<void> addAutoPoint(AutoPoint point) async {
    if (_database == null) return;

    await _database!
        .into(_database!.autoPointsTable)
        .insert(point.toDriftCompanion());

    _autoPoints.add(point);
    notifyListeners();
  }

  Future<List<AutoPoint>> getAllAutoPoints() async {
    return List.from(_autoPoints);
  }

  // ========== Current Departure Station ==========

  Future<void> setCurrentDepartureStationId(int? stationId, {bool isStationSwitch = false}) async {
    _currentDepartureStationId = stationId;
    if (isStationSwitch) {
      _needsLegStart = true;
    }
    notifyListeners();
    if (stationId != null) {
      await _prefs?.setInt('currentDepartureStationId', stationId);
    } else {
      await _prefs?.remove('currentDepartureStationId');
    }
  }

  Future<void> setDepartureDistance(double distance) async {
    _departureDistance = distance;
    await _prefs?.setDouble('departureDistance', distance);
  }

  // ========== Clear All ==========

  Future<void> clearAllSurveyData() async {
    if (_database == null) return;

    await _database!.delete(_database!.surveyLegsTable).go();
    await _database!.delete(_database!.stationsTable).go();
    await _database!.delete(_database!.autoPointsTable).go();

    _stations.clear();
    _legs.clear();
    _autoPoints.clear();
    _stationCounter = 1;
    _currentDepartureStationId = null;
    _departureDistance = 0.0;
    _needsLegStart = true;
    await _prefs?.setInt('stationCounter', _stationCounter);
    await _prefs?.remove('currentDepartureStationId');
    await _prefs?.remove('departureDistance');

    await _prefs?.remove('lastDepth');
    await _prefs?.remove('lastLeft');
    await _prefs?.remove('lastRight');
    await _prefs?.remove('lastUp');
    await _prefs?.remove('lastDown');

    notifyListeners();
  }

  /// Alias for clearAllSurveyData (used by UI)
  Future<void> clearAllData() async {
    await clearAllSurveyData();
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

  // ========== Last Entered Values (Depth & LRUD) ==========

  /// Save last entered depth and LRUD values
  Future<void> saveLastEnteredValues({
    required double depth,
    required double left,
    required double right,
    required double up,
    required double down,
  }) async {
    if (_prefs == null) return;
    await _prefs!.setDouble('lastDepth', depth);
    await _prefs!.setDouble('lastLeft', left);
    await _prefs!.setDouble('lastRight', right);
    await _prefs!.setDouble('lastUp', up);
    await _prefs!.setDouble('lastDown', down);
  }

  /// Load last entered depth and LRUD values
  Map<String, double> getLastEnteredValues() {
    if (_prefs == null) {
      return {
        'depth': 0.0,
        'left': 0.0,
        'right': 0.0,
        'up': 0.0,
        'down': 0.0,
      };
    }

    return {
      'depth': _prefs!.getDouble('lastDepth') ?? 0.0,
      'left': _prefs!.getDouble('lastLeft') ?? 0.0,
      'right': _prefs!.getDouble('lastRight') ?? 0.0,
      'up': _prefs!.getDouble('lastUp') ?? 0.0,
      'down': _prefs!.getDouble('lastDown') ?? 0.0,
    };
  }
}
