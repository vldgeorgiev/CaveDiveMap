import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';
import '../services/rotation_detection/rotation_algorithm.dart';
import '../utils/theme_extensions.dart';
import '../widgets/info_card.dart';
import '../widgets/monospaced_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'button_customization_screen.dart';
import 'survey_data_debug_screen.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _wheelDiameterController;
  late TextEditingController _minPeakThresholdController;
  late TextEditingController _maxPeakThresholdController;
  late TextEditingController _surveyNameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _wheelDiameterController = TextEditingController(
      text: (settings.wheelDiameter * 1000).toStringAsFixed(1),
    );
    _minPeakThresholdController = TextEditingController(
      text: settings.minPeakThreshold.toInt().toString(),
    );
    _maxPeakThresholdController = TextEditingController(
      text: settings.maxPeakThreshold.toInt().toString(),
    );
    _surveyNameController = TextEditingController(text: settings.surveyName);

    // Start magnetometer and compass services for live sensor readout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MagnetometerService>().startListening();
      context.read<CompassService>().startListening();
    });
  }

  @override
  void dispose() {
    _wheelDiameterController.dispose();
    _minPeakThresholdController.dispose();
    _maxPeakThresholdController.dispose();
    _surveyNameController.dispose();
    // Stop sensors when leaving settings
    context.read<MagnetometerService>().stopListening();
    context.read<CompassService>().stopListening();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settings = context.read<Settings>();

    final wheelDiameterMm = double.tryParse(_wheelDiameterController.text);
    final minPeakThreshold = double.tryParse(_minPeakThresholdController.text);
    final maxPeakThreshold = double.tryParse(_maxPeakThresholdController.text);

    if (wheelDiameterMm == null || wheelDiameterMm <= 0) {
      _showError('Wheel diameter must be a positive number');
      return;
    }

    if (minPeakThreshold == null || minPeakThreshold < 0) {
      _showError('Min peak threshold must be a non-negative number');
      return;
    }

    if (maxPeakThreshold == null || maxPeakThreshold < 0) {
      _showError('Max peak threshold must be a non-negative number');
      return;
    }

    if (maxPeakThreshold <= minPeakThreshold) {
      _showError('Max threshold must be greater than min threshold');
      return;
    }

    // Convert mm to meters for storage
    settings.updateWheelDiameter(wheelDiameterMm / 1000);
    settings.updateMinPeakThreshold(minPeakThreshold);
    settings.updateMaxPeakThreshold(maxPeakThreshold);
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      final timestamp = DateTime.now();
      final timeString =
          '${settings.surveyName}_'
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}';

      File file;
      if (format == 'csv') {
        file = await exportService.exportToCSV(allData, '$timeString.csv');
      } else {
        file = await exportService.exportToTherion(allData, timeString);
      }

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
            backgroundColor: format == 'csv'
                ? AppColors.actionExportCSV
                : AppColors.actionExportTherion,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  Future<void> _importData() async {
    final exportService = context.read<ExportService>();
    final storageService = context.read<StorageService>();

    // Check if data already exists
    final existingData = await storageService.getAllSurveyData();
    if (existingData.isNotEmpty) {
      _showError('Cannot import: existing survey data found.\n\nPlease reset survey data before importing.');
      return;
    }

    try {
      // Import CSV data
      final importedData = await exportService.importFromCSV();

      if (importedData.isEmpty) {
        _showError('No data found in CSV file');
        return;
      }

      // Show confirmation dialog
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            title: Text(
              'Import Survey Data',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Found ${importedData.length} survey points.\n\n'
              'Continue with import?',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionSave,
                ),
                child: Text(
                  'Import',
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return;
        }
      }

      // Save imported data
      for (final point in importedData) {
        await storageService.saveSurveyPoint(point);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${importedData.length} survey points',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.actionSave,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Import failed: $e');
    }
  }

  Future<void> _showAboutDialog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = '${packageInfo.version}';

    showAboutDialog(
      context: context,
      applicationName: 'CaveDiveMap',
      applicationVersion: version,
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
          '• Live 2D map view\n',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 32),
          color: Colors.red,
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cancel',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 32),
            color: AppColors.actionSave,
            onPressed: _saveSettings,
            tooltip: 'Save',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Survey Configuration Section
            _buildSectionHeader('Survey Configuration'),
            const SizedBox(height: 8),
            InfoCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _surveyNameController,
                    label: 'Survey Name',
                    hint: 'Enter cave/site name',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportData('csv'),
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.actionExportCSV,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportData('therion'),
                          icon: const Icon(Icons.map),
                          label: const Text('Export Therion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.actionExportTherion,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importData,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.actionSave,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wheel Settings Section
            _buildSectionHeader('Wheel Settings'),
            const SizedBox(height: 8),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _wheelDiameterController,
                    label: 'Diameter (mm)',
                    hint: '43.0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Measure wheel diameter in millimeters',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rotation Detection Algorithm Section
            _buildSectionHeader('Rotation Detection Algorithm'),
            const SizedBox(height: 8),
            Consumer2<Settings, MagnetometerService>(
              builder: (context, settings, magnetometer, child) {
                return InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAlgorithmSelector(settings, magnetometer),
                      if (settings.rotationAlgorithm == RotationAlgorithm.threshold) ...[
                        const Divider(height: 24),
                        _buildTextField(
                          controller: _minPeakThresholdController,
                          label: 'Min Peak Threshold (μT)',
                          hint: '50',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _maxPeakThresholdController,
                          label: 'Max Peak Threshold (μT)',
                          hint: '200',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Magnetic field range for peak detection',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (settings.rotationAlgorithm == RotationAlgorithm.pca) ...[
                        const Divider(height: 24),
                        _buildSignalQualityIndicator(magnetometer),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Sensor Configuration Section (removed - moved into algorithm section)
            // _buildSectionHeader('Sensor Configuration'),
            // const SizedBox(height: 8),
            // InfoCard(
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _buildTextField(
            //         controller: _minPeakThresholdController,
            //         label: 'Min Peak Threshold (μT)',
            //         hint: '50',
            //         keyboardType: TextInputType.number,
            //       ),
            //       const SizedBox(height: 8),
            //       _buildTextField(
            //         controller: _maxPeakThresholdController,
            //         label: 'Max Peak Threshold (μT)',
            //         hint: '200',
            //         keyboardType: TextInputType.number,
            //       ),
            //       const SizedBox(height: 2),
            //       Text(
            //         'Magnetic field range for wheel rotation detection',
            //         style: AppTextStyles.caption.copyWith(
            //           color: AppColors.textSecondary,
            //           fontStyle: FontStyle.italic,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 16),

            // Live Magnetometer Section
            _buildSectionHeader('Magnetic Field Readout'),
            const SizedBox(height: 8),
            Consumer2<MagnetometerService, CompassService>(
              builder: (context, magnetometer, compass, child) {
                return InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Magnetometer (μT)',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSensorRow('X', magnetometer.magnetometerX),
                      const SizedBox(height: 4),
                      _buildSensorRow('Y', magnetometer.magnetometerY),
                      const SizedBox(height: 4),
                      _buildSensorRow('Z', magnetometer.magnetometerZ),
                      const Divider(height: 20),
                      _buildSensorRow(
                        'Magnitude',
                        magnetometer.magneticStrength,
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compass',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSensorRow('Heading', compass.heading, suffix: '°'),
                      const SizedBox(height: 4),
                      _buildSensorRow(
                        'Accuracy',
                        compass.accuracy,
                        suffix: '°',
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Button Customization Section
            _buildSectionHeader('Interface'),
            const SizedBox(height: 8),
            Consumer<Settings>(
              builder: (context, settings, child) {
                return InfoCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Keep Screen On',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Prevent screen from dimming or locking during surveys',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: settings.keepScreenOn,
                        activeColor: AppColors.actionSave,
                        onChanged: (value) async {
                          settings.updateKeepScreenOn(value);
                          final storageService = context.read<StorageService>();
                          await storageService.saveSettings(settings);

                          // Apply wakelock immediately
                          if (value) {
                            WakelockPlus.enable();
                          } else {
                            WakelockPlus.disable();
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Fullscreen Mode',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Hide system UI bars for immersive experience',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: settings.fullscreen,
                        activeColor: AppColors.actionSave,
                        onChanged: (value) async {
                          settings.updateFullscreen(value);
                          final storageService = context.read<StorageService>();
                          await storageService.saveSettings(settings);

                          // Apply fullscreen mode immediately
                          if (value) {
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                          } else {
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.touch_app,
                          color: AppColors.textPrimary,
                        ),
                        title: Text(
                          'Button Customization',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Adjust button size and position',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ButtonCustomizationScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.table_chart,
                          color: AppColors.textPrimary,
                        ),
                        title: Text(
                          'Debug: Survey Data',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'View collected survey data in table format',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SurveyDataDebugScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Links Section
            _buildSectionHeader('Information'),
            const SizedBox(height: 8),
            InfoCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.help_outline,
                      color: AppColors.textPrimary,
                    ),
                    title: Text(
                      'Documentation',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () =>
                        _launchURL('https://github.com/vldgeorgiev/CaveDiveMap'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.print, color: AppColors.textPrimary),
                    title: Text(
                      '3D Print Files',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () =>
                        _launchURL('https://www.thingiverse.com/thing:6950056'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.info_outline,
                      color: AppColors.textPrimary,
                    ),
                    title: Text(
                      'About',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(
        color: AppColors.dataPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
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
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dataPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSensorRow(
    String label,
    double value, {
    String suffix = 'μT',
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: highlight ? AppColors.dataPrimary : AppColors.textSecondary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        MonospacedText(
          '${value.toStringAsFixed(2)} $suffix',
          style: AppTextStyles.body.copyWith(
            color: highlight ? AppColors.dataPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmSelector(Settings settings, MagnetometerService magnetometer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Method',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...RotationAlgorithm.values.map((algorithm) {
          final isSelected = settings.rotationAlgorithm == algorithm;
          return RadioListTile<RotationAlgorithm>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              _getAlgorithmName(algorithm),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _getAlgorithmDescription(algorithm),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: algorithm,
            groupValue: settings.rotationAlgorithm,
            activeColor: AppColors.actionSave,
            onChanged: (value) async {
              if (value != null) {
                settings.updateRotationAlgorithm(value);
                magnetometer.setAlgorithm(value);
                final storageService = context.read<StorageService>();
                await storageService.saveSettings(settings);
              }
            },
          );
        }).toList(),
      ],
    );
  }

  String _getAlgorithmName(RotationAlgorithm algorithm) {
    switch (algorithm) {
      case RotationAlgorithm.threshold:
        return 'Threshold (Legacy)';
      case RotationAlgorithm.pca:
        return 'PCA Phase Tracking (New)';
    }
  }

  String _getAlgorithmDescription(RotationAlgorithm algorithm) {
    switch (algorithm) {
      case RotationAlgorithm.threshold:
        return 'Magnitude-based peak detection. Requires manual tuning.';
      case RotationAlgorithm.pca:
        return 'Orientation-independent phase tracking. Zero configuration.';
    }
  }

  Widget _buildSignalQualityIndicator(MagnetometerService magnetometer) {
    final quality = magnetometer.signalQuality;
    final percentage = (quality * 100).round();

    Color qualityColor;
    String qualityText;

    if (quality >= 0.7) {
      qualityColor = AppColors.statusGood;
      qualityText = 'Excellent';
    } else if (quality >= 0.5) {
      qualityColor = Colors.blue;
      qualityText = 'Good';
    } else if (quality >= 0.3) {
      qualityColor = Colors.orange;
      qualityText = 'Fair';
    } else {
      qualityColor = Colors.red;
      qualityText = 'Poor';
    }

    final pcaDetector = magnetometer.pcaDetector;
    final validity = pcaDetector?.latestValidity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Signal Quality',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$qualityText ($percentage%)',
              style: AppTextStyles.body.copyWith(
                color: qualityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: quality,
          backgroundColor: AppColors.backgroundSecondary,
          valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
          minHeight: 8,
        ),
        if (validity != null && magnetometer.isRecording) ...[
          const SizedBox(height: 12),
          Text(
            'Quality Checks',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _buildQualityCheck('Planar Signal', validity.isPlanar),
          _buildQualityCheck('Strong Signal', validity.hasStrongSignal),
          _buildQualityCheck('Valid Frequency', validity.isWithinFrequencyLimit),
          _buildQualityCheck('Phase Motion', validity.hasPhaseMotion),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Start recording to see live quality metrics',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQualityCheck(String label, bool passed, [String? value]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: passed ? AppColors.statusGood : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
