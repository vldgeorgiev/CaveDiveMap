import 'package:flutter/foundation.dart';
import '../models/button_config.dart';
import 'storage_service.dart';

/// Service managing button customization settings
/// Provides reactive access to button configurations with persistence
class ButtonCustomizationService extends ChangeNotifier {
  final StorageService _storage;

  // Main Screen button configs
  ButtonConfig _mainSaveButton = ButtonConfig.defaultMainSave();
  ButtonConfig _mainMapButton = ButtonConfig.defaultMainMap();
  ButtonConfig _mainResetButton = ButtonConfig.defaultMainReset();
  ButtonConfig _mainCameraButton = ButtonConfig.defaultMainCamera();

  // Save Data View button configs
  ButtonConfig _saveDataSaveButton = ButtonConfig.defaultSaveDataSave();
  ButtonConfig _saveDataIncrementButton = ButtonConfig.defaultSaveDataIncrement();
  ButtonConfig _saveDataDecrementButton = ButtonConfig.defaultSaveDataDecrement();
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
    _mainSaveButton = await _storage.loadButtonConfig('main_save') ??
        ButtonConfig.defaultMainSave();
    _mainMapButton = await _storage.loadButtonConfig('main_map') ??
        ButtonConfig.defaultMainMap();
    _mainResetButton = await _storage.loadButtonConfig('main_reset') ??
        ButtonConfig.defaultMainReset();
    _mainCameraButton = await _storage.loadButtonConfig('main_camera') ??
        ButtonConfig.defaultMainCamera();

    _saveDataSaveButton = await _storage.loadButtonConfig('save_data_save') ??
        ButtonConfig.defaultSaveDataSave();
    _saveDataIncrementButton =
        await _storage.loadButtonConfig('save_data_increment') ??
            ButtonConfig.defaultSaveDataIncrement();
    _saveDataDecrementButton =
        await _storage.loadButtonConfig('save_data_decrement') ??
            ButtonConfig.defaultSaveDataDecrement();
    _saveDataCycleButton = await _storage.loadButtonConfig('save_data_cycle') ??
        ButtonConfig.defaultSaveDataCycle();

    // Migrate old button positions to new defaults if they match old values
    await _migrateOldPositions();

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
    _mainSaveButton = config;
    await _storage.saveButtonConfig('main_save', config);
    notifyListeners();
  }

  /// Update main screen map button configuration
  Future<void> updateMainMapButton(ButtonConfig config) async {
    _mainMapButton = config;
    await _storage.saveButtonConfig('main_map', config);
    notifyListeners();
  }

  /// Update main screen reset button configuration
  Future<void> updateMainResetButton(ButtonConfig config) async {
    _mainResetButton = config;
    await _storage.saveButtonConfig('main_reset', config);
    notifyListeners();
  }

  /// Update main screen camera button configuration
  Future<void> updateMainCameraButton(ButtonConfig config) async {
    _mainCameraButton = config;
    await _storage.saveButtonConfig('main_camera', config);
    notifyListeners();
  }

  /// Update save data view save button configuration
  Future<void> updateSaveDataSaveButton(ButtonConfig config) async {
    _saveDataSaveButton = config;
    await _storage.saveButtonConfig('save_data_save', config);
    notifyListeners();
  }

  /// Update save data view increment button configuration
  Future<void> updateSaveDataIncrementButton(ButtonConfig config) async {
    _saveDataIncrementButton = config;
    await _storage.saveButtonConfig('save_data_increment', config);
    notifyListeners();
  }

  /// Update save data view decrement button configuration
  Future<void> updateSaveDataDecrementButton(ButtonConfig config) async {
    _saveDataDecrementButton = config;
    await _storage.saveButtonConfig('save_data_decrement', config);
    notifyListeners();
  }

  /// Update save data view cycle button configuration
  Future<void> updateSaveDataCycleButton(ButtonConfig config) async {
    _saveDataCycleButton = config;
    await _storage.saveButtonConfig('save_data_cycle', config);
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
      _storage.saveButtonConfig('save_data_increment', _saveDataIncrementButton),
      _storage.saveButtonConfig('save_data_decrement', _saveDataDecrementButton),
      _storage.saveButtonConfig('save_data_cycle', _saveDataCycleButton),
    ]);

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
}
