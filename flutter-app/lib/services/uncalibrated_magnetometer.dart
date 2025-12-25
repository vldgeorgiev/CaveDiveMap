import 'package:flutter/services.dart';

/// Simple wrapper for the platform uncalibrated magnetometer stream.
class UncalibratedMagnetometer {
  static const EventChannel _channel =
      EventChannel('cavedivemap/uncalibrated_magnetometer');

  /// Stream of raw uncalibrated magnetometer readings (μT).
  /// Emits maps with keys: x, y, z.
  static Stream<Map<String, double>> get events async* {
    await for (final event in _channel.receiveBroadcastStream()) {
      if (event is Map) {
        yield {
          'x': (event['x'] as num).toDouble(),
          'y': (event['y'] as num).toDouble(),
          'z': (event['z'] as num).toDouble(),
        };
      }
    }
  }
}
