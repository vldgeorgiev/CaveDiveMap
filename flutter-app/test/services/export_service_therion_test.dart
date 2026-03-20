import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/survey_data.dart';
import 'package:cavedivemapf/services/export_service.dart';

SurveyData _point({
  required int recordNumber,
  required double distance,
  required double heading,
  required double depth,
  String rtype = 'manual',
  double left = 1.0,
  double right = 1.0,
  double up = 2.0,
  double down = 3.0,
}) {
  return SurveyData(
    recordNumber: recordNumber,
    distance: distance,
    heading: heading,
    depth: depth,
    left: left,
    right: right,
    up: up,
    down: down,
    rtype: rtype,
    timestamp: DateTime(2026, 3, 19, 11, 48, 14),
  );
}

void main() {
  final service = ExportService();

  group('buildTherionContent', () {
    test('first line is encoding  utf-8', () {
      final content = service.buildTherionContent(
        [_point(recordNumber: 1, distance: 0, heading: 0, depth: 0)],
        'test_survey',
      );
      expect(content.split('\n').first, equals('encoding  utf-8'));
    });

    test('contains data diving declaration', () {
      final content = service.buildTherionContent(
        [_point(recordNumber: 1, distance: 0, heading: 0, depth: 0)],
        'test_survey',
      );
      expect(content, contains('data diving from to length compass fromdepth todepth'));
    });

    test('contains walls on directive', () {
      final content = service.buildTherionContent(
        [_point(recordNumber: 1, distance: 0, heading: 0, depth: 0)],
        'test_survey',
      );
      expect(content, contains('walls on'));
    });

    test('contains date derived from first point timestamp', () {
      final content = service.buildTherionContent(
        [_point(recordNumber: 1, distance: 0, heading: 0, depth: 0)],
        'test_survey',
      );
      expect(content, contains('date 2026.03.19'));
    });

    test('auto points are excluded from exported stations', () {
      final points = [
        _point(recordNumber: 1, distance: 0.0, heading: 0.0, depth: 0.0),
        _point(recordNumber: 2, distance: 2.0, heading: 90.0, depth: 1.0, rtype: 'auto'),
        _point(recordNumber: 3, distance: 5.0, heading: 180.0, depth: 2.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');

      // Only two stations (0 and 1) from the two manual points; auto point skipped.
      // Leg count == 1: from 0 to 1.
      final lines = content.split('\n');
      final dataLines = lines
          .where((l) => RegExp(r'^\s+\d+\s+\d+\s+[\d.]+').hasMatch(l))
          .toList();
      expect(dataLines.length, equals(1));
    });

    test('station numbers are 0-based sequential regardless of recordNumber', () {
      final points = [
        _point(recordNumber: 100, distance: 0.0, heading: 0.0, depth: 0.0),
        _point(recordNumber: 200, distance: 4.0, heading: 45.0, depth: 1.0),
        _point(recordNumber: 300, distance: 9.0, heading: 90.0, depth: 2.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');

      // Expecting legs:  "   0   1 ..." and "   1   2 ..."
      expect(content, contains(RegExp(r'\s+0\s+1\s+')));
      expect(content, contains(RegExp(r'\s+1\s+2\s+')));
    });

    test('fromdepth and todepth match point depth values', () {
      final points = [
        _point(recordNumber: 1, distance: 0.0, heading: 10.0, depth: 3.5),
        _point(recordNumber: 2, distance: 6.0, heading: 10.0, depth: 7.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');
      // Leg: from=0, to=1, length=6.0, compass=from.heading=10.0, fromdepth=3.5, todepth=7.0
      expect(content, contains('3.5'));
      expect(content, contains('7.0'));
    });

    test('compass uses from-station heading (not to-station heading)', () {
      final points = [
        _point(recordNumber: 1, distance: 0.0, heading: 42.0, depth: 0.0),
        _point(recordNumber: 2, distance: 5.0, heading: 99.0, depth: 1.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');
      // The compass for leg 0→1 must be 42.0 (from.heading), not 99.0 (to.heading).
      expect(content, contains('42.00'));
    });

    test('LRUD dimensions block uses 0-based station index', () {
      final points = [
        _point(recordNumber: 42, distance: 0.0, heading: 0.0, depth: 0.0,
            left: 1.1, right: 2.2, up: 3.3, down: 4.4),
        _point(recordNumber: 43, distance: 5.0, heading: 10.0, depth: 1.0,
            left: 0.5, right: 0.5, up: 1.0, down: 2.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');

      // Dimension lines should use station index 0 and 1, not recordNumber 42/43.
      expect(content, contains(RegExp(r'\s+0 1\.10 2\.20 3\.30 4\.40')));
      expect(content, contains(RegExp(r'\s+1 0\.50 0\.50 1\.00 2\.00')));
    });

    test('auto points are omitted from LRUD dimensions block', () {
      final points = [
        _point(recordNumber: 1, distance: 0.0, heading: 0.0, depth: 0.0),
        _point(recordNumber: 2, distance: 3.0, heading: 90.0, depth: 1.0, rtype: 'auto'),
        _point(recordNumber: 3, distance: 6.0, heading: 180.0, depth: 2.0),
      ];
      final content = service.buildTherionContent(points, 'test_survey');

      // Only stations 0 and 1 appear in the dimensions block; station from auto point absent.
      final dimSection = content.split('data dimensions').last;
      expect(dimSection, contains(RegExp(r'\s+0 ')));
      expect(dimSection, contains(RegExp(r'\s+1 ')));
      // Index 2 should NOT appear (only 2 exported stations).
      expect(dimSection, isNot(contains(RegExp(r'\s+2 '))));
    });
  });
}
