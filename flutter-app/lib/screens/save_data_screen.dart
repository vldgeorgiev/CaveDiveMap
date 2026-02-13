import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/survey_data.dart';
import '../services/storage_service.dart';
import '../services/magnetometer_service.dart';
import '../services/button_customization_service.dart';
import '../widgets/positioned_button.dart';
import '../widgets/info_card.dart';
import '../widgets/monospaced_text.dart';
import '../utils/theme_extensions.dart';

/// Screen for entering manual survey point data
class SaveDataScreen extends StatefulWidget {
  final double capturedHeading;

  const SaveDataScreen({super.key, required this.capturedHeading});

  @override
  State<SaveDataScreen> createState() => _SaveDataScreenState();
}

class _SaveDataScreenState extends State<SaveDataScreen> {
  // Current parameter being edited (cyclic: depth -> left -> right -> up -> down -> depth...)
  int _currentParameter = 0;
  final List<String> _parameters = ['Depth', 'Left', 'Right', 'Up', 'Down'];

  // Values for manual point
  late double _depth;
  late double _left;
  late double _right;
  late double _up;
  late double _down;

  @override
  void initState() {
    super.initState();
    _loadLastEnteredValues();
  }

  /// Load last entered values from storage
  void _loadLastEnteredValues() {
    final storageService = context.read<StorageService>();
    final lastValues = storageService.getLastEnteredValues();

    _depth = lastValues['depth']!;
    _left = lastValues['left']!;
    _right = lastValues['right']!;
    _up = lastValues['up']!;
    _down = lastValues['down']!;
  }

  // Tap vs long-press detection
  Timer? _incrementTimer;
  Timer? _decrementTimer;
  Timer? _incrementLongPressDetector;
  Timer? _decrementLongPressDetector;
  bool _isIncrementHolding = false;
  bool _isDecrementHolding = false;

