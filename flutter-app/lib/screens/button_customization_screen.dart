import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/button_config.dart';
import '../services/button_customization_service.dart';
import '../utils/theme_extensions.dart';
import '../widgets/draggable_button_customizer.dart';

enum ScreenType { mainScreen, saveDataScreen }

enum MainScreenButton { save, map, reset, camera }

enum SaveDataButton { save, increment, decrement, cycle }

class ButtonCustomizationScreen extends StatefulWidget {
  const ButtonCustomizationScreen({super.key});

  @override
  State<ButtonCustomizationScreen> createState() =>
      _ButtonCustomizationScreenState();
}

class _ButtonCustomizationScreenState
    extends State<ButtonCustomizationScreen> {
  ScreenType _selectedScreen = ScreenType.mainScreen;
  String? _selectedButtonId; // Track which button is selected for editing
  bool _isFullScreenMode = false; // Track if in full-screen edit mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: _isFullScreenMode ? null : AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Button Customization',
          style: AppTextStyles.headline,
        ),
      ),
      body: Consumer<ButtonCustomizationService>(
        builder: (context, service, child) {
          return Stack(
            children: [
              // Normal UI when not in full-screen mode
              if (!_isFullScreenMode)
                Column(
                  children: [
                    // Screen selector
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: _buildScreenSelector(),
                    ),

                    // Instructions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.dataPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.dataPrimary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: AppColors.dataPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                'Enter full-screen mode to drag buttons',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.dataPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Interactive preview area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        child: _buildInteractivePreview(service),
                      ),
                    ),

                    // Controls panel at bottom
                    _buildControlsPanel(service),
                  ],
                ),

              // Full-screen edit mode overlay
              if (_isFullScreenMode)
                _buildFullScreenEditor(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScreenSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                'Main Screen',
                _selectedScreen == ScreenType.mainScreen,
                () => setState(() {
                  _selectedScreen = ScreenType.mainScreen;
                  _selectedButtonId = null; // Clear selection when switching screens
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildSegmentButton(
                'Save Data',
                _selectedScreen == ScreenType.saveDataScreen,
                () => setState(() {
                  _selectedScreen = ScreenType.saveDataScreen;
                  _selectedButtonId = null; // Clear selection when switching screens
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dataPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.dataPrimary : AppColors.textSecondary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: isSelected ? AppColors.backgroundPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractivePreview(ButtonCustomizationService service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            // Enter full-screen mode when tapping the preview
            setState(() {
              _isFullScreenMode = true;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fullscreen,
                    size: 48,
                    color: AppColors.dataPrimary,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'Tap to Enter Full-Screen Editor',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.dataPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Drag buttons anywhere on the screen',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenEditor(ButtonCustomizationService service) {
    final selectedConfig = _getSelectedButtonConfig(service);
    final selectedLabel = _getSelectedButtonLabel();

    return Material(
      color: AppColors.backgroundPrimary,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate top bar height to constrain button movement
            const topBarHeight = 100.0; // Compact top bar
            final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // Background with center crosshair (below top bar)
                Positioned(
                  top: topBarHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    painter: _CenterCrosshairPainter(),
                  ),
                ),

                // All buttons for current screen (constrained below top bar)
                if (_selectedScreen == ScreenType.mainScreen)
                  ..._buildMainScreenButtons(service, screenSize, topBarHeight)
                else
                  ..._buildSaveDataButtons(service, screenSize, topBarHeight),

                // Compact top bar with controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.small,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: instructions and close
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: AppColors.dataPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                'Drag to reposition',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.close,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFullScreenMode = false;
                                });
                              },
                            ),
                          ],
                        ),
                        // Size slider (compact, only when button selected)
                        if (selectedConfig != null && selectedLabel != null) ...[
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              Icon(
                                Icons.zoom_out_map,
                                color: AppColors.dataPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Text(
                                '${selectedConfig.size.toInt()}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: AppColors.dataPrimary,
                                    inactiveTrackColor: AppColors.textSecondary,
                                    thumbColor: AppColors.dataPrimary,
                                    overlayColor: AppColors.dataPrimary.withOpacity(0.2),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: selectedConfig.size,
                                    min: 40,
                                    max: 150,
                                    divisions: 22,
                                    onChanged: (value) {
                                      _updateSelectedButtonSize(service, value);
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                selectedLabel.split(' ')[0],
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMainScreenButtons(
    ButtonCustomizationService service,
    Size screenSize,
    double topBarHeight,
  ) {
    return [
      _buildDraggableButton(
        id: 'main_save',
        config: service.mainSaveButton,
        label: 'Save',
        color: AppColors.actionSave,
        icon: Icons.save,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateMainSaveButton,
      ),
      _buildDraggableButton(
        id: 'main_map',
        config: service.mainMapButton,
        label: 'Map',
        color: AppColors.actionMap,
        icon: Icons.map,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateMainMapButton,
      ),
      _buildDraggableButton(
        id: 'main_reset',
        config: service.mainResetButton,
        label: 'Reset',
        color: AppColors.actionReset,
        icon: Icons.refresh,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateMainResetButton,
      ),
      _buildDraggableButton(
        id: 'main_camera',
        config: service.mainCameraButton,
        label: 'Camera',
        color: AppColors.actionMap,
        icon: Icons.camera_alt,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateMainCameraButton,
      ),
    ];
  }

  List<Widget> _buildSaveDataButtons(
    ButtonCustomizationService service,
    Size screenSize,
    double topBarHeight,
  ) {
    return [
      _buildDraggableButton(
        id: 'save_save',
        config: service.saveDataSaveButton,
        label: 'Save',
        color: AppColors.actionSave,
        icon: Icons.save,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateSaveDataSaveButton,
      ),
      _buildDraggableButton(
        id: 'save_increment',
        config: service.saveDataIncrementButton,
        label: 'Plus',
        color: AppColors.actionIncrement,
        icon: Icons.add,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateSaveDataIncrementButton,
      ),
      _buildDraggableButton(
        id: 'save_decrement',
        config: service.saveDataDecrementButton,
        label: 'Minus',
        color: AppColors.actionDecrement,
        icon: Icons.remove,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateSaveDataDecrementButton,
      ),
      _buildDraggableButton(
        id: 'save_cycle',
        config: service.saveDataCycleButton,
        label: 'Cycle',
        color: AppColors.actionCycle,
        icon: Icons.loop,
        screenSize: screenSize,
        topBarHeight: topBarHeight,
        onConfigChanged: service.updateSaveDataCycleButton,
      ),
    ];
  }

  Widget _buildDraggableButton({
    required String id,
    required ButtonConfig config,
    required String label,
    required Color color,
    required IconData icon,
    required Size screenSize,
    required double topBarHeight,
    required Function(ButtonConfig) onConfigChanged,
  }) {
    return DraggableButtonCustomizer(
      config: config,
      label: label,
      color: color,
      icon: icon,
      isSelected: _selectedButtonId == id,
      onConfigChanged: onConfigChanged,
      onTap: () {
        setState(() {
          _selectedButtonId = _selectedButtonId == id ? null : id;
        });
      },
      screenSize: screenSize,
      topBarHeight: topBarHeight,
    );
  }

  Widget _buildControlsPanel(ButtonCustomizationService service) {
    final selectedConfig = _getSelectedButtonConfig(service);
    final selectedLabel = _getSelectedButtonLabel();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedConfig != null && selectedLabel != null) ...[
              // Size slider for selected button
              Row(
                children: [
                  Icon(
                    Icons.zoom_out_map,
                    color: AppColors.dataPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'Size: ${selectedConfig.size.toInt()}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.dataPrimary,
                        inactiveTrackColor: AppColors.textSecondary,
                        thumbColor: AppColors.dataPrimary,
                        overlayColor: AppColors.dataPrimary.withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: selectedConfig.size,
                        min: 40,
                        max: 150,
                        divisions: 22,
                        onChanged: (value) {
                          _updateSelectedButtonSize(service, value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Selected: $selectedLabel',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],

            // Reset button
            GestureDetector(
              onTap: () => _confirmReset(service),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.actionReset.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.actionReset, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Reset All to Defaults',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.actionReset,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonConfig? _getSelectedButtonConfig(ButtonCustomizationService service) {
    if (_selectedButtonId == null) return null;

    switch (_selectedButtonId) {
      case 'main_save':
        return service.mainSaveButton;
      case 'main_map':
        return service.mainMapButton;
      case 'main_reset':
        return service.mainResetButton;
      case 'main_camera':
        return service.mainCameraButton;
      case 'save_save':
        return service.saveDataSaveButton;
      case 'save_increment':
        return service.saveDataIncrementButton;
      case 'save_decrement':
        return service.saveDataDecrementButton;
      case 'save_cycle':
        return service.saveDataCycleButton;
      default:
        return null;
    }
  }

  String? _getSelectedButtonLabel() {
    if (_selectedButtonId == null) return null;

    switch (_selectedButtonId) {
      case 'main_save':
        return 'Save Button (Main)';
      case 'main_map':
        return 'Map Button (Main)';
      case 'main_reset':
        return 'Reset Button (Main)';
      case 'main_camera':
        return 'Camera Button (Main)';
      case 'save_save':
        return 'Save Button (Save Data)';
      case 'save_increment':
        return 'Plus Button (Save Data)';
      case 'save_decrement':
        return 'Minus Button (Save Data)';
      case 'save_cycle':
        return 'Cycle Button (Save Data)';
      default:
        return null;
    }
  }

  void _updateSelectedButtonSize(ButtonCustomizationService service, double size) {
    if (_selectedButtonId == null) return;

    switch (_selectedButtonId) {
      case 'main_save':
        service.updateMainSaveButton(service.mainSaveButton.copyWith(size: size));
        break;
      case 'main_map':
        service.updateMainMapButton(service.mainMapButton.copyWith(size: size));
        break;
      case 'main_reset':
        service.updateMainResetButton(service.mainResetButton.copyWith(size: size));
        break;
      case 'main_camera':
        service.updateMainCameraButton(service.mainCameraButton.copyWith(size: size));
        break;
      case 'save_save':
        service.updateSaveDataSaveButton(service.saveDataSaveButton.copyWith(size: size));
        break;
      case 'save_increment':
        service.updateSaveDataIncrementButton(
            service.saveDataIncrementButton.copyWith(size: size));
        break;
      case 'save_decrement':
        service.updateSaveDataDecrementButton(
            service.saveDataDecrementButton.copyWith(size: size));
        break;
      case 'save_cycle':
        service.updateSaveDataCycleButton(service.saveDataCycleButton.copyWith(size: size));
        break;
    }
  }

  Future<void> _confirmReset(ButtonCustomizationService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'Reset All Buttons?',
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
        content: Text(
          'This will reset all button sizes and positions to their default values.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset',
              style: AppTextStyles.body.copyWith(color: AppColors.actionReset),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      service.resetAllToDefaults();
      setState(() {
        _selectedButtonId = null; // Clear selection after reset
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All buttons reset to defaults',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.dataPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Custom painter for center crosshair guide
class _CenterCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Vertical line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
