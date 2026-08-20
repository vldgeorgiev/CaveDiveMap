import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../services/storage_service.dart';
import '../services/magnetometer_service.dart';
import '../services/button_customization_service.dart';
import '../widgets/underwater_action_button.dart';
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

  Future<void> _saveManualPoint() async {
    final magnetometerService = context.read<MagnetometerService>();
    final storageService = context.read<StorageService>();

    // After a station switch, first Save just captures departure heading
    if (storageService.needsLegStart && storageService.currentDepartureStationId != null) {
      await storageService.setDepartureHeading(widget.capturedHeading);
      magnetometerService.resetLegLength();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Heading captured — start measuring'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Save the entered values for next time
    await storageService.saveLastEnteredValues(
      depth: _depth,
      left: _left,
      right: _right,
      up: _up,
      down: _down,
    );

    final now = DateTime.now();
    final stationNumber = storageService.nextStationNumber;

    final station = Station(
      number: stationNumber,
      depth: _depth,
      timestamp: now,
    );

    final stationId = await storageService.addStation(station);

    // Create leg from current departure station if one exists
    final departureId = storageService.currentDepartureStationId;
    if (departureId != null && storageService.departureHeading != null) {
      final legDistance = magnetometerService.legLength;
      final leg = SurveyLeg(
        fromStationId: departureId,
        toStationId: stationId,
        distance: legDistance,
        heading: storageService.departureHeading!,
        left: _left,
        right: _right,
        up: _up,
        down: _down,
        timestamp: now,
      );
      await storageService.addSurveyLeg(leg);
      magnetometerService.resetLegLength();
    }

    // Capture current heading as departure heading for the next leg
    await storageService.setDepartureHeading(widget.capturedHeading);
    // New station becomes the departure point
    await storageService.setCurrentDepartureStationId(stationId);

    magnetometerService.incrementPointNumber();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Station $stationNumber saved'),
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
          'Save Station',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
      ),
      body: Consumer3<MagnetometerService, ButtonCustomizationService, StorageService>(
        builder: (context, magnetometer, buttonService, storageService2, child) {
          final departureId = storageService2.currentDepartureStationId;
          final departureStation = departureId != null
              ? storageService2.getStationById(departureId)
              : null;
          final activeLabel = departureStation != null
              ? '${departureStation.number}'
              : '—';
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
                              'Active Station',
                              activeLabel,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Leg distance',
                              '${magnetometer.legLength.toStringAsFixed(2)} m',
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

              // Underwater action buttons positioned via ButtonConfig
              PositionedButton(
                config: buttonService.saveDataDecrementButton,
                onPressed: () => _decrement(1.0),
                actionProfile: ButtonActionProfile.pressAndRepeat,
                repeatInitialDelay: const Duration(milliseconds: 500),
                repeatInterval: const Duration(milliseconds: 100),
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
                onPressed: () => _increment(1.0),
                actionProfile: ButtonActionProfile.pressAndRepeat,
                repeatInitialDelay: const Duration(milliseconds: 500),
                repeatInterval: const Duration(milliseconds: 100),
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
