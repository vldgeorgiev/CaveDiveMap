import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_data.dart';
import '../services/storage_service.dart';
import '../services/compass_service.dart';
import 'dart:math' as math;

/// Map visualization screen with 2D cave survey rendering
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _scale = 20.0; // pixels per meter
  Offset _offset = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  double _rotation = 0.0; // North-oriented rotation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cave Map'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _scale = 20.0;
                _offset = Offset.zero;
                _rotation = 0.0;
              });
            },
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: FutureBuilder<List<SurveyData>>(
        future: context.read<StorageService>().getAllSurveyData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading survey data: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final surveyData = snapshot.data ?? [];

          if (surveyData.isEmpty) {
            return const Center(
              child: Text(
                'No survey data yet.\nStart surveying to see the map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return Stack(
            children: [
              // Map canvas
              GestureDetector(
                onScaleStart: (details) {
                  _lastFocalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Handle panning
                    _offset += details.focalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.focalPoint;

                    // Handle scaling (pinch zoom)
                    _scale = (_scale * details.scale).clamp(5.0, 100.0);
                  });
                },
                child: CustomPaint(
                  painter: CaveMapPainter(
                    surveyData: surveyData,
                    scale: _scale,
                    offset: _offset,
                    rotation: _rotation,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Compass overlay
              Positioned(
                top: 16,
                right: 16,
                child: Consumer<CompassService>(
                  builder: (context, compass, child) {
                    return _buildCompassOverlay(compass.heading);
                  },
                ),
              ),

              // Scale indicator
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildScaleIndicator(),
              ),

              // Stats overlay
              Positioned(
                top: 16,
                left: 16,
                child: _buildStatsOverlay(surveyData),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompassOverlay(double heading) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // North indicator
          Transform.rotate(
            angle: -heading * math.pi / 180,
            child: const Icon(
              Icons.navigation,
              color: Colors.red,
              size: 40,
            ),
          ),
          // North label
          Positioned(
            top: 8,
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleIndicator() {
    final scaleMeters = (50 / _scale).ceil(); // 50 pixels = X meters
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            '$scaleMeters m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(List<SurveyData> surveyData) {
    final totalPoints = surveyData.length;
    final manualPoints = surveyData.where((d) => d.rtype == 'manual').length;
    final totalDistance = surveyData.isEmpty ? 0.0 : surveyData.last.distance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Points: $totalPoints',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Manual: $manualPoints',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Distance: ${totalDistance.toStringAsFixed(1)} m',
            style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering the cave survey map
class CaveMapPainter extends CustomPainter {
  final List<SurveyData> surveyData;
  final double scale;
  final Offset offset;
  final double rotation;

  CaveMapPainter({
    required this.surveyData,
    required this.scale,
    required this.offset,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Apply transformations
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.rotate(rotation * math.pi / 180);

    // Draw grid
    _drawGrid(canvas, size);

    // Convert survey data to screen coordinates
    final points = _convertToScreenCoordinates(surveyData);

    if (points.isEmpty) return;

    // Draw survey line
    _drawSurveyLine(canvas, points);

    // Draw passage walls (from manual points)
    _drawPassageWalls(canvas, points, surveyData);

    // Draw points
    _drawPoints(canvas, points, surveyData);

    // Draw start point marker
    _drawStartPoint(canvas, points.first);
  }

  List<Offset> _convertToScreenCoordinates(List<SurveyData> data) {
    final points = <Offset>[];
    double x = 0.0;
    double y = 0.0;

    for (final point in data) {
      if (points.isNotEmpty) {
        // Calculate delta from previous point
        final prevPoint = data[data.indexOf(point) - 1];
        final deltaDistance = point.distance - prevPoint.distance;
        final headingRad = point.heading * math.pi / 180;

        // North is up (negative Y), East is right (positive X)
        x += deltaDistance * math.sin(headingRad) * scale;
        y -= deltaDistance * math.cos(headingRad) * scale;
      }

      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const gridSpacing = 50.0; // pixels
    final extent = math.max(size.width, size.height);

    // Vertical lines
    for (double x = -extent; x < extent; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, -extent),
        Offset(x, extent),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = -extent; y < extent; y += gridSpacing) {
      canvas.drawLine(
        Offset(-extent, y),
        Offset(extent, y),
        gridPaint,
      );
    }
  }

  void _drawSurveyLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);
  }

  void _drawPassageWalls(Canvas canvas, List<Offset> points, List<SurveyData> data) {
    final wallPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final surveyPoint = data[i];

      // Only draw walls for manual points with dimensions
      if (surveyPoint.rtype == 'manual' &&
          (surveyPoint.left > 0 || surveyPoint.right > 0)) {

        final headingRad = surveyPoint.heading * math.pi / 180;
        final perpRad = headingRad + math.pi / 2; // Perpendicular to heading

        // Calculate left and right wall endpoints
        final leftOffset = Offset(
          math.sin(perpRad) * surveyPoint.left * scale,
          -math.cos(perpRad) * surveyPoint.left * scale,
        );
        final rightOffset = Offset(
          -math.sin(perpRad) * surveyPoint.right * scale,
          math.cos(perpRad) * surveyPoint.right * scale,
        );

        // Draw wall segments
        canvas.drawCircle(point + leftOffset, 3, wallPaint);
        canvas.drawCircle(point + rightOffset, 3, wallPaint);

        // Draw connecting lines
        final wallLinePaint = Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 1;

        canvas.drawLine(point, point + leftOffset, wallLinePaint);
        canvas.drawLine(point, point + rightOffset, wallLinePaint);
      }
    }
  }

  void _drawPoints(Canvas canvas, List<Offset> points, List<SurveyData> data) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final surveyPoint = data[i];

      final pointPaint = Paint()
        ..color = surveyPoint.rtype == 'manual' ? Colors.green : Colors.cyan
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, surveyPoint.rtype == 'manual' ? 5 : 3, pointPaint);
    }
  }

  void _drawStartPoint(Canvas canvas, Offset point) {
    final startPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 8, startPaint);

    // Draw "S" for start
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(point.dx - textPainter.width / 2, point.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CaveMapPainter oldDelegate) {
    return oldDelegate.surveyData != surveyData ||
           oldDelegate.scale != scale ||
           oldDelegate.offset != offset ||
           oldDelegate.rotation != rotation;
  }
}
