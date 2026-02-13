import 'package:flutter/foundation.dart';
import '../models/button_config.dart';
import 'storage_service.dart';
import '../utils/underwater_button_layout.dart';

/// Service managing button customization settings
/// Provides reactive access to button configurations with persistence
class ButtonCustomizationService extends ChangeNotifier {
  final StorageService _storage;
  static const List<String> _mainGroupOrder = <String>[
    'main_save',
    'main_map',
    'main_reset',
    'main_camera',
  ];
  static const List<String> _saveDataGroupOrder = <String>[
    'save_data_save',
    'save_data_increment',
    'save_data_decrement',
    'save_data_cycle',
  ];

  // Main Screen button configs
  ButtonConfig _mainSaveButton = ButtonConfig.defaultMainSave();
  ButtonConfig _mainMapButton = ButtonConfig.defaultMainMap();
  ButtonConfig _mainResetButton = ButtonConfig.defaultMainReset();
  ButtonConfig _mainCameraButton = ButtonConfig.defaultMainCamera();

  // Save Data View button configs
  ButtonConfig _saveDataSaveButton = ButtonConfig.defaultSaveDataSave();
  ButtonConfig _saveDataIncrementButton =
      ButtonConfig.defaultSaveDataIncrement();
  ButtonConfig _saveDataDecrementButton =
      ButtonConfig.defaultSaveDataDecrement();
  ButtonConfig _saveDataCycleButton = ButtonConfig.defaultSaveDataCycle();

  bool _isLoaded = false;

  ButtonCustomizationService(this._storage);

  // ========== Getters ==========

  bool get isLoaded => _isLoaded;

  // Main Screen
  ButtonConfig get mainSaveButton => _mainSaveButton;
  ButtonConfig get mainMapButton => _mainMapButton;
  ButtonConfig get mainResetButton => _mainResetButton;
  ButtonConfig get mainCameraButton => _mainCameraButton;

  // Save Data View
  ButtonConfig get saveDataSaveButton => _saveDataSaveButton;
  ButtonConfig get saveDataIncrementButton => _saveDataIncrementButton;
  ButtonConfig get saveDataDecrementButton => _saveDataDecrementButton;
  ButtonConfig get saveDataCycleButton => _saveDataCycleButton;

  // ========== Initialization ==========

  /// Load all button configurations from storage
  Future<void> loadSettings() async {
    // Load saved configs or use defaults
    _mainSaveButton =
        await _storage.loadButtonConfig('main_save') ??
        ButtonConfig.defaultMainSave();
    _mainMapButton =
        await _storage.loadButtonConfig('main_map') ??
        ButtonConfig.defaultMainMap();
    _mainResetButton =
        await _storage.loadButtonConfig('main_reset') ??
        ButtonConfig.defaultMainReset();
    _mainCameraButton =
        await _storage.loadButtonConfig('main_camera') ??
        ButtonConfig.defaultMainCamera();

    _saveDataSaveButton =
        await _storage.loadButtonConfig('save_data_save') ??
        ButtonConfig.defaultSaveDataSave();
    _saveDataIncrementButton =
        await _storage.loadButtonConfig('save_data_increment') ??
        ButtonConfig.defaultSaveDataIncrement();
    _saveDataDecrementButton =
        await _storage.loadButtonConfig('save_data_decrement') ??
        ButtonConfig.defaultSaveDataDecrement();
    _saveDataCycleButton =
        await _storage.loadButtonConfig('save_data_cycle') ??
        ButtonConfig.defaultSaveDataCycle();

    // Migrate old button positions to new defaults if they match old values
    await _migrateOldPositions();
    await _sanitizeAllGroups();

    _isLoaded = true;
    notifyListeners();
  }

  /// Migrate buttons from old default positions to new defaults
  Future<void> _migrateOldPositions() async {
    bool needsUpdate = false;

    // Check and migrate main screen buttons
    if (_mainSaveButton.offsetY == 20 && _mainSaveButton.offsetX == 0) {
      _mainSaveButton = ButtonConfig.defaultMainSave();
      await _storage.saveButtonConfig('main_save', _mainSaveButton);
      needsUpdate = true;
    }
    if (_mainMapButton.offsetY == 10 && _mainMapButton.offsetX == 130) {
      _mainMapButton = ButtonConfig.defaultMainMap();
      await _storage.saveButtonConfig('main_map', _mainMapButton);
      needsUpdate = true;
    }
    if (_mainResetButton.offsetY == -70 && _mainResetButton.offsetX == -70) {
      _mainResetButton = ButtonConfig.defaultMainReset();
      await _storage.saveButtonConfig('main_reset', _mainResetButton);
      needsUpdate = true;
    }
    if (_mainCameraButton.offsetY == -70 && _mainCameraButton.offsetX == 70) {
      _mainCameraButton = ButtonConfig.defaultMainCamera();
      await _storage.saveButtonConfig('main_camera', _mainCameraButton);
      needsUpdate = true;
    }

    if (needsUpdate) {
      notifyListeners();
    }
  }

