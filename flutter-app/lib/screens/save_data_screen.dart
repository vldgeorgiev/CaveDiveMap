import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_data.dart';
import '../services/storage_service.dart';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';

/// Screen for entering manual survey point data
class SaveDataScreen extends StatefulWidget {
  const SaveDataScreen({super.key});

  @override
  State<SaveDataScreen> createState() => _SaveDataScreenState();
}

class _SaveDataScreenState extends State<SaveDataScreen> {
  // Current parameter being edited (cyclic: depth -> left -> right -> up -> down -> depth...)
  int _currentParameter = 0;
  final List<String> _parameters = ['Depth', 'Left', 'Right', 'Up', 'Down'];

  // Values for manual point
  double _depth = 0.0;
  double _left = 0.0;
  double _right = 0.0;
  double _up = 0.0;
  double _down = 0.0;

  void _cycleParameter() {
    setState(() {
      _currentParameter = (_currentParameter + 1) % _parameters.length;
    });
  }

  void _adjustCurrentParameter(double delta) {
    setState(() {
      switch (_currentParameter) {
        case 0: // Depth
          _depth = (_depth + delta).clamp(0.0, 200.0);
          break;
        case 1: // Left
          _left = (_left + delta).clamp(0.0, 100.0);
          break;
        case 2: // Right
          _right = (_right + delta).clamp(0.0, 100.0);
          break;
        case 3: // Up
          _up = (_up + delta).clamp(0.0, 100.0);
          break;
        case 4: // Down
          _down = (_down + delta).clamp(0.0, 100.0);
          break;
      }
    });
  }

  Future<void> _saveManualPoint() async {
    final magnetometerService = context.read<MagnetometerService>();
    final compassService = context.read<CompassService>();
    final storageService = context.read<StorageService>();

    final manualPoint = SurveyData(
      recordNumber: magnetometerService.currentPointNumber + 1,
      distance: magnetometerService.totalDistance,
      heading: compassService.heading,
      depth: _depth,  // Use manually entered depth
      left: _left,
      right: _right,
      up: _up,
      down: _down,
      rtype: 'manual',
      timestamp: DateTime.now(),
    );

    await storageService.saveSurveyPoint(manualPoint);

    // Increment point counter (manual point counts as a point)
    magnetometerService.incrementPointNumber();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manual point ${manualPoint.recordNumber} saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Save Manual Point'),
        backgroundColor: Colors.grey[900],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer2<MagnetometerService, CompassService>(
                builder: (context, magnetometer, compass, child) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      // Current sensor readings (read-only)
                      _buildReadOnlyRow('Point', '${magnetometer.currentPointNumber + 1}'),
                      const SizedBox(height: 12),
                      _buildReadOnlyRow('Distance', '${magnetometer.totalDistance.toStringAsFixed(2)} m'),
                      const SizedBox(height: 12),
                      _buildReadOnlyRow('Heading', '${compass.heading.toStringAsFixed(1)}°'),
                      const SizedBox(height: 12),
                      _buildReadOnlyRow('Depth', '${magnetometer.currentDepth.toStringAsFixed(1)} m'),

                      const SizedBox(height: 40),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 20),

                      // Passage dimensions header
                      Text(
                        'Passage Dimensions',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Active parameter selector
                      GestureDetector(
                        onTap: _cycleParameter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Editing: ${_parameters[_currentParameter]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Current parameter adjustment
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAdjustButton('-', () => _adjustCurrentParameter(-1.0)),
                          const SizedBox(width: 30),
                          _buildParameterValue(_getCurrentParameterValue()),
                          const SizedBox(width: 30),
                          _buildAdjustButton('+', () => _adjustCurrentParameter(1.0)),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // All dimensions display
                      _buildDimensionsGrid(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveManualPoint,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Manual Point'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        onLongPress: () {
          // TODO: Implement rapid increment/decrement on long press
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildParameterValue(double value) {
    return Column(
      children: [
        Text(
          _parameters[_currentParameter],
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} m',
          style: const TextStyle(
            color: Colors.cyan,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDimensionItem('Depth', _depth, 0),
              _buildDimensionItem('Left', _left, 1),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDimensionItem('Right', _right, 2),
              _buildDimensionItem('Up', _up, 3),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDimensionItem('Down', _down, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionItem(String label, double value, int index) {
    final isActive = _currentParameter == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[900] : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue[300] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)} m',
            style: TextStyle(
              color: isActive ? Colors.cyan : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _getCurrentParameterValue() {
    switch (_currentParameter) {
      case 0:
        return _depth;
      case 1:
        return _left;
      case 2:
        return _right;
      case 3:
        return _up;
      case 4:
        return _down;
      default:
        return 0.0;
    }
  }
}
