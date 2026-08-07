import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/station.dart';
import 'dart:math' as math;

void main() {
  group('Map View Coordinate Calculations', () {
    test('Plan view coordinates - north heading', () {
      final legs = [
        SurveyLeg(
          fromStationId: 1,
          toStationId: 2,
          distance: 10.0,
          heading: 0.0,
          timestamp: DateTime.now(),
        ),
      ];

      // Traverse leg: heading 0° (north) → x += 0, y -= 10
      final scale = 20.0;
      final headingRad = legs[0].heading * math.pi / 180;
      final dx = legs[0].distance * math.sin(headingRad) * scale;
      final dy = -legs[0].distance * math.cos(headingRad) * scale;

      expect(dx, closeTo(0.0, 0.01));
      expect(dy, closeTo(-200.0, 0.01)); // 10m * 20 scale = -200
    });

    test('Plan view coordinates - east heading', () {
      final legs = [
        SurveyLeg(
          fromStationId: 1,
          toStationId: 2,
          distance: 10.0,
          heading: 90.0,
          timestamp: DateTime.now(),
        ),
      ];

      final scale = 20.0;
      final headingRad = legs[0].heading * math.pi / 180;
      final dx = legs[0].distance * math.sin(headingRad) * scale;
      final dy = -legs[0].distance * math.cos(headingRad) * scale;

      expect(dx, closeTo(200.0, 0.01)); // 10m * 20 scale = 200
      expect(dy, closeTo(0.0, 0.01));
    });

    test('Elevation view coordinates', () {
      final stations = [
        Station(id: 1, number: 1, depth: 5.0, timestamp: DateTime.now()),
        Station(id: 2, number: 2, depth: 10.0, timestamp: DateTime.now()),
        Station(id: 3, number: 3, depth: 8.0, timestamp: DateTime.now()),
      ];

      final legs = [
        SurveyLeg(fromStationId: 1, toStationId: 2, distance: 10.0,
            heading: 45.0, timestamp: DateTime.now()),
        SurveyLeg(fromStationId: 2, toStationId: 3, distance: 10.0,
            heading: 180.0, timestamp: DateTime.now()),
      ];

      final scale = 20.0;
      double cumulativeDist = 0;
      final coords = <Map<String, double>>[
        {'x': 0.0, 'y': stations[0].depth * scale},
      ];

      for (final leg in legs) {
        cumulativeDist += leg.distance;
        final toStation = stations.firstWhere((s) => s.id == leg.toStationId);
        coords.add({'x': cumulativeDist * scale, 'y': toStation.depth * scale});
      }

      expect(coords[0]['x'], equals(0.0));
      expect(coords[0]['y'], equals(100.0)); // 5m * 20 = 100
      expect(coords[1]['x'], equals(200.0)); // 10m * 20 = 200
      expect(coords[1]['y'], equals(200.0)); // 10m * 20 = 200
      expect(coords[2]['x'], equals(400.0)); // 20m total * 20 = 400
      expect(coords[2]['y'], equals(160.0)); // 8m * 20 = 160
    });

    test('Bounding box calculation - elevation view', () {
      final stations = [
        Station(id: 1, number: 1, depth: 5.0, timestamp: DateTime.now()),
        Station(id: 2, number: 2, depth: 10.0, timestamp: DateTime.now()),
      ];

      final legs = [
        SurveyLeg(fromStationId: 1, toStationId: 2, distance: 10.0,
            heading: 0.0, up: 1.0, down: 2.0, timestamp: DateTime.now()),
      ];

      double totalDist = legs.fold(0.0, (sum, l) => sum + l.distance);
      // LRUD is now on legs; elevation bounds use leg up/down at the to-station
      double minDepth = double.infinity;
      double maxDepth = -double.infinity;

      for (final s in stations) {
        // Find max up/down from connected legs
        double sUp = 0, sDown = 0;
        for (final l in legs) {
          if (l.fromStationId == s.id || l.toStationId == s.id) {
            sUp = math.max(sUp, l.up);
            sDown = math.max(sDown, l.down);
          }
        }
        minDepth = math.min(minDepth, s.depth - sDown);
        maxDepth = math.max(maxDepth, s.depth + sUp);
      }

      expect(totalDist, equals(10.0));
      expect(minDepth, equals(3.0)); // 5 - 2
      expect(maxDepth, equals(11.0)); // 10 + 1
    });

    test('Branching topology - junction station with two outgoing legs', () {
      final stations = [
        Station(id: 1, number: 1, depth: 0, timestamp: DateTime.now()),
        Station(id: 2, number: 2, depth: 0, timestamp: DateTime.now()),
        Station(id: 3, number: 3, depth: 0, timestamp: DateTime.now()),
      ];

      final legs = [
        SurveyLeg(fromStationId: 1, toStationId: 2, distance: 5.0,
            heading: 0.0, timestamp: DateTime.now()),
        SurveyLeg(fromStationId: 1, toStationId: 3, distance: 5.0,
            heading: 90.0, timestamp: DateTime.now()),
      ];

      // Station 1 has two outgoing legs
      final outgoing = legs.where((l) => l.fromStationId == 1).toList();
      expect(outgoing.length, equals(2));

      // Station 2 is north, station 3 is east
      final leg1Rad = outgoing[0].heading * math.pi / 180;
      final leg2Rad = outgoing[1].heading * math.pi / 180;
      final pos2 = Offset(
        5.0 * math.sin(leg1Rad),
        -5.0 * math.cos(leg1Rad),
      );
      final pos3 = Offset(
        5.0 * math.sin(leg2Rad),
        -5.0 * math.cos(leg2Rad),
      );

      expect(pos2.dx, closeTo(0.0, 0.01)); // North
      expect(pos2.dy, closeTo(-5.0, 0.01));
      expect(pos3.dx, closeTo(5.0, 0.01)); // East
      expect(pos3.dy, closeTo(0.0, 0.01));
    });
  });
}