  // ========== Update Methods ==========

  /// Update main screen save button configuration
  Future<void> updateMainSaveButton(ButtonConfig config) async {
    await _sanitizeMainGroup(overrides: {'main_save': config});
    notifyListeners();
  }

  /// Update main screen map button configuration
  Future<void> updateMainMapButton(ButtonConfig config) async {
    await _sanitizeMainGroup(overrides: {'main_map': config});
    notifyListeners();
  }

  /// Update main screen reset button configuration
  Future<void> updateMainResetButton(ButtonConfig config) async {
    await _sanitizeMainGroup(overrides: {'main_reset': config});
    notifyListeners();
  }

  /// Update main screen camera button configuration
  Future<void> updateMainCameraButton(ButtonConfig config) async {
    await _sanitizeMainGroup(overrides: {'main_camera': config});
    notifyListeners();
  }

  /// Update save data view save button configuration
  Future<void> updateSaveDataSaveButton(ButtonConfig config) async {
    await _sanitizeSaveDataGroup(overrides: {'save_data_save': config});
    notifyListeners();
  }

  /// Update save data view increment button configuration
  Future<void> updateSaveDataIncrementButton(ButtonConfig config) async {
    await _sanitizeSaveDataGroup(overrides: {'save_data_increment': config});
    notifyListeners();
  }

  /// Update save data view decrement button configuration
  Future<void> updateSaveDataDecrementButton(ButtonConfig config) async {
    await _sanitizeSaveDataGroup(overrides: {'save_data_decrement': config});
    notifyListeners();
  }

  /// Update save data view cycle button configuration
  Future<void> updateSaveDataCycleButton(ButtonConfig config) async {
    await _sanitizeSaveDataGroup(overrides: {'save_data_cycle': config});
    notifyListeners();
  }

  // ========== Bulk Operations ==========

  /// Reset all buttons to their default configurations
  Future<void> resetAllToDefaults() async {
    _mainSaveButton = ButtonConfig.defaultMainSave();
    _mainMapButton = ButtonConfig.defaultMainMap();
    _mainResetButton = ButtonConfig.defaultMainReset();
    _mainCameraButton = ButtonConfig.defaultMainCamera();

    _saveDataSaveButton = ButtonConfig.defaultSaveDataSave();
    _saveDataIncrementButton = ButtonConfig.defaultSaveDataIncrement();
    _saveDataDecrementButton = ButtonConfig.defaultSaveDataDecrement();
    _saveDataCycleButton = ButtonConfig.defaultSaveDataCycle();

    // Save all defaults
    await Future.wait([
      _storage.saveButtonConfig('main_save', _mainSaveButton),
      _storage.saveButtonConfig('main_map', _mainMapButton),
      _storage.saveButtonConfig('main_reset', _mainResetButton),
      _storage.saveButtonConfig('main_camera', _mainCameraButton),
      _storage.saveButtonConfig('save_data_save', _saveDataSaveButton),
      _storage.saveButtonConfig(
        'save_data_increment',
        _saveDataIncrementButton,
      ),
      _storage.saveButtonConfig(
        'save_data_decrement',
        _saveDataDecrementButton,
      ),
      _storage.saveButtonConfig('save_data_cycle', _saveDataCycleButton),
    ]);

    await _sanitizeAllGroups();

    notifyListeners();
  }

  /// Get button config by key (for generic access)
  ButtonConfig? getButtonConfig(String key) {
    switch (key) {
      case 'main_save':
        return _mainSaveButton;
      case 'main_map':
        return _mainMapButton;
      case 'main_reset':
        return _mainResetButton;
      case 'main_camera':
        return _mainCameraButton;
      case 'save_data_save':
        return _saveDataSaveButton;
      case 'save_data_increment':
        return _saveDataIncrementButton;
      case 'save_data_decrement':
        return _saveDataDecrementButton;
      case 'save_data_cycle':
        return _saveDataCycleButton;
      default:
        return null;
    }
  }

