import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../services/magnetometer_service.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _wheelCircumferenceController;
  late TextEditingController _minPeakThresholdController;
  late TextEditingController _maxPeakThresholdController;
  late TextEditingController _surveyNameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _wheelCircumferenceController = TextEditingController(
      text: settings.wheelCircumference.toStringAsFixed(3),
    );
    _minPeakThresholdController = TextEditingController(
      text: settings.minPeakThreshold.toStringAsFixed(1),
    );
    _maxPeakThresholdController = TextEditingController(
      text: '200.0',  // Default max threshold
    );
    _surveyNameController = TextEditingController(
      text: settings.surveyName,
    );

    // Start magnetometer service for live sensor readout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MagnetometerService>().startListening();
    });
  }

  @override
  void dispose() {
    _wheelCircumferenceController.dispose();
    _minPeakThresholdController.dispose();
    _maxPeakThresholdController.dispose();
    _surveyNameController.dispose();
    // Note: Don't stop magnetometer here as main screen might still need it
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settings = context.read<Settings>();

    final wheelCircumference = double.tryParse(_wheelCircumferenceController.text);
    final minPeakThreshold = double.tryParse(_minPeakThresholdController.text);

    if (wheelCircumference == null || wheelCircumference <= 0) {
      _showError('Wheel circumference must be a positive number');
      return;
    }

    if (minPeakThreshold == null || minPeakThreshold < 0) {
      _showError('Peak threshold must be a non-negative number');
      return;
    }

    settings.updateWheelCircumference(wheelCircumference);
    settings.updateMinPeakThreshold(minPeakThreshold);
    settings.updateSurveyName(_surveyNameController.text);

    final storageService = context.read<StorageService>();
    await storageService.saveSettings(settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _exportData(String format) async {
    final storageService = context.read<StorageService>();
    final exportService = context.read<ExportService>();
    final settings = context.read<Settings>();

    final allData = await storageService.getAllSurveyData();

    if (allData.isEmpty) {
      _showError('No survey data to export');
      return;
    }

    try {
      if (format == 'csv') {
        await exportService.exportToCSV(allData, settings.surveyName);
      } else if (format == 'therion') {
        await exportService.exportToTherion(allData, settings.surveyName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${allData.length} points as $format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: 'CaveDiveMap',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.explore, size: 48, color: Colors.blue),
      children: [
        const Text(
          'Cross-platform cave diving survey application using magnetometer-based distance measurement.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Measures underwater cave passages with a 3D-printed wheel device and magnetic sensor.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Features:\n'
          '• Automatic distance measurement\n'
          '• Manual tie-off points\n'
          '• Live 2D map view\n'
          '• CSV and Therion export\n',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.grey[900],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Survey Configuration
            _buildSectionHeader('Survey Configuration'),
            _buildTextField(
              controller: _surveyNameController,
              label: 'Survey Name',
              hint: 'Enter cave/site name',
            ),
            const SizedBox(height: 20),

            // Hardware Configuration
            _buildSectionHeader('Hardware Configuration'),
            _buildTextField(
              controller: _wheelCircumferenceController,
              label: 'Wheel Circumference (m)',
              hint: '0.263',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Measure your 3D-printed wheel diameter and calculate circumference: π × diameter',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Sensor Configuration
            _buildSectionHeader('Sensor Configuration'),
            _buildTextField(
              controller: _minPeakThresholdController,
              label: 'Minimum Peak Threshold (μT)',
              hint: '50.0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _maxPeakThresholdController,
              label: 'Maximum Peak Threshold (μT)',
              hint: '200.0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Min/Max magnetic field strength to detect wheel rotation. Adjust if getting false detections or missing rotations.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Live Magnetometer Readout
            _buildSectionHeader('Magnetometer Sensor'),
            Consumer<MagnetometerService>(
              builder: (context, magnetometer, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildSensorRow('X:', magnetometer.magnetometerX, 'μT'),
                      const SizedBox(height: 8),
                      _buildSensorRow('Y:', magnetometer.magnetometerY, 'μT'),
                      const SizedBox(height: 8),
                      _buildSensorRow('Z:', magnetometer.magnetometerZ, 'μT'),
                      const Divider(color: Colors.grey, height: 24),
                      _buildSensorRow('Magnitude:', magnetometer.magneticStrength, 'μT', highlight: true),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Data Export
            _buildSectionHeader('Data Export'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('therion'),
                    icon: const Icon(Icons.terrain),
                    label: const Text('Export Therion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // About
            _buildSectionHeader('About'),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('About CaveDiveMap', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _showAboutDialog,
              tileColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.orange),
              title: const Text('View on GitHub', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.open_in_new, color: Colors.grey),
              onTap: () {
                // TODO: Open GitHub repository
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GitHub link: github.com/f0xdude/CaveDiveMap')),
                );
              },
              tileColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyan,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, double value, String unit, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? Colors.cyan : Colors.grey[400],
            fontSize: 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} $unit',
          style: TextStyle(
            color: highlight ? Colors.cyan : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
