import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/station.dart';
import 'package:cavedivemapf/services/export_service.dart';

Station _station({
  required int id,
  required int number,
  required double depth,
}) {
  return Station(
    id: id,
    number: number,
    depth: depth,
    timestamp: DateTime(2026, 3, 19, 11, 48, 14),
  );
}

SurveyLeg _leg({
  required int fromStationId,
  required int toStationId,
  required double distance,
  required double heading,
  double left = 1.0,
  double right = 1.0,
  double up = 2.0,
  double down = 3.0,
}) {
  return SurveyLeg(
    fromStationId: fromStationId,
    toStationId: toStationId,
    distance: distance,
    heading: heading,
    left: left,
    right: right,
    up: up,
    down: down,
    timestamp: DateTime(2026, 3, 19, 11, 48, 14),
  );
}

void main() {
  final service = ExportService();

  group('buildTherionContent', () {
    test('first line is encoding  utf-8', () {
      final content = service.buildTherionContent(
        [_station(id: 1, number: 1, depth: 0)],
        [],
        'test_survey',
      );
      expect(content.split('\n').first, equals('encoding  utf-8'));
    });

    test('contains data diving declaration', () {
      final content = service.buildTherionContent(
        [_station(id: 1, number: 1, depth: 0)],
        [],
        'test_survey',
      );
      expect(content, contains('data diving from to length compass fromdepth todepth'));
    });

    test('contains walls on directive', () {
      final content = service.buildTherionContent(
        [_station(id: 1, number: 1, depth: 0)],
        [],
        'test_survey',
      );
      expect(content, contains('walls on'));
    });

    test('contains date derived from first station timestamp', () {
      final content = service.buildTherionContent(
        [_station(id: 1, number: 1, depth: 0)],
        [],
        'test_survey',
      );
      expect(content, contains('date 2026.03.19'));
    });

    test('leg uses explicit from→to station numbers', () {
      final stations = [
        _station(id: 1, number: 1, depth: 0),
        _station(id: 2, number: 2, depth: 1),
        _station(id: 3, number: 3, depth: 2),
      ];
      final legs = [
        _leg(fromStationId: 1, toStationId: 2, distance: 4.0, heading: 45.0),
        _leg(fromStationId: 2, toStationId: 3, distance: 5.0, heading: 90.0),
      ];
      final content = service.buildTherionContent(stations, legs, 'test_survey');

      expect(content, contains(RegExp(r'\s+1\s+2\s+')));
      expect(content, contains(RegExp(r'\s+2\s+3\s+')));
    });

    test('fromdepth and todepth match station depth values', () {
      final stations = [
        _station(id: 1, number: 1, depth: 3.5),
        _station(id: 2, number: 2, depth: 7.0),
      ];
      final legs = [
        _leg(fromStationId: 1, toStationId: 2, distance: 6.0, heading: 10.0),
      ];
      final content = service.buildTherionContent(stations, legs, 'test_survey');
      expect(content, contains('3.5'));
      expect(content, contains('7.0'));
    });

    test('compass uses leg heading', () {
      final stations = [
        _station(id: 1, number: 1, depth: 0),
        _station(id: 2, number: 2, depth: 1),
      ];
      final legs = [
        _leg(fromStationId: 1, toStationId: 2, distance: 5.0, heading: 42.0),
      ];
      final content = service.buildTherionContent(stations, legs, 'test_survey');
      expect(content, contains('42.00'));
    });

    test('LRUD dimensions block uses station numbers', () {
      final stations = [
        _station(id: 1, number: 1, depth: 0),
        _station(id: 2, number: 2, depth: 1),
      ];
      final legs = [
        _leg(fromStationId: 1, toStationId: 2, distance: 5.0, heading: 10.0,
            left: 0.5, right: 0.5, up: 1.0, down: 2.0),
      ];
      final content = service.buildTherionContent(stations, legs, 'test_survey');

      // LRUD is on the leg, exported for the to-station (station 2)
      expect(content, contains(RegExp(r'\s+2 0\.50 0\.50 1\.00 2\.00')));
    });

    test('branching survey exports all legs from junction', () {
      final stations = [
        _station(id: 1, number: 1, depth: 0),
        _station(id: 2, number: 2, depth: 1),
        _station(id: 3, number: 3, depth: 2),
      ];
      final legs = [
        _leg(fromStationId: 1, toStationId: 2, distance: 3.0, heading: 45.0),
        _leg(fromStationId: 1, toStationId: 3, distance: 4.0, heading: 180.0),
      ];
      final content = service.buildTherionContent(stations, legs, 'test_survey');

      // Station 1 appears as from-station in two legs
      final dataLines = content.split('\n')
          .where((l) => RegExp(r'^\s+\d+\s+\d+\s+[\d.]+').hasMatch(l))
          .toList();
      expect(dataLines.length, equals(2));
    });
  });
}