  /// Update button config by key (for generic access)
  Future<void> updateButtonConfig(String key, ButtonConfig config) async {
    switch (key) {
      case 'main_save':
        await updateMainSaveButton(config);
        break;
      case 'main_map':
        await updateMainMapButton(config);
        break;
      case 'main_reset':
        await updateMainResetButton(config);
        break;
      case 'main_camera':
        await updateMainCameraButton(config);
        break;
      case 'save_data_save':
        await updateSaveDataSaveButton(config);
        break;
      case 'save_data_increment':
        await updateSaveDataIncrementButton(config);
        break;
      case 'save_data_decrement':
        await updateSaveDataDecrementButton(config);
        break;
      case 'save_data_cycle':
        await updateSaveDataCycleButton(config);
        break;
    }
  }

  Future<void> _sanitizeAllGroups() async {
    await _sanitizeMainGroup();
    await _sanitizeSaveDataGroup();
  }

  Future<void> _sanitizeMainGroup({
    Map<String, ButtonConfig> overrides = const <String, ButtonConfig>{},
  }) async {
    final sanitized = UnderwaterButtonLayout.sanitizeGroup({
      'main_save': overrides['main_save'] ?? _mainSaveButton,
      'main_map': overrides['main_map'] ?? _mainMapButton,
      'main_reset': overrides['main_reset'] ?? _mainResetButton,
      'main_camera': overrides['main_camera'] ?? _mainCameraButton,
    }, priorityOrder: _mainGroupOrder);

    await _applyMainGroup(sanitized);
  }

  Future<void> _sanitizeSaveDataGroup({
    Map<String, ButtonConfig> overrides = const <String, ButtonConfig>{},
  }) async {
    final sanitized = UnderwaterButtonLayout.sanitizeGroup({
      'save_data_save': overrides['save_data_save'] ?? _saveDataSaveButton,
      'save_data_increment':
          overrides['save_data_increment'] ?? _saveDataIncrementButton,
      'save_data_decrement':
          overrides['save_data_decrement'] ?? _saveDataDecrementButton,
      'save_data_cycle': overrides['save_data_cycle'] ?? _saveDataCycleButton,
    }, priorityOrder: _saveDataGroupOrder);

    await _applySaveDataGroup(sanitized);
  }

  Future<void> _applyMainGroup(Map<String, ButtonConfig> sanitized) async {
    final nextMainSave = sanitized['main_save']!;
    if (nextMainSave != _mainSaveButton) {
      _mainSaveButton = nextMainSave;
      await _storage.saveButtonConfig('main_save', _mainSaveButton);
    }

    final nextMainMap = sanitized['main_map']!;
    if (nextMainMap != _mainMapButton) {
      _mainMapButton = nextMainMap;
      await _storage.saveButtonConfig('main_map', _mainMapButton);
    }

    final nextMainReset = sanitized['main_reset']!;
    if (nextMainReset != _mainResetButton) {
      _mainResetButton = nextMainReset;
      await _storage.saveButtonConfig('main_reset', _mainResetButton);
    }

    final nextMainCamera = sanitized['main_camera']!;
    if (nextMainCamera != _mainCameraButton) {
      _mainCameraButton = nextMainCamera;
      await _storage.saveButtonConfig('main_camera', _mainCameraButton);
    }
  }

  Future<void> _applySaveDataGroup(Map<String, ButtonConfig> sanitized) async {
    final nextSaveDataSave = sanitized['save_data_save']!;
    if (nextSaveDataSave != _saveDataSaveButton) {
      _saveDataSaveButton = nextSaveDataSave;
      await _storage.saveButtonConfig('save_data_save', _saveDataSaveButton);
    }

    final nextSaveDataIncrement = sanitized['save_data_increment']!;
    if (nextSaveDataIncrement != _saveDataIncrementButton) {
      _saveDataIncrementButton = nextSaveDataIncrement;
      await _storage.saveButtonConfig(
        'save_data_increment',
        _saveDataIncrementButton,
      );
    }

    final nextSaveDataDecrement = sanitized['save_data_decrement']!;
    if (nextSaveDataDecrement != _saveDataDecrementButton) {
      _saveDataDecrementButton = nextSaveDataDecrement;
      await _storage.saveButtonConfig(
        'save_data_decrement',
        _saveDataDecrementButton,
      );
    }

    final nextSaveDataCycle = sanitized['save_data_cycle']!;
    if (nextSaveDataCycle != _saveDataCycleButton) {
      _saveDataCycleButton = nextSaveDataCycle;
      await _storage.saveButtonConfig('save_data_cycle', _saveDataCycleButton);
    }
  }
}
