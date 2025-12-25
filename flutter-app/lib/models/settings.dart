import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import '../services/rotation_detection/rotation_algorithm.dart';

/// Application settings model
class Settings extends ChangeNotifier {
  double _wheelDiameter;
  double _minPeakThreshold;
  double _maxPeakThreshold;
  String _surveyName;
  bool _keepScreenOn;
  bool _fullscreen;
  RotationAlgorithm _rotationAlgorithm;

  Settings({
    double wheelDiameter = 0.043, // Default 43mm diameter wheel
    double minPeakThreshold = 50.0,
    double maxPeakThreshold = 100.0,
    String surveyName = 'survey',
    bool keepScreenOn = true, // Default: keep screen on during surveys
    bool fullscreen = true, // Default: fullscreen mode enabled
    RotationAlgorithm rotationAlgorithm = RotationAlgorithm.threshold,
  }) : _wheelDiameter = wheelDiameter,
       _minPeakThreshold = minPeakThreshold,
       _maxPeakThreshold = maxPeakThreshold,
       _surveyName = surveyName,
       _keepScreenOn = keepScreenOn,
       _fullscreen = fullscreen,
       _rotationAlgorithm = rotationAlgorithm;

  // Getters
  double get wheelDiameter => _wheelDiameter;
  double get wheelCircumference => _wheelDiameter * pi; // Calculated property
  double get minPeakThreshold => _minPeakThreshold;
  double get maxPeakThreshold => _maxPeakThreshold;
  String get surveyName => _surveyName;
  bool get keepScreenOn => _keepScreenOn;
  bool get fullscreen => _fullscreen;
  RotationAlgorithm get rotationAlgorithm => _rotationAlgorithm;

  // Update methods
  void updateWheelDiameter(double value) {
    _wheelDiameter = value;
    notifyListeners();
  }

  void updateMinPeakThreshold(double value) {
    _minPeakThreshold = value;
    notifyListeners();
  }

  void updateMaxPeakThreshold(double value) {
    _maxPeakThreshold = value;
    notifyListeners();
  }

  void updateSurveyName(String value) {
    _surveyName = value;
    notifyListeners();
  }

  void updateKeepScreenOn(bool value) {
    _keepScreenOn = value;
    notifyListeners();
  }

  void updateFullscreen(bool value) {
    _fullscreen = value;
    notifyListeners();
  }

  void updateRotationAlgorithm(RotationAlgorithm value) {
    _rotationAlgorithm = value;
    notifyListeners();
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'wheelDiameter': _wheelDiameter,
      'minPeakThreshold': _minPeakThreshold,
      'maxPeakThreshold': _maxPeakThreshold,
      'surveyName': _surveyName,
      'keepScreenOn': _keepScreenOn,
      'fullscreen': _fullscreen,
      'rotationAlgorithm': _rotationAlgorithm.name,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      wheelDiameter: json['wheelDiameter'] as double? ?? 0.043,
      minPeakThreshold: json['minPeakThreshold'] as double? ?? 50.0,
      maxPeakThreshold: json['maxPeakThreshold'] as double? ?? 100.0,
      surveyName: json['surveyName'] as String? ?? 'survey',
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      fullscreen: json['fullscreen'] as bool? ?? true,
      rotationAlgorithm: _parseAlgorithm(json['rotationAlgorithm'] as String?),
    );
  }

  static RotationAlgorithm _parseAlgorithm(String? value) {
    if (value == null) return RotationAlgorithm.threshold;
    try {
      return RotationAlgorithm.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return RotationAlgorithm.threshold;
    }
  }

  // JSON string serialization for SharedPreferences
  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Settings.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Settings.fromJson(json);
  }
}
