import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/magnetometer_service.dart';
import '../services/compass_service.dart';
import '../utils/theme_extensions.dart';
import '../widgets/info_card.dart';
import '../widgets/monospaced_text.dart';
import 'package:url_launcher/url_launcher.dart';
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
      text: (settings.wheelDiameter * 1000).toStringAsFixed(
        1,
      ), // Convert m to mm for display
    );
    _minPeakThresholdController = TextEditingController(
      text: settings.minPeakThreshold.toStringAsFixed(1),
    );
    _maxPeakThresholdController = TextEditingController(
      text: settings.maxPeakThreshold.toStringAsFixed(1),
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
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Survey Configuration Section
            _buildSectionHeader('Survey Configuration'),
            const SizedBox(height: AppSpacing.small),
            InfoCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _surveyNameController,
                    label: 'Survey Name',
                    hint: 'Enter cave/site name',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Wheel Settings Section
            _buildSectionHeader('Wheel Settings'),
            const SizedBox(height: AppSpacing.small),
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
                  const SizedBox(height: 4),
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
            const SizedBox(height: AppSpacing.medium),

            // Sensor Configuration Section
            _buildSectionHeader('Sensor Configuration'),
            const SizedBox(height: AppSpacing.small),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _minPeakThresholdController,
                    label: 'Min Peak Threshold (μT)',
                    hint: '50.0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildTextField(
                    controller: _maxPeakThresholdController,
                    label: 'Max Peak Threshold (μT)',
                    hint: '200.0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Magnetic field range for wheel rotation detection',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),

            // Live Magnetometer Section
            _buildSectionHeader('Magnetic Field Readout'),
            const SizedBox(height: AppSpacing.small),
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
                      const SizedBox(height: AppSpacing.small),
                      _buildSensorRow('X', magnetometer.magnetometerX),
                      const SizedBox(height: 6),
                      _buildSensorRow('Y', magnetometer.magnetometerY),
                      const SizedBox(height: 6),
                      _buildSensorRow('Z', magnetometer.magnetometerZ),
                      const Divider(height: 20),
                      _buildSensorRow(
                        'Magnitude',
                        magnetometer.magneticStrength,
                        highlight: true,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Compass',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildSensorRow('Heading', compass.heading, suffix: '°'),
                      const SizedBox(height: 6),
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
            const SizedBox(height: AppSpacing.medium),

            // Button Customization Section
            _buildSectionHeader('Interface'),
            const SizedBox(height: AppSpacing.small),
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
            const SizedBox(height: AppSpacing.medium),

            // Links Section
            _buildSectionHeader('Information'),
            const SizedBox(height: AppSpacing.small),
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
                        _launchURL('https://github.com/f0xdude/CaveDiveMap'),
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
            const SizedBox(height: AppSpacing.large),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionSave,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
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
}
