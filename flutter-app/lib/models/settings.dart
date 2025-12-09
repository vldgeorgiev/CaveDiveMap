import 'package:flutter/foundation.dart';

/// Application settings model
class Settings extends ChangeNotifier {
  double _wheelCircumference;
  double _minPeakThreshold;
  String _surveyName;

  Settings({
    double wheelCircumference = 0.263, // Default ~84mm diameter wheel
    double minPeakThreshold = 50.0,
    String surveyName = 'Unnamed Survey',
  })  : _wheelCircumference = wheelCircumference,
        _minPeakThreshold = minPeakThreshold,
        _surveyName = surveyName;

  // Getters
  double get wheelCircumference => _wheelCircumference;
  double get minPeakThreshold => _minPeakThreshold;
  String get surveyName => _surveyName;

  // Update methods
  void updateWheelCircumference(double value) {
    _wheelCircumference = value;
    notifyListeners();
  }

  void updateMinPeakThreshold(double value) {
    _minPeakThreshold = value;
    notifyListeners();
  }

  void updateSurveyName(String value) {
    _surveyName = value;
    notifyListeners();
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'wheelCircumference': _wheelCircumference,
      'minPeakThreshold': _minPeakThreshold,
      'surveyName': _surveyName,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      wheelCircumference: json['wheelCircumference'] as double? ?? 0.263,
      minPeakThreshold: json['minPeakThreshold'] as double? ?? 50.0,
      surveyName: json['surveyName'] as String? ?? 'Unnamed Survey',
    );
  }
}
