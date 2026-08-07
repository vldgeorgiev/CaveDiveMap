import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cavedivemapf/models/settings.dart';
import 'package:cavedivemapf/models/station.dart';
import 'package:cavedivemapf/screens/map_screen.dart';
import 'package:cavedivemapf/services/export_service.dart';
import 'package:cavedivemapf/services/storage_service.dart';

class _FakeStorageService extends StorageService {
  _FakeStorageService(this._stations, this._legs);

  final List<Station> _stations;
  final List<SurveyLeg> _legs;

  @override
  List<Station> get stations => _stations;

  @override
  List<SurveyLeg> get legs => _legs;
}

class _FakeExportService extends ExportService {
  int csvCalls = 0;

  @override
  Future<File> exportToCSV(
    List<Station> stations,
    List<SurveyLeg> legs,
    String fileName,
  ) async {
    csvCalls++;
    final file = File('${Directory.systemTemp.path}/$fileName');
    return file.writeAsString('ok');
  }

  @override
  Future<File> exportToTherion(
    List<Station> stations,
    List<SurveyLeg> legs,
    String surveyName,
  ) async {
    final file = File('${Directory.systemTemp.path}/$surveyName.th');
    return file.writeAsString('ok');
  }
}

void main() {
  Future<void> pumpMap(
    WidgetTester tester, {
    required _FakeStorageService storage,
    required _FakeExportService export,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageService>.value(value: storage),
          Provider<ExportService>.value(value: export),
          ChangeNotifierProvider<Settings>(create: (_) => Settings()),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> stablePress(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  CaveMapPainter currentPainter(WidgetTester tester) {
    final customPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('map_canvas')),
    );
    return customPaint.painter! as CaveMapPainter;
  }

  void sampleData(List<Station> stations, List<SurveyLeg> legs) {
    final now = DateTime(2026, 1, 1);
    stations.addAll([
      Station(
        id: 1,
        number: 1,
        depth: 5,
        timestamp: now,
      ),
      Station(
        id: 2,
        number: 2,
        depth: 6,
        timestamp: now.add(const Duration(seconds: 1)),
      ),
    ]);
    legs.add(SurveyLeg(
      fromStationId: 1,
      toStationId: 2,
      distance: 10,
      heading: 45,
      left: 1,
      right: 1,
      up: 1,
      down: 1,
      timestamp: now.add(const Duration(seconds: 1)),
    ));
  }

  testWidgets('export overlay touch does not modify map transform', (
    tester,
  ) async {
    final stations = <Station>[];
    final legs = <SurveyLeg>[];
    sampleData(stations, legs);
    final storage = _FakeStorageService(stations, legs);
    final export = _FakeExportService();
    await pumpMap(tester, storage: storage, export: export);

    final before = currentPainter(tester);
    await stablePress(tester, find.byKey(const Key('map_export_csv')));
    final after = currentPainter(tester);

    expect(export.csvCalls, 1);
    expect(after.scale, before.scale);
    expect(after.offset, before.offset);
    expect(after.rotation, before.rotation);
  });

  testWidgets('view mode control touch does not pan/zoom/rotate map', (
    tester,
  ) async {
    final stations = <Station>[];
    final legs = <SurveyLeg>[];
    sampleData(stations, legs);
    final storage = _FakeStorageService(stations, legs);
    final export = _FakeExportService();
    await pumpMap(tester, storage: storage, export: export);

    final before = currentPainter(tester);
    await stablePress(tester, find.byKey(const Key('map_toggle_plan')));
    final after = currentPainter(tester);

    expect(after.scale, before.scale);
    expect(after.offset, before.offset);
    expect(after.rotation, before.rotation);
  });
}
