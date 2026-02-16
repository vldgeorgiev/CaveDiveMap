import 'package:cavedivemapf/models/settings.dart';
import 'package:cavedivemapf/screens/main_screen.dart';
import 'package:cavedivemapf/services/button_customization_service.dart';
import 'package:cavedivemapf/services/compass_service.dart';
import 'package:cavedivemapf/services/export_service.dart';
import 'package:cavedivemapf/services/magnetometer_service.dart';
import 'package:cavedivemapf/services/rotation_detection/rotation_algorithm.dart';
import 'package:cavedivemapf/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestCompassService extends CompassService {
  double _heading = 123.0;
  double _accuracy = 5.0;

  @override
  double get heading => _heading;

  @override
  double get accuracy => _accuracy;

  @override
  Future<void> startListening() async {}

  @override
  void stopListening() {}
}

class _TestMagnetometerService extends MagnetometerService {
  bool _recording = false;
  int startRecordingCallCount = 0;
  int resetCallCount = 0;
  double _currentDepth = 0.0;
  double _totalDistance = 0.0;
  double _uncalibratedMagnitude = 0.0;
  RotationAlgorithm _algorithm = RotationAlgorithm.threshold;
  double _signalQuality = 0.0;

  _TestMagnetometerService(StorageService storage) : super(storage);

  @override
  bool get isRecording => _recording;

  @override
  double get currentDepth => _currentDepth;

  @override
  double get totalDistance => _totalDistance;

  @override
  double get uncalibratedMagnitude => _uncalibratedMagnitude;

  @override
  RotationAlgorithm get algorithm => _algorithm;

  @override
  double get signalQuality => _signalQuality;

  @override
  void startListening() {}

  @override
  void stopListening() {}

  @override
  void setAlgorithm(RotationAlgorithm algorithm) {
    _algorithm = algorithm;
  }

  @override
  void startRecording({
    double initialDepth = 0.0,
    double initialHeading = 0.0,
  }) {
    if (_recording) return;
    _recording = true;
    _currentDepth = initialDepth;
    startRecordingCallCount++;
    notifyListeners();
  }

  @override
  void stopRecording() {
    _recording = false;
    notifyListeners();
  }

  @override
  void reset() {
    stopRecording();
    _currentDepth = 0.0;
    _totalDistance = 0.0;
    resetCallCount++;
    notifyListeners();
  }

  @override
  void updateHeading(double heading) {}
}

void main() {
  testWidgets('reset hold resumes recording immediately without app restart', (
    tester,
  ) async {
    final storage = StorageService();
    final settings = Settings();
    final buttonService = ButtonCustomizationService(storage);
    final compass = _TestCompassService();
    final magnetometer = _TestMagnetometerService(storage);
    final export = ExportService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          ChangeNotifierProvider<Settings>.value(value: settings),
          ChangeNotifierProvider<ButtonCustomizationService>.value(
            value: buttonService,
          ),
          ChangeNotifierProvider<CompassService>.value(value: compass),
          ChangeNotifierProvider<MagnetometerService>.value(
            value: magnetometer,
          ),
          Provider<ExportService>.value(value: export),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.pump();

    expect(magnetometer.isRecording, isTrue);
    final startsBeforeReset = magnetometer.startRecordingCallCount;

    final resetButton = find.byIcon(Icons.refresh);
    expect(resetButton, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(resetButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 5));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(magnetometer.resetCallCount, 1);
    expect(magnetometer.startRecordingCallCount, startsBeforeReset + 1);
    expect(magnetometer.isRecording, isTrue);

    // Allow reset snackbar timer to complete before test teardown.
    await tester.pump(const Duration(seconds: 4));
  });
}
