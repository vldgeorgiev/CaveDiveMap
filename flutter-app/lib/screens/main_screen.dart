import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';
import '../services/storage_service.dart';
import 'save_data_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';

/// Main survey screen - displays real-time sensor data and controls
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Start sensor services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MagnetometerService>().startListening();
      context.read<CompassService>().startListening();
    });
  }

  @override
  void dispose() {
    // Stop sensors when leaving screen
    context.read<MagnetometerService>().stopListening();
    context.read<CompassService>().stopListening();
    super.dispose();
  }

  void _navigateToSaveData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaveDataScreen()),
    );
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _resetSurvey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Survey'),
        content: const Text('Are you sure you want to reset all survey data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final storageService = context.read<StorageService>();
      await storageService.clearAllData();
      context.read<MagnetometerService>().reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey data reset')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CaveDiveMap'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sensor data display
            Expanded(
              child: Consumer2<MagnetometerService, CompassService>(
                builder: (context, magnetometer, compass, child) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      // Point number
                      _buildDataRow(
                        'Point',
                        '${magnetometer.currentPointNumber}',
                        fontSize: 36,
                      ),
                      const SizedBox(height: 20),

                      // Distance
                      _buildDataRow(
                        'Distance',
                        '${magnetometer.totalDistance.toStringAsFixed(2)} m',
                        fontSize: 48,
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 20),

                      // Heading
                      _buildDataRow(
                        'Heading',
                        '${compass.heading.toStringAsFixed(1)}°',
                        fontSize: 36,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),

                      // Depth (read-only display)
                      _buildDataRow(
                        'Depth',
                        '${magnetometer.currentDepth.toStringAsFixed(1)} m',
                        fontSize: 36,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(height: 30),

                      // Magnetic field strength indicator
                      _buildMagneticStrengthIndicator(magnetometer.magneticStrength),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom control buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToSaveData,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Manual Point'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToMap,
                          icon: const Icon(Icons.map),
                          label: const Text('View Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetSurvey,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Widget _buildDataRow(String label, String value, {
    double fontSize = 32,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildMagneticStrengthIndicator(double strength) {
    // Normalize strength to 0-100 range for display
    final normalizedStrength = (strength / 100.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          'Magnetic Field',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: normalizedStrength,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              normalizedStrength > 0.7 ? Colors.green :
              normalizedStrength > 0.4 ? Colors.orange : Colors.red,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${strength.toStringAsFixed(1)} μT',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
