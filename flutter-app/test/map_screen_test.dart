import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/survey_data.dart';
import 'dart:math' as math;

void main() {
  group('Map View Coordinate Calculations', () {
    test('Plan view coordinates - north heading', () {
      // Create sample survey points heading north (0°)
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 10.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      // Calculate plan coordinates (north should be negative Y)
      final scale = 20.0;
      double x = 0.0;
      double y = 0.0;

      final coords = <Map<String, double>>[];
      for (int i = 0; i < points.length; i++) {
        if (i > 0) {
          final deltaDistance = points[i].distance - points[i - 1].distance;
          final headingRad = points[i].heading * math.pi / 180;
          x += deltaDistance * math.sin(headingRad) * scale;
          y -= deltaDistance * math.cos(headingRad) * scale;
        }
        coords.add({'x': x, 'y': y});
      }

      // First point at origin
      expect(coords[0]['x'], equals(0.0));
      expect(coords[0]['y'], equals(0.0));

      // Second point 10m north (negative Y direction)
      expect(coords[1]['x'], closeTo(0.0, 0.01));
      expect(coords[1]['y'], closeTo(-200.0, 0.01)); // 10m * 20 scale = -200
    });

    test('Plan view coordinates - east heading', () {
      // Create sample survey points heading east (90°)
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 90.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 10.0,
          heading: 90.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      final scale = 20.0;
      double x = 0.0;
      double y = 0.0;

      final coords = <Map<String, double>>[];
      for (int i = 0; i < points.length; i++) {
        if (i > 0) {
          final deltaDistance = points[i].distance - points[i - 1].distance;
          final headingRad = points[i].heading * math.pi / 180;
          x += deltaDistance * math.sin(headingRad) * scale;
          y -= deltaDistance * math.cos(headingRad) * scale;
        }
        coords.add({'x': x, 'y': y});
      }

      // Second point 10m east (positive X direction)
      expect(coords[1]['x'], closeTo(200.0, 0.01)); // 10m * 20 scale = 200
      expect(coords[1]['y'], closeTo(0.0, 0.01));
    });

    test('Elevation view coordinates', () {
      // Create sample survey points with varying depth
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 0.0,
          depth: 5.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 10.0,
          heading: 45.0, // Heading should be ignored in elevation view
          depth: 10.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 3,
          distance: 20.0,
          heading: 180.0,
          depth: 8.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      final scale = 20.0;
      double totalDist = 0.0;

      final coords = <Map<String, double>>[];
      for (int i = 0; i < points.length; i++) {
        if (i > 0) {
          totalDist += (points[i].distance - points[i - 1].distance) * scale;
        }
        coords.add({'x': totalDist, 'y': points[i].depth * scale});
      }

      // First point at origin depth
      expect(coords[0]['x'], equals(0.0));
      expect(coords[0]['y'], equals(100.0)); // 5m * 20 = 100

      // Second point 10m along, depth 10m
      expect(coords[1]['x'], equals(200.0)); // 10m * 20 = 200
      expect(coords[1]['y'], equals(200.0)); // 10m * 20 = 200

      // Third point 20m along, depth 8m
      expect(coords[2]['x'], equals(400.0)); // 20m total * 20 = 400
      expect(coords[2]['y'], equals(160.0)); // 8m * 20 = 160
    });

    test('Manual points filtering', () {
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'auto',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 5.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 3,
          distance: 10.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'auto',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 4,
          distance: 15.0,
          heading: 0.0,
          depth: 0.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      final manualPoints = points.where((p) => p.rtype == 'manual').toList();

      expect(manualPoints.length, equals(2));
      expect(manualPoints[0].recordNumber, equals(2));
      expect(manualPoints[1].recordNumber, equals(4));
    });

    test('Bounding box calculation - plan view', () {
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 0.0,
          depth: 0.0,
          left: 2.0,
          right: 3.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 10.0,
          heading: 90.0,
          depth: 0.0,
          left: 1.0,
          right: 1.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      // Calculate bounds including passage dimensions
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      double x = 0, y = 0;
      for (int i = 0; i < points.length; i++) {
        if (i > 0) {
          final deltaDistance = points[i].distance - points[i - 1].distance;
          final headingRad = points[i].heading * math.pi / 180;
          x += deltaDistance * math.sin(headingRad);
          y += deltaDistance * math.cos(headingRad);
        }

        final left = points[i].left;
        final right = points[i].right;

        minX = math.min(minX, x - left);
        maxX = math.max(maxX, x + right);
        minY = math.min(minY, y - left);
        maxY = math.max(maxY, y + right);
      }

      // First point should expand bounds by left/right
      expect(minX, lessThan(0));
      expect(maxX, greaterThan(0));

      // Second point at 10m east should shift bounds
      expect(maxX, greaterThan(10));
    });

    test('Bounding box calculation - elevation view', () {
      final points = [
        SurveyData(
          recordNumber: 1,
          distance: 0.0,
          heading: 0.0,
          depth: 5.0,
          up: 1.0,
          down: 2.0,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
        SurveyData(
          recordNumber: 2,
          distance: 10.0,
          heading: 0.0,
          depth: 10.0,
          up: 0.5,
          down: 1.5,
          rtype: 'manual',
          timestamp: DateTime.now(),
        ),
      ];

      double totalDist = 0;
      double minDepth = double.infinity;
      double maxDepth = -double.infinity;

      for (int i = 0; i < points.length; i++) {
        if (i > 0) {
          totalDist += points[i].distance - points[i - 1].distance;
        }

        minDepth = math.min(minDepth, points[i].depth - points[i].down);
        maxDepth = math.max(maxDepth, points[i].depth + points[i].up);
      }

      // Total distance should be 10m
      expect(totalDist, equals(10.0));

      // Min depth: point 1 (5 - 2 = 3)
      expect(minDepth, equals(3.0));

      // Max depth: point 2 (10 + 0.5 = 10.5)
      expect(maxDepth, equals(10.5));
    });
  });
}
