import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Service for compass heading measurement
class CompassService extends ChangeNotifier {
  StreamSubscription<CompassEvent>? _compassSubscription;

  double? _currentHeading;
  double? _headingAccuracy;
  bool _isActive = false;
  bool _isCalibrated = false;

  // Getters
  double? get currentHeading => _currentHeading;
  double get heading => _currentHeading ?? 0.0; // Non-nullable for convenience
  double? get headingAccuracy => _headingAccuracy;
  bool get isActive => _isActive;
  bool get isCalibrated => _isCalibrated;

  /// Check if compass is available on device
  static Future<bool> isAvailable() async {
    return FlutterCompass.events != null;
  }

  /// Start listening to compass events
  Future<void> startListening() async {
    if (_isActive) return;

    final events = FlutterCompass.events;
    if (events == null) {
      debugPrint('Compass not available on this device');
      return;
    }

    _isActive = true;
    _compassSubscription = events.listen(_onCompassEvent);

    notifyListeners();
  }

  /// Stop listening to compass events
  void stopListening() {
    _isActive = false;
    _compassSubscription?.cancel();
    _compassSubscription = null;

    notifyListeners();
  }

  /// Handle compass event
  void _onCompassEvent(CompassEvent event) {
    // Ensure heading is always positive (0-360°)
    if (event.heading != null) {
      _currentHeading = event.heading! < 0 ? event.heading! + 360 : event.heading;
    } else {
      _currentHeading = event.heading;
    }
    _headingAccuracy = event.accuracy;

    // Consider calibrated if accuracy is better than 20 degrees
    if (_headingAccuracy != null) {
      _isCalibrated = _headingAccuracy! < 20.0;
    }

    notifyListeners();
  }

  /// Get heading as formatted string
  String getHeadingString() {
    if (_currentHeading == null) return '---°';
    return '${_currentHeading!.toStringAsFixed(1)}°';
  }

  /// Get cardinal direction (N, NE, E, SE, S, SW, W, NW)
  String getCardinalDirection() {
    if (_currentHeading == null) return '---';

    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = (((_currentHeading! + 22.5) % 360) / 45).floor();
    return directions[index];
  }

  /// Get accuracy status color (for UI indicator)
  /// Returns: 'good' (<20°), 'moderate' (20-40°), 'poor' (>40°), 'unknown'
  String getAccuracyStatus() {
    if (_headingAccuracy == null) return 'unknown';

    if (_headingAccuracy! < 20.0) return 'good';
    if (_headingAccuracy! < 40.0) return 'moderate';
    return 'poor';
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
