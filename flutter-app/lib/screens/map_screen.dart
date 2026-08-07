import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/magnetometer_service.dart';
import '../services/export_service.dart';
import '../utils/theme_extensions.dart';
import 'dart:math' as math;

/// Map view mode (Plan or Elevation)
enum MapViewMode { plan, elevation }

/// Map visualization screen with 2D cave survey rendering
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Separate state for plan view
  double _planScale = 20.0;
  Offset _planOffset = Offset.zero;
  double _planRotation = 0.0;

  // Separate state for elevation view
  double _elevationScale = 20.0;
  Offset _elevationOffset = Offset.zero;

  // Gesture tracking
  Offset _lastFocalPoint = Offset.zero;
  double _baseRotation = 0.0;
  double _baseScale = 20.0;

  MapViewMode _viewMode = MapViewMode.plan;
  bool _isFirstLoadPlan = true;
  bool _isFirstLoadElevation = true;
  bool _isOverlayInteractionActive = false;

  // Getters for current view's state
  double get _scale =>
      _viewMode == MapViewMode.plan ? _planScale : _elevationScale;
  set _scale(double value) {
    if (_viewMode == MapViewMode.plan) {
      _planScale = value;
    } else {
      _elevationScale = value;
    }
  }

  Offset get _offset =>
      _viewMode == MapViewMode.plan ? _planOffset : _elevationOffset;
  set _offset(Offset value) {
    if (_viewMode == MapViewMode.plan) {
      _planOffset = value;
    } else {
      _elevationOffset = value;
    }
  }

  double get _rotation => _viewMode == MapViewMode.plan ? _planRotation : 0.0;
  set _rotation(double value) {
    if (_viewMode == MapViewMode.plan) {
      _planRotation = value;
    }
  }

  @override
  void initState() {
    super.initState();
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
      body: Consumer<StorageService>(
        builder: (context, storageService, _) {
          final stations = storageService.stations;
          final surveyLegs = storageService.legs;

          if (stations.isEmpty) {
            return const Center(
              child: Text(
                'No survey data yet.\nStart surveying to see the map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Auto-fit on first load for each view mode
          final needsAutoFit = _viewMode == MapViewMode.plan
              ? _isFirstLoadPlan
              : _isFirstLoadElevation;

          if (needsAutoFit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performAutoFit(stations, surveyLegs);
              if (_viewMode == MapViewMode.plan) {
                _isFirstLoadPlan = false;
              } else {
                _isFirstLoadElevation = false;
              }
            });
          }

          return Stack(
            children: [
              // Map canvas (bottom layer)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    if (_isOverlayInteractionActive) return;
                    _lastFocalPoint = details.focalPoint;
                    _baseScale = _scale;
                    _baseRotation = _rotation;
                  },
                  onScaleUpdate: (details) {
                    if (_isOverlayInteractionActive) return;
                    setState(() {
                      // Zoom - update scale first
                      _scale = (_baseScale * details.scale).clamp(1.0, 100.0);

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
                    key: const Key('map_canvas'),
                    painter: CaveMapPainter(
                      stations: stations,
                      legs: surveyLegs,
                      scale: _scale,
                      offset: _offset,
                      rotation: _rotation,
                      viewMode: _viewMode,
                      activeStationId: storageService.currentDepartureStationId,
                    ),
                  ),
                ),
              ),

              // Long-press layer for station selection (separate from pan/zoom)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (details) {
                    if (_isOverlayInteractionActive) return;

                    // Block station switch if distance measured since last save
                    final magnetometer = context.read<MagnetometerService>();
                    if (magnetometer.totalDistance > storageService.departureDistance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Save measured section before switching stations'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final renderBox = context.findRenderObject() as RenderBox;
                    final size = renderBox.size;
                    final painter = CaveMapPainter(
                      stations: stations,
                      legs: surveyLegs,
                      scale: _scale,
                      offset: _offset,
                      rotation: _rotation,
                      viewMode: _viewMode,
                      activeStationId: storageService.currentDepartureStationId,
                    );
                    final hitId = painter.hitTestStation(details.localPosition, size);
                    if (hitId != null) {
                      // BFS to compute cumulative distance to the selected station
                      final visited = <int>{};
                      final queue = <int>[stations.first.id!];
                      final distTo = <int, double>{stations.first.id!: 0};
                      final adj = <int, List<SurveyLeg>>{};
                      for (final l in surveyLegs) {
                        adj.putIfAbsent(l.fromStationId, () => []).add(l);
                      }
                      while (queue.isNotEmpty) {
                        final cur = queue.removeAt(0);
                        if (visited.contains(cur)) continue;
                        visited.add(cur);
                        for (final l in adj[cur] ?? []) {
                          if (!visited.contains(l.toStationId)) {
                            distTo[l.toStationId] = (distTo[cur] ?? 0) + l.distance;
                            queue.add(l.toStationId);
                          }
                        }
                      }
                      storageService.setCurrentDepartureStationId(hitId, isStationSwitch: true);
                      storageService.setDepartureDistance(magnetometer.totalDistance);
                      setState(() {});
                    }
                  },
                ),
              ),

              // View mode toggle (top layer)
              Positioned(top: 16, left: 16, child: _buildViewModeToggle()),

              // Scale indicator
              Positioned(bottom: 16, left: 16, child: _buildScaleIndicator()),

              // North arrow indicator (plan view only)
              if (_viewMode == MapViewMode.plan)
                Positioned(top: 16, right: 16, child: _buildNorthArrow()),

              // Stats overlay
              Positioned(
                top: 80,
                left: 16,
                child: _buildStatsOverlay(stations, surveyLegs),
              ),

              // Export buttons
              Positioned(bottom: 20, right: 20, child: _buildExportButtons()),
            ],
          );
        },
      ),
    );
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
            const Key('map_toggle_plan'),
          ),
          _buildToggleButton(
            'Elevation',
            MapViewMode.elevation,
            const Key('map_toggle_elevation'),
          ),
        ],
      ),
    );
  }

  void _setOverlayInteractionActive(bool active) {
    if (_isOverlayInteractionActive == active || !mounted) return;
    setState(() {
      _isOverlayInteractionActive = active;
    });
  }

  Widget _buildToggleButton(String label, MapViewMode mode, Key key) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      key: key,
      onTapDown: (_) => _setOverlayInteractionActive(true),
      onTapUp: (_) => _setOverlayInteractionActive(false),
      onTapCancel: () => _setOverlayInteractionActive(false),
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
              mode == MapViewMode.plan ? Icons.map : Icons.show_chart,
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

  /// Auto-fit view to show all stations (async version for button)
  void _autoFitView() {
    final storageService = context.read<StorageService>();
    final stations = storageService.stations;
    final legs = storageService.legs;

    _performAutoFit(stations, legs);
  }

  /// Perform auto-fit with provided stations and legs
  void _performAutoFit(List<Station> stations, List<SurveyLeg> legs) {
    if (stations.isEmpty) return;

    final size = MediaQuery.of(context).size;
    final bounds = _calculateSurveyBounds(stations, legs);

    if (bounds.width == 0 || bounds.height == 0) {
      // Single point or zero-size bounds
      setState(() {
        if (_viewMode == MapViewMode.plan) {
          _planScale = 20.0;
          _planOffset = Offset.zero;
          _planRotation = 0.0;
        } else {
          _elevationScale = 20.0;
          _elevationOffset = Offset.zero;
        }
      });
      return;
    }

    setState(() {
      final padding = 0.2; // 20% margin for better visibility
      final scaleX = size.width / (bounds.width * (1 + padding * 2));
      final scaleY = size.height / (bounds.height * (1 + padding * 2));
      final calculatedScale = math
          .min(scaleX, scaleY)
          .clamp(1.0, double.infinity);
      final calculatedOffset = Offset(-bounds.center.dx, -bounds.center.dy);

      if (_viewMode == MapViewMode.plan) {
        _planRotation = 0.0;
        _planScale = calculatedScale;
        _planOffset = calculatedOffset;
      } else {
        _elevationScale = calculatedScale;
        _elevationOffset = calculatedOffset;
      }
    });
  }

  /// Calculate bounding box by traversing legs graph
  Rect _calculateSurveyBounds(List<Station> stations, List<SurveyLeg> legs) {
    if (stations.isEmpty) return Rect.zero;

    final positions = _computeStationPositions(stations, legs);

    if (_viewMode == MapViewMode.plan) {
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      final stationMap = {for (final s in stations) s.id: s};

      for (final entry in positions.entries) {
        final pos = entry.value;

        // Get max LRUD from legs connected to this station
        final connectedLegs = legs.where(
            (l) => l.fromStationId == entry.key || l.toStationId == entry.key);
        if (connectedLegs.isEmpty) {
          minX = math.min(minX, pos.dx);
          maxX = math.max(maxX, pos.dx);
          minY = math.min(minY, pos.dy);
          maxY = math.max(maxY, pos.dy);
          continue;
        }
        final leg = connectedLegs.first;
        final headingRad = leg.heading * math.pi / 180;
        final perpRad = headingRad + math.pi / 2;

        final lx = pos.dx - math.sin(perpRad) * leg.left;
        final ly = pos.dy + math.cos(perpRad) * leg.left;
        final rx = pos.dx + math.sin(perpRad) * leg.right;
        final ry = pos.dy - math.cos(perpRad) * leg.right;

        minX = math.min(minX, math.min(math.min(lx, rx), pos.dx));
        maxX = math.max(maxX, math.max(math.max(lx, rx), pos.dx));
        minY = math.min(minY, math.min(math.min(ly, ry), pos.dy));
        maxY = math.max(maxY, math.max(math.max(ly, ry), pos.dy));
      }

      return Rect.fromLTRB(minX, minY, maxX, maxY);
    } else {
      // Elevation view
      double maxDist = 0;
      double minDepth = double.infinity;
      double maxDepth = -double.infinity;

      final stationMap = {for (final s in stations) s.id: s};
      // Build map of max up/down per station from connected legs
      final stationUp = <int, double>{};
      final stationDown = <int, double>{};
      for (final leg in legs) {
        for (final sid in [leg.fromStationId, leg.toStationId]) {
          stationUp[sid] = math.max(stationUp[sid] ?? 0, leg.up);
          stationDown[sid] = math.max(stationDown[sid] ?? 0, leg.down);
        }
      }

      for (final entry in positions.entries) {
        final pos = entry.value;
        final station = stationMap[entry.key];
        if (station == null) continue;

        maxDist = math.max(maxDist, pos.dx);
        minDepth = math.min(minDepth, station.depth - (stationDown[entry.key] ?? 0));
        maxDepth = math.max(maxDepth, station.depth + (stationUp[entry.key] ?? 0));
      }

      return Rect.fromLTRB(0, minDepth, maxDist, maxDepth);
    }
  }

  /// Compute station positions by traversing the leg graph (BFS from first station)
  Map<int, Offset> _computeStationPositions(
      List<Station> stations, List<SurveyLeg> legs) {
    if (stations.isEmpty) return {};

    final stationMap = {for (final s in stations) s.id: s};
    final positions = <int, Offset>{};

    // Build adjacency: fromStationId → list of legs
    final adjacency = <int, List<SurveyLeg>>{};
    for (final leg in legs) {
      adjacency.putIfAbsent(leg.fromStationId, () => []).add(leg);
    }

    // BFS from the first station
    final startId = stations.first.id!;
    positions[startId] = Offset.zero;
    final queue = <int>[startId];
    double cumulativeDistance = 0;

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final currentPos = positions[currentId]!;
      final currentStation = stationMap[currentId];

      for (final leg in adjacency[currentId] ?? []) {
        if (positions.containsKey(leg.toStationId)) continue;

        final toStation = stationMap[leg.toStationId];
        if (toStation == null) continue;

        if (_viewMode == MapViewMode.plan) {
          final headingRad = leg.heading * math.pi / 180;
          final dx = leg.distance * math.sin(headingRad);
          final dy = -leg.distance * math.cos(headingRad);
          positions[leg.toStationId] = Offset(currentPos.dx + dx, currentPos.dy + dy);
        } else {
          // Elevation: X = cumulative distance along path, Y = depth
          cumulativeDistance += leg.distance;
          positions[leg.toStationId] = Offset(cumulativeDistance, toStation.depth);
        }

        queue.add(leg.toStationId);
      }
    }

    // Handle orphan stations (no legs)
    for (final station in stations) {
      if (!positions.containsKey(station.id)) {
        positions[station.id!] = _viewMode == MapViewMode.plan
            ? Offset.zero
            : Offset(0, station.depth);
      }
    }

    return positions;
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

  Widget _buildNorthArrow() {
    final isNorthUp = _planRotation == 0.0;
    return GestureDetector(
      onTap: isNorthUp
          ? null
          : () => setState(() => _planRotation = 0.0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: isNorthUp ? Colors.cyan : Colors.orange,
            width: 2,
          ),
        ),
        child: Transform.rotate(
          angle: _planRotation,
          child: CustomPaint(painter: NorthArrowPainter()),
        ),
      ),
    );
  }

  Widget _buildExportButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: const Key('map_export_csv'),
          onTapDown: (_) => _setOverlayInteractionActive(true),
          onTapUp: (_) => _setOverlayInteractionActive(false),
          onTapCancel: () => _setOverlayInteractionActive(false),
          onTap: _exportCSV,
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
        GestureDetector(
          key: const Key('map_export_th'),
          onTapDown: (_) => _setOverlayInteractionActive(true),
          onTapUp: (_) => _setOverlayInteractionActive(false),
          onTapCancel: () => _setOverlayInteractionActive(false),
          onTap: _exportTherion,
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
      final stations = storageService.stations;
      final surveyLegs = storageService.legs;

      if (stations.isEmpty) {
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
      final file = await exportService.exportToCSV(stations, surveyLegs, fileName);
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
      final stations = storageService.stations;
      final surveyLegs = storageService.legs;

      if (stations.isEmpty) {
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
      final file = await exportService.exportToTherion(stations, surveyLegs, surveyName);
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

  Widget _buildStatsOverlay(
    List<Station> stations,
    List<SurveyLeg> legs,
  ) {
    final stationCount = stations.length;
    final totalDistance = legs.fold(0.0, (sum, leg) => sum + leg.distance);

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
            'Stations: $stationCount',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Legs: ${legs.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
  final List<Station> stations;
  final List<SurveyLeg> legs;
  final double scale;
  final Offset offset;
  final double rotation;
  final MapViewMode viewMode;
  final int? activeStationId;

  CaveMapPainter({
    required this.stations,
    required this.legs,
    required this.scale,
    required this.offset,
    required this.rotation,
    required this.viewMode,
    this.activeStationId,
  });

  /// Convert screen position to world coordinates and find nearest station
  int? hitTestStation(Offset screenPos, Size size) {
    final worldPos = screenToWorld(screenPos, size);
    final positions = _computePositions();
    // Large touch radius for gloved underwater use
    final hitRadius = 2.0 + 25 / scale;

    int? closest;
    double closestDist = double.infinity;
    for (final entry in positions.entries) {
      final d = (entry.value - worldPos).distance;
      if (d < hitRadius && d < closestDist) {
        closestDist = d;
        closest = entry.key;
      }
    }
    return closest;
  }

  /// Convert screen coordinates to world coordinates
  Offset screenToWorld(Offset screenPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var p = (screenPos - center) / scale;
    if (viewMode == MapViewMode.plan) {
      final cosR = math.cos(-rotation);
      final sinR = math.sin(-rotation);
      p = Offset(p.dx * cosR - p.dy * sinR, p.dx * sinR + p.dy * cosR);
    }
    return p - offset;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    if (viewMode == MapViewMode.plan) {
      canvas.rotate(rotation);
    }

    canvas.translate(offset.dx, offset.dy);

    _drawGrid(canvas, size);

    if (stations.isEmpty) return;

    if (viewMode == MapViewMode.plan) {
      _drawPlanView(canvas);
    } else {
      _drawElevationView(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridSpacing = scale >= 10.0 ? 1.0 : 10.0;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.5 / scale;

    final halfWidth = size.width / 2 / scale;
    final halfHeight = size.height / 2 / scale;
    final margin = math.max(halfWidth, halfHeight) * 0.5;

    final centerX = -offset.dx;
    final centerY = -offset.dy;

    final startX =
        ((centerX - halfWidth - margin) / gridSpacing).floor() * gridSpacing;
    final endX =
        ((centerX + halfWidth + margin) / gridSpacing).ceil() * gridSpacing;
    final startY =
        ((centerY - halfHeight - margin) / gridSpacing).floor() * gridSpacing;
    final endY =
        ((centerY + halfHeight + margin) / gridSpacing).ceil() * gridSpacing;

    for (double x = startX; x <= endX; x += gridSpacing) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), gridPaint);
    }

    for (double y = startY; y <= endY; y += gridSpacing) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
    }
  }

  /// Compute station positions by BFS over leg graph
  Map<int, Offset> _computePositions() {
    if (stations.isEmpty) return {};

    final stationMap = {for (final s in stations) s.id: s};
    final positions = <int, Offset>{};
    final adjacency = <int, List<SurveyLeg>>{};
    for (final leg in legs) {
      adjacency.putIfAbsent(leg.fromStationId, () => []).add(leg);
    }

    final startId = stations.first.id!;
    positions[startId] = viewMode == MapViewMode.plan
        ? Offset.zero
        : Offset(0, stations.first.depth);
    final queue = <int>[startId];
    double cumulativeDist = 0;

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final currentPos = positions[currentId]!;

      for (final leg in adjacency[currentId] ?? []) {
        if (positions.containsKey(leg.toStationId)) continue;
        final toStation = stationMap[leg.toStationId];
        if (toStation == null) continue;

        if (viewMode == MapViewMode.plan) {
          final headingRad = leg.heading * math.pi / 180;
          positions[leg.toStationId] = Offset(
            currentPos.dx + leg.distance * math.sin(headingRad),
            currentPos.dy - leg.distance * math.cos(headingRad),
          );
        } else {
          cumulativeDist += leg.distance;
          positions[leg.toStationId] = Offset(cumulativeDist, toStation.depth);
        }
        queue.add(leg.toStationId);
      }
    }

    // Orphan stations
    for (final s in stations) {
      if (!positions.containsKey(s.id)) {
        positions[s.id!] = viewMode == MapViewMode.plan
            ? Offset.zero
            : Offset(0, s.depth);
      }
    }

    return positions;
  }

  void _drawPlanView(Canvas canvas) {
    final positions = _computePositions();
    if (positions.isEmpty) return;

    _drawSurveyLegs(canvas, positions);
    _drawPlanPassageWalls(canvas, positions);
    _drawStationsWithLabels(canvas, positions);
    _drawStartPoint(canvas, positions[stations.first.id]!);
  }

  void _drawElevationView(Canvas canvas) {
    final positions = _computePositions();
    if (positions.isEmpty) return;

    _drawSurveyLegs(canvas, positions);
    _drawElevationPassageHeight(canvas, positions);
    _drawStationsWithLabels(canvas, positions);
    _drawStartPoint(canvas, positions[stations.first.id]!);
  }

  void _drawSurveyLegs(Canvas canvas, Map<int, Offset> positions) {
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2 / scale
      ..style = PaintingStyle.stroke;

    for (final leg in legs) {
      final from = positions[leg.fromStationId];
      final to = positions[leg.toStationId];
      if (from != null && to != null) {
        canvas.drawLine(from, to, linePaint);
      }
    }
  }

  void _drawPlanPassageWalls(Canvas canvas, Map<int, Offset> positions) {
    final wallPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final wallLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1 / scale;

    for (final leg in legs) {
      // Draw LRUD at the to-station using leg heading
      final point = positions[leg.toStationId];
      if (point == null) continue;
      if (leg.left <= 0 && leg.right <= 0) continue;

      final headingRad = leg.heading * math.pi / 180;
      final perpRad = headingRad + math.pi / 2;

      if (leg.left > 0) {
        final leftOffset = Offset(
          -math.sin(perpRad) * leg.left,
          math.cos(perpRad) * leg.left,
        );
        canvas.drawCircle(point + leftOffset, 3 / scale, wallPaint);
        canvas.drawLine(point, point + leftOffset, wallLinePaint);
      }
      if (leg.right > 0) {
        final rightOffset = Offset(
          math.sin(perpRad) * leg.right,
          -math.cos(perpRad) * leg.right,
        );
        canvas.drawCircle(point + rightOffset, 3 / scale, wallPaint);
        canvas.drawLine(point, point + rightOffset, wallLinePaint);
      }
    }
  }

  void _drawElevationPassageHeight(Canvas canvas, Map<int, Offset> positions) {
    final wallPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final wallLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1 / scale;

    for (final leg in legs) {
      final point = positions[leg.toStationId];
      if (point == null) continue;

      if (leg.up > 0) {
        final upOffset = Offset(0, -leg.up);
        canvas.drawCircle(point + upOffset, 3 / scale, wallPaint);
        canvas.drawLine(point, point + upOffset, wallLinePaint);
      }
      if (leg.down > 0) {
        final downOffset = Offset(0, leg.down);
        canvas.drawCircle(point + downOffset, 3 / scale, wallPaint);
        canvas.drawLine(point, point + downOffset, wallLinePaint);
      }
    }
  }

  void _drawStationsWithLabels(Canvas canvas, Map<int, Offset> positions) {
    for (final station in stations) {
      final point = positions[station.id];
      if (point == null) continue;

      final isActive = station.id == activeStationId;

      // Draw active station highlight
      if (isActive) {
        final ringPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 / scale;
        canvas.drawCircle(point, 14 / scale, ringPaint);
      }

      final pointPaint = Paint()
        ..color = isActive ? Colors.orange : Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 5 / scale, pointPaint);

      final textSpan = TextSpan(
        text: '${station.number}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelOffset = Offset(point.dx + 8 / scale, point.dy - 8 / scale);

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.scale(1 / scale);

      final bgRect = Rect.fromLTWH(
        -2,
        -2,
        textPainter.width + 4,
        textPainter.height + 4,
      );

      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
        bgPaint,
      );

      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
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
    return oldDelegate.stations != stations ||
        oldDelegate.legs != legs ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.rotation != rotation ||
        oldDelegate.viewMode != viewMode ||
        oldDelegate.activeStationId != activeStationId;
  }
}

/// Painter for north arrow indicator
class NorthArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowLength = size.height * 0.35;

    // Arrow pointing north (upward)
    final arrowPath = Path();
    final tipY = center.dy - arrowLength;
    final baseY = center.dy + arrowLength * 0.3;

    // Arrow head (triangle)
    arrowPath.moveTo(center.dx, tipY);
    arrowPath.lineTo(center.dx - arrowLength * 0.25, baseY);
    arrowPath.lineTo(center.dx + arrowLength * 0.25, baseY);
    arrowPath.close();

    // Draw filled arrow
    final arrowPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    // Draw arrow outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(arrowPath, outlinePaint);

    // Draw "N" letter
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + arrowLength * 0.5),
    );
  }

  @override
  bool shouldRepaint(NorthArrowPainter oldDelegate) => false;
}
