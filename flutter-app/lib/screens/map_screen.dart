import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_data.dart';
import '../services/storage_service.dart';
import '../services/compass_service.dart';
import '../services/export_service.dart';
import '../utils/theme_extensions.dart';
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
  double _baseRotation = 0.0; // Base rotation before gesture

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
                  _baseRotation = _rotation;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Handle panning
                    _offset += details.focalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.focalPoint;

                    // Handle scaling (pinch zoom)
                    _scale = (_scale * details.scale).clamp(5.0, 100.0);

                    // Handle rotation (two-finger twist)
                    _rotation =
                        _baseRotation + (details.rotation * 180 / math.pi);
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
              Positioned(bottom: 16, left: 16, child: _buildScaleIndicator()),

              // Stats overlay
              Positioned(
                top: 16,
                left: 16,
                child: _buildStatsOverlay(surveyData),
              ),

              // Export buttons
              Positioned(bottom: 20, left: 20, child: _buildExportButtons()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompassOverlay(double heading) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.dataPrimary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass rose background
          CustomPaint(size: const Size(80, 80), painter: CompassRosePainter()),
          // North indicator (red arrow)
          Transform.rotate(
            angle: -(heading + _rotation) * math.pi / 180,
            child: Icon(
              Icons.navigation,
              color: AppColors.actionReset,
              size: 44,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          // North label
          Transform.rotate(
            angle: -_rotation * math.pi / 180,
            child: Positioned(
              top: 10,
              child: Text(
                'N',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.9), blurRadius: 6),
                  ],
                ),
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
          Container(width: 50, height: 4, color: Colors.white),
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

  Widget _buildExportButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CSV Export (Purple)
        GestureDetector(
          onTap: () => _exportCSV(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.actionExportCSV,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.upload_file, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        // Therion Export (Gray)
        GestureDetector(
          onTap: () => _exportTherion(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.actionExportTherion,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCSV() async {
    try {
      final storageService = context.read<StorageService>();
      final exportService = context.read<ExportService>();
      final surveyData = await storageService.getAllSurveyData();

      if (surveyData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No survey data to export',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.actionWarning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final fileName =
          'cave_survey_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      final file = await exportService.exportAndShareCSV(surveyData, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV exported successfully\n${_truncatePath(file.path)}',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            backgroundColor: AppColors.actionExportCSV,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: $e',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.actionReset,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _exportTherion() async {
    try {
      final storageService = context.read<StorageService>();
      final exportService = context.read<ExportService>();
      final surveyData = await storageService.getAllSurveyData();

      if (surveyData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No survey data to export',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.actionWarning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final surveyName =
          'cave_survey_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      final file = await exportService.exportAndShareTherion(
        surveyData,
        surveyName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Therion file exported successfully\n${_truncatePath(file.path)}',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            backgroundColor: AppColors.actionExportTherion,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: $e',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.actionReset,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _truncatePath(String path, {int maxLength = 60}) {
    if (path.length <= maxLength) return path;

    final parts = path.split('/');
    final filename = parts.last;
    final start = parts.take(2).join('/');

    return '$start/.../$filename';
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
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
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
      canvas.drawLine(Offset(x, -extent), Offset(x, extent), gridPaint);
    }

    // Horizontal lines
    for (double y = -extent; y < extent; y += gridSpacing) {
      canvas.drawLine(Offset(-extent, y), Offset(extent, y), gridPaint);
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

  void _drawPassageWalls(
    Canvas canvas,
    List<Offset> points,
    List<SurveyData> data,
  ) {
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

      canvas.drawCircle(
        point,
        surveyPoint.rtype == 'manual' ? 5 : 3,
        pointPaint,
      );
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
      Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      ),
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

/// Custom painter for compass rose background
class CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw cardinal direction marks
    final markPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - (math.pi / 2);
      final isCardinal = i % 2 == 0;
      final startRadius = radius * (isCardinal ? 0.65 : 0.75);
      final endRadius = radius * 0.85;

      final start = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * endRadius,
        center.dy + math.sin(angle) * endRadius,
      );

      canvas.drawLine(start, end, markPaint);
    }
  }

  @override
  bool shouldRepaint(CompassRosePainter oldDelegate) => false;
}