  @override
  void dispose() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    _incrementLongPressDetector?.cancel();
    _decrementLongPressDetector?.cancel();
    super.dispose();
  }

  void _cycleParameter() {
    setState(() {
      _currentParameter = (_currentParameter + 1) % _parameters.length;
    });
  }

  void _increment(double step) {
    setState(() {
      switch (_currentParameter) {
        case 0: // Depth
          _depth = _depth + step;
          break;
        case 1: // Left
          _left = _left + step;
          break;
        case 2: // Right
          _right = _right + step;
          break;
        case 3: // Up
          _up = _up + step;
          break;
        case 4: // Down
          _down = _down + step;
          break;
      }
    });
  }

  void _decrement(double step) {
    setState(() {
      switch (_currentParameter) {
        case 0: // Depth
          _depth = (_depth - step).clamp(0.0, double.infinity);
          break;
        case 1: // Left
          _left = (_left - step).clamp(0.0, double.infinity);
          break;
        case 2: // Right
          _right = (_right - step).clamp(0.0, double.infinity);
          break;
        case 3: // Up
          _up = (_up - step).clamp(0.0, double.infinity);
          break;
        case 4: // Down
          _down = (_down - step).clamp(0.0, double.infinity);
          break;
      }
    });
  }

  double get _currentParameterValue {
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

  // Start repeating increment for long-press
  void _startIncrementTimer() {
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _increment(1.0);
    });
  }

  // Start repeating decrement for long-press
  void _startDecrementTimer() {
    _decrementTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _decrement(1.0);
    });
  }

  // Stop increment timer
  void _stopIncrementTimer() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }

  // Stop decrement timer
  void _stopDecrementTimer() {
    _decrementTimer?.cancel();
    _decrementTimer = null;
  }

  // Handle increment tap down (start of press)
  void _onIncrementTapDown() {
    _isIncrementHolding = false;
    // Schedule long-press detection after 500ms
    _incrementLongPressDetector = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_isIncrementHolding) {
        _isIncrementHolding = true;
        _startIncrementTimer();
      }
    });
  }

  // Handle increment tap up (end of press)
  void _onIncrementTapUp() {
    _incrementLongPressDetector?.cancel();
    _incrementLongPressDetector = null;

    if (!_isIncrementHolding) {
      // Was a tap, not a hold
      _increment(1.0);
    }
    _stopIncrementTimer();
    _isIncrementHolding = false;
  }

  // Handle decrement tap down
  void _onDecrementTapDown() {
    _isDecrementHolding = false;
    _decrementLongPressDetector = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_isDecrementHolding) {
        _isDecrementHolding = true;
        _startDecrementTimer();
      }
    });
  }

  // Handle decrement tap up
  void _onDecrementTapUp() {
    _decrementLongPressDetector?.cancel();
    _decrementLongPressDetector = null;

    if (!_isDecrementHolding) {
      _decrement(1.0);
    }
    _stopDecrementTimer();
    _isDecrementHolding = false;
  }

  // Handle tap cancel (finger moved off button)
  void _onIncrementTapCancel() {
    _incrementLongPressDetector?.cancel();
    _incrementLongPressDetector = null;
    _stopIncrementTimer();
    _isIncrementHolding = false;
  }

  void _onDecrementTapCancel() {
    _decrementLongPressDetector?.cancel();
    _decrementLongPressDetector = null;
    _stopDecrementTimer();
    _isDecrementHolding = false;
  }

  Future<void> _saveManualPoint() async {
    final magnetometerService = context.read<MagnetometerService>();
    final storageService = context.read<StorageService>();

    // Save the entered values for next time
    await storageService.saveLastEnteredValues(
      depth: _depth,
      left: _left,
      right: _right,
      up: _up,
      down: _down,
    );

    final manualPoint = SurveyData(
      recordNumber: magnetometerService.currentPointNumber + 1,
      distance: magnetometerService.fractionalDistance,
      heading: widget.capturedHeading, // Use static captured heading
      depth: _depth, // Use manually entered depth
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
          backgroundColor: AppColors.actionSave,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Save Manual Point',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
      ),
      body: Consumer2<MagnetometerService, ButtonCustomizationService>(
        builder: (context, magnetometer, buttonService, child) {
          return Stack(
            children: [
              // Main content
              SafeArea(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info card
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Point Number',
                              '${magnetometer.currentPointNumber + 1}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Distance',
                              '${magnetometer.fractionalDistance.toStringAsFixed(2)} m',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Heading',
                              '${widget.capturedHeading.toStringAsFixed(1)}°',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      Divider(color: AppColors.textSecondary),
                      const SizedBox(height: AppSpacing.medium),

                      // Selected parameter card
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _parameters[_currentParameter],
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MonospacedText(
                              '${_currentParameterValue.toStringAsFixed(2)} m',
                              style: AppTextStyles.largeTitle.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer to push buttons to bottom
                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // Circular action buttons positioned via ButtonConfig
              PositionedButton(
                config: buttonService.saveDataDecrementButton,
                onTapDown: (_) => _onDecrementTapDown(),
                onTapUp: (_) => _onDecrementTapUp(),
                onTapCancel: _onDecrementTapCancel,
                icon: Icons.remove,
                color: AppColors.actionDecrement,
              ),

              PositionedButton(
                config: buttonService.saveDataSaveButton,
                onPressed: _saveManualPoint,
                label: 'Save',
                color: AppColors.actionSave,
              ),

              PositionedButton(
                config: buttonService.saveDataIncrementButton,
                onTapDown: (_) => _onIncrementTapDown(),
                onTapUp: (_) => _onIncrementTapUp(),
                onTapCancel: _onIncrementTapCancel,
                icon: Icons.add,
                color: AppColors.actionIncrement,
              ),

              PositionedButton(
                config: buttonService.saveDataCycleButton,
                onPressed: _cycleParameter,
                icon: Icons.refresh,
                color: AppColors.actionCycle,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        MonospacedText(
          value,
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
