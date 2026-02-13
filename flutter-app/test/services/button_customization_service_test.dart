import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/button_config.dart';
import 'package:cavedivemapf/services/button_customization_service.dart';
import 'package:cavedivemapf/services/storage_service.dart';
import 'package:cavedivemapf/utils/underwater_button_layout.dart';

class _FakeStorageService extends StorageService {
  _FakeStorageService(this._configs);

  final Map<String, ButtonConfig> _configs;

  @override
  Future<ButtonConfig?> loadButtonConfig(String key) async {
    return _configs[key];
  }

  @override
  Future<void> saveButtonConfig(String key, ButtonConfig config) async {
    _configs[key] = config;
  }
}

void main() {
  test('loadSettings sanitizes unsafe saved layouts', () async {
    final storage = _FakeStorageService({
      'main_save': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'main_map': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'main_reset': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'main_camera': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'save_data_save': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'save_data_increment': const ButtonConfig(
        size: 40,
        offsetX: 0,
        offsetY: 0,
      ),
      'save_data_decrement': const ButtonConfig(
        size: 40,
        offsetX: 0,
        offsetY: 0,
      ),
      'save_data_cycle': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
    });

    final service = ButtonCustomizationService(storage);
    await service.loadSettings();

    expect(service.mainSaveButton.size, UnderwaterButtonLayout.minSize);
    expect(service.mainMapButton.size, UnderwaterButtonLayout.minSize);
    expect(
      UnderwaterButtonLayout.conflicts(
        service.mainSaveButton,
        service.mainMapButton,
      ),
      isFalse,
    );
    expect(
      UnderwaterButtonLayout.conflicts(
        service.saveDataSaveButton,
        service.saveDataIncrementButton,
      ),
      isFalse,
    );
    final persistedMain = await storage.loadButtonConfig('main_save');
    final persistedSave = await storage.loadButtonConfig('save_data_save');
    expect(persistedMain, isNotNull);
    expect(persistedSave, isNotNull);
    expect(persistedMain!.size, UnderwaterButtonLayout.minSize);
    expect(persistedSave!.size, UnderwaterButtonLayout.minSize);
  });
}
