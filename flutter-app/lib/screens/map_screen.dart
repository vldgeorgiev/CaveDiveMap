import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_data.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../utils/theme_extensions.dart';
import 'dart:math' as math;

/// Map view mode (Plan or Elevation)
enum MapViewMode {
  plan,
  elevation,
}

/// Map visualization screen with 2D cave survey rendering
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _scale = 20.0; // pixels per meter
  Offset _offset = Offset.zero; // Pan offset in WORLD units (meters)
  Offset _lastFocalPoint = Offset.zero;
  double _rotation = 0.0; // Rotation in radians
  double _baseRotation = 0.0; // Base rotation before gesture
  double _baseScale = 20.0; // Base scale before gesture
  MapViewMode _viewMode = MapViewMode.plan;
  bool _isFirstLoad = true; // Track if auto-fit has been applied

  late Future<List<SurveyData>> _surveyFuture;

  @override
  void initState() {
    super.initState();
    _surveyFuture = context.read<StorageService>().getAllSurveyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cave Map'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _autoFitView,
            tooltip: 'Fit to screen',
          ),
        ],
      ),
      body: FutureBuilder<List<SurveyData>>(
        future: _surveyFuture,
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

          final allSurveyData = snapshot.data ?? [];
          final manualPoints = _getManualPoints(allSurveyData);

          if (allSurveyData.isEmpty) {
            return const Center(
              child: Text(
                'No survey data yet.\nStart surveying to see the map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          if (manualPoints.isEmpty) {
            return const Center(
              child: Text(
                'No manual survey points yet.\nManual points with reliable compass data are required for map visualization.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Auto-fit on first load
          if (_isFirstLoad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performAutoFit(manualPoints);
            });
            _isFirstLoad = false;
          }

          return Stack(
            children: [
              // Map canvas (bottom layer)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _lastFocalPoint = details.focalPoint;
                    _baseScale = _scale;
                    _baseRotation = _rotation;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      // Zoom - update scale first
                      _scale = (_baseScale * details.scale).clamp(5.0, 100.0);

                      // Pan - convert screen delta (pixels) to world delta (meters)
                      // Need to account for rotation when panning
                      final screenDelta = details.focalPoint - _lastFocalPoint;
                      _lastFocalPoint = details.focalPoint;

                      // Rotate the screen delta by the negative of the current rotation
                      // to get the correct world delta
                      final cosR = math.cos(-_rotation);
                      final sinR = math.sin(-_rotation);
                      final rotatedDelta = Offset(
                        screenDelta.dx * cosR - screenDelta.dy * sinR,
                        screenDelta.dx * sinR + screenDelta.dy * cosR,
                      );

                      final worldDelta = rotatedDelta / _scale;
                      _offset += worldDelta;

                      // Rotation (two-finger twist) - only in plan view
                      if (_viewMode == MapViewMode.plan) {
                        _rotation = _baseRotation + details.rotation;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: CaveMapPainter(
                      surveyData: manualPoints,
                      scale: _scale,
                      offset: _offset,
                      rotation: _rotation,
                      viewMode: _viewMode,
                    ),
                  ),
                ),
              ),

              // View mode toggle (top layer)
              Positioned(
                top: 16,
                left: 16,
                child: _buildViewModeToggle(),
              ),

              // Scale indicator
              Positioned(bottom: 16, left: 16, child: _buildScaleIndicator()),

              // Stats overlay
              Positioned(
                top: 80,
                left: 16,
                child: _buildStatsOverlay(allSurveyData, manualPoints),
              ),

              // Export buttons
              Positioned(bottom: 20, right: 20, child: _buildExportButtons()),
            ],
          );
        },
      ),
    );
  }

  /// Filter survey data to only manual points
  List<SurveyData> _getManualPoints(List<SurveyData> allPoints) {
    return allPoints.where((point) => point.rtype == 'manual').toList();
  }

  /// Build view mode toggle widget
  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            'Plan',
            MapViewMode.plan,
            Icons.map,
          ),
          _buildToggleButton(
            'Elevation',
            MapViewMode.elevation,
            Icons.show_chart,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, MapViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.cyan : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyan : Colors.grey,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Auto-fit view to show all manual points (async version for button)
  void _autoFitView() async {
    final storageService = context.read<StorageService>();
    final allData = await storageService.getAllSurveyData();
    final manualPoints = _getManualPoints(allData);

    if (!mounted) return;
    _performAutoFit(manualPoints);
  }

  /// Perform auto-fit with provided manual points (sync version)
  void _performAutoFit(List<SurveyData> manualPoints) {
    if (manualPoints.isEmpty) return;

    final size = MediaQuery.of(context).size;
    final bounds = _calculateSurveyBounds(manualPoints);

    if (bounds.width == 0 || bounds.height == 0) {
      // Single point or zero-size bounds
      setState(() {
        _scale = 20.0;
        _offset = Offset.zero;
        _rotation = 0.0;
      });
      return;
    }

    setState(() {
      final padding = 0.1; // 10% margin
      final scaleX = size.width / (bounds.width * (1 + padding));
      final scaleY = size.height / (bounds.height * (1 + padding));
      _rotation = 0.0;
      _scale = math.min(scaleX, scaleY).clamp(5.0, 100.0);

      // Center the survey - offset in world units (meters)
      _offset = Offset(
        -bounds.center.dx,
        -bounds.center.dy,
      );
    });
  }

  /// Calculate bounding box for survey points
  Rect _calculateSurveyBounds(List<SurveyData> manualPoints) {
    if (manualPoints.isEmpty) return Rect.zero;

    if (_viewMode == MapViewMode.plan) {
      // Plan view: Calculate XY from heading/distance
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      double x = 0, y = 0;
      for (int i = 0; i < manualPoints.length; i++) {
        if (i > 0) {
          final deltaDistance = manualPoints[i].distance - manualPoints[i - 1].distance;
          final headingRad = manualPoints[i].heading * math.pi / 180;
          x += deltaDistance * math.sin(headingRad);
          y += deltaDistance * math.cos(headingRad);
        }

        // Include passage dimensions in bounds
        final left = manualPoints[i].left;
        final right = manualPoints[i].right;
        final headingRad = manualPoints[i].heading * math.pi / 180;
        final perpRad = headingRad + math.pi / 2;

        minX = math.min(minX, x - left * math.sin(perpRad).abs());
        maxX = math.max(maxX, x + right * math.sin(perpRad).abs());
        minY = math.min(minY, y - left * math.cos(perpRad).abs());
        maxY = math.max(maxY, y + right * math.cos(perpRad).abs());
      }

      return Rect.fromLTRB(minX, minY, maxX, maxY);
    } else {
      // Elevation view: distance x depth
      double totalDist = 0;
      double minDepth = double.infinity;
      double maxDepth = -double.infinity;

      for (int i = 0; i < manualPoints.length; i++) {
        if (i > 0) {
          totalDist += manualPoints[i].distance - manualPoints[i - 1].distance;
        }

        final depth = manualPoints[i].depth;
        final up = manualPoints[i].up;
        final down = manualPoints[i].down;

        minDepth = math.min(minDepth, depth - down);
        maxDepth = math.max(maxDepth, depth + up);
      }

      return Rect.fromLTRB(0, minDepth, totalDist, maxDepth);
    }
  }

  Widget _buildScaleIndicator() {
    // Calculate actual meters for 50 pixel line
    final actualMeters = 50 / _scale;

    // Find a nice round number for the scale
    double scaleMeters;
    double scaleWidth;

    // Choose nice round numbers: 0.5, 1, 2, 5, 10, 20, 50, 100, etc.
    final niceNumbers = <double>[0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];

    // Find the closest nice number that fits reasonably (between 30-70 pixels)
    scaleMeters = niceNumbers.firstWhere(
      (n) => n >= actualMeters * 0.6,
      orElse: () => actualMeters,
    );

    // Calculate the actual pixel width for this scale
    scaleWidth = scaleMeters * _scale;

    // Format the label
    final label = scaleMeters >= 1
        ? '${scaleMeters.toStringAsFixed(scaleMeters % 1 == 0 ? 0 : 1)} m'
        : '${(scaleMeters * 100).toInt()} cm';

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
          Container(width: scaleWidth, height: 4, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
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
            child: const Center(
              child: Text(
                'csv',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            child: const Center(
              child: Text(
                'th',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCSV() async {
    try {
      final storageService = context.read<StorageService>();
      final exportService = context.read<ExportService>();
      final settings = context.read<Settings>();
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

      final timestamp = DateTime.now();
      final fileName =
          '${settings.surveyName}_'
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}'
          '.csv';
      final file = await exportService.exportToCSV(surveyData, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              file.path,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
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
      final settings = context.read<Settings>();
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

      final timestamp = DateTime.now();
      final surveyName =
          '${settings.surveyName}_'
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}';
      final file = await exportService.exportToTherion(
        surveyData,
        surveyName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              file.path,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
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

  Widget _buildStatsOverlay(List<SurveyData> allData, List<SurveyData> manualPoints) {
    final totalPoints = allData.length;
    final manualCount = manualPoints.length;
    final totalDistance = allData.isEmpty ? 0.0 : allData.last.distance;

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
            'Manual: $manualCount',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Distance: ${totalDistance.toStringAsFixed(1)} m',
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
  final MapViewMode viewMode;

  CaveMapPainter({
    required this.surveyData,
    required this.scale,
    required this.offset,
    required this.rotation,
    required this.viewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Apply transformations in correct order:
    // 1) Move origin to screen center
    canvas.translate(center.dx, center.dy);

    // 2) Apply zoom
    canvas.scale(scale);

    // 3) Apply rotation (plan view only)
    if (viewMode == MapViewMode.plan) {
      canvas.rotate(rotation); // rotation is already in radians
    }

    // 4) Apply world offset (in meters)
    canvas.translate(offset.dx, offset.dy);

    // Now draw everything in WORLD units (meters)
    _drawGrid(canvas, size);

    if (surveyData.isEmpty) return;

    // Draw based on view mode
    if (viewMode == MapViewMode.plan) {
      _drawPlanView(canvas);
    } else {
      _drawElevationView(canvas);
    }
  }

  /// Draw plan view (overhead, north-up)
  void _drawPlanView(Canvas canvas) {
    final points = _calculatePlanCoordinates();

    if (points.isEmpty) return;

    // Draw survey line
    _drawSurveyLine(canvas, points);

    // Draw passage walls (left/right)
    _drawPlanPassageWalls(canvas, points);

    // Draw points with labels
    _drawPointsWithLabels(canvas, points);

    // Draw start point marker
    _drawStartPoint(canvas, points.first);
  }

  /// Draw elevation view (vertical profile)
  void _drawElevationView(Canvas canvas) {
    final points = _calculateElevationCoordinates();

    if (points.isEmpty) return;

    // Draw survey line
    _drawSurveyLine(canvas, points);

    // Draw passage height (up/down)
    _drawElevationPassageHeight(canvas, points);

    // Draw points with labels
    _drawPointsWithLabels(canvas, points);

    // Draw start point marker
    _drawStartPoint(canvas, points.first);
  }

  /// Calculate plan view coordinates (heading + distance → XY)
  List<Offset> _calculatePlanCoordinates() {
    final points = <Offset>[];
    double x = 0.0;
    double y = 0.0;

    for (int i = 0; i < surveyData.length; i++) {
      if (i > 0) {
        final deltaDistance = surveyData[i].distance - surveyData[i - 1].distance;
        // Use heading from point i-1 (the starting point of this leg)
        final headingRad = surveyData[i - 1].heading * math.pi / 180;

        // North is up (negative Y), East is right (positive X)
        x += deltaDistance * math.sin(headingRad);
        y -= deltaDistance * math.cos(headingRad);
      }

      points.add(Offset(x, y));
    }

    return points;
  }

  /// Calculate elevation view coordinates (distance → X, depth → Y)
  List<Offset> _calculateElevationCoordinates() {
    final points = <Offset>[];
    double totalDist = 0.0;

    for (int i = 0; i < surveyData.length; i++) {
      if (i > 0) {
        totalDist += surveyData[i].distance - surveyData[i - 1].distance;
      }

      // Y is depth (positive downward in cave convention)
      final y = surveyData[i].depth;
      points.add(Offset(totalDist, y));
    }

    return points;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1 / scale;

    const gridSpacing = 5.0; // meters

    // Calculate visible range in world coordinates
    final extent = math.max(size.width, size.height) / scale * 1.5;

    // Calculate grid start positions aligned to gridSpacing in world space
    final startX = (-extent / gridSpacing).floor() * gridSpacing;
    final endX = (extent / gridSpacing).ceil() * gridSpacing;
    final startY = (-extent / gridSpacing).floor() * gridSpacing;
    final endY = (extent / gridSpacing).ceil() * gridSpacing;

    // Vertical lines - draw in world space
    for (double x = startX; x <= endX; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = startY; y <= endY; y += gridSpacing) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        gridPaint,
      );
    }
  }

  void _drawSurveyLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2 / scale
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);
  }

  /// Draw left/right passage walls in plan view
  void _drawPlanPassageWalls(Canvas canvas, List<Offset> points) {
    final wallPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final wallLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1 / scale;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final surveyPoint = surveyData[i];

      // Draw walls for points with left/right dimensions
      if (surveyPoint.left > 0 || surveyPoint.right > 0) {
        final headingRad = surveyPoint.heading * math.pi / 180;
        final perpRad = headingRad + math.pi / 2; // Perpendicular to heading

        // Calculate left and right wall endpoints (in meters)
        final leftOffset = Offset(
          math.sin(perpRad) * surveyPoint.left,
          -math.cos(perpRad) * surveyPoint.left,
        );
        final rightOffset = Offset(
          -math.sin(perpRad) * surveyPoint.right,
          math.cos(perpRad) * surveyPoint.right,
        );

        // Draw wall endpoints
        if (surveyPoint.left > 0) {
          canvas.drawCircle(point + leftOffset, 3 / scale, wallPaint);
          canvas.drawLine(point, point + leftOffset, wallLinePaint);
        }
        if (surveyPoint.right > 0) {
          canvas.drawCircle(point + rightOffset, 3 / scale, wallPaint);
          canvas.drawLine(point, point + rightOffset, wallLinePaint);
        }
      }
    }
  }

  /// Draw up/down passage height in elevation view
  void _drawElevationPassageHeight(Canvas canvas, List<Offset> points) {
    final wallPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final wallLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1 / scale;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final surveyPoint = surveyData[i];

      // Draw height for points with up/down dimensions
      if (surveyPoint.up > 0 || surveyPoint.down > 0) {
        // Vertical lines for up/down (in meters)
        final upOffset = Offset(0, -surveyPoint.up);
        final downOffset = Offset(0, surveyPoint.down);

        // Draw endpoints
        if (surveyPoint.up > 0) {
          canvas.drawCircle(point + upOffset, 3 / scale, wallPaint);
          canvas.drawLine(point, point + upOffset, wallLinePaint);
        }
        if (surveyPoint.down > 0) {
          canvas.drawCircle(point + downOffset, 3 / scale, wallPaint);
          canvas.drawLine(point, point + downOffset, wallLinePaint);
        }
      }
    }
  }

  /// Draw points with labels
  void _drawPointsWithLabels(Canvas canvas, List<Offset> points) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final surveyPoint = surveyData[i];

      // Draw point (size scales with zoom)
      final pointPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 5 / scale, pointPaint);

      // Draw label with background
      final textSpan = TextSpan(
        text: '${surveyPoint.recordNumber}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11 / scale,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Label background
      final labelOffset = Offset(point.dx + 8 / scale, point.dy - 8 / scale);
      final bgRect = Rect.fromLTWH(
        labelOffset.dx - 2 / scale,
        labelOffset.dy - 2 / scale,
        textPainter.width,
        textPainter.height,
      );

      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(3 / scale)),
        bgPaint,
      );

      // Paint label
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawStartPoint(Canvas canvas, Offset point) {
    final startPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 8 / scale, startPaint);

    // Draw "S" for start
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 / scale,
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
        oldDelegate.rotation != rotation ||
        oldDelegate.viewMode != viewMode;
  }
}
