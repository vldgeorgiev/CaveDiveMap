import 'package:flutter/foundation.dart';
import 'dart:math';

/// Application settings model
class Settings extends ChangeNotifier {
  double _wheelDiameter;
  double _minPeakThreshold;
  double _maxPeakThreshold;
  String _surveyName;

  Settings({
    double wheelDiameter = 0.043, // Default 43mm diameter wheel
    double minPeakThreshold = 50.0,
    double maxPeakThreshold = 100.0,
    String surveyName = 'Unnamed Survey',
  })  : _wheelDiameter = wheelDiameter,
        _minPeakThreshold = minPeakThreshold,
        _maxPeakThreshold = maxPeakThreshold,
        _surveyName = surveyName;

  // Getters
  double get wheelDiameter => _wheelDiameter;
  double get wheelCircumference => _wheelDiameter * pi; // Calculated property
  double get minPeakThreshold => _minPeakThreshold;
  double get maxPeakThreshold => _maxPeakThreshold;
  String get surveyName => _surveyName;

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

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'wheelDiameter': _wheelDiameter,
      'minPeakThreshold': _minPeakThreshold,
      'maxPeakThreshold': _maxPeakThreshold,
      'surveyName': _surveyName,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    // Support legacy 'wheelCircumference' for migration
    double diameter;
    if (json.containsKey('wheelDiameter')) {
      diameter = json['wheelDiameter'] as double? ?? 0.0837;
    } else if (json.containsKey('wheelCircumference')) {
      // Migrate old circumference to diameter
      final circumference = json['wheelCircumference'] as double? ?? 0.263;
      diameter = circumference / pi;
    } else {
      diameter = 0.0837;
    }

    return Settings(
      wheelDiameter: diameter,
      minPeakThreshold: json['minPeakThreshold'] as double? ?? 50.0,
      maxPeakThreshold: json['maxPeakThreshold'] as double? ?? 100.0,
      surveyName: json['surveyName'] as String? ?? 'Unnamed Survey',
    );
  }
}
