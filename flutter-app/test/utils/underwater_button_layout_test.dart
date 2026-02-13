import 'package:flutter_test/flutter_test.dart';
import 'package:cavedivemapf/models/button_config.dart';
import 'package:cavedivemapf/utils/underwater_button_layout.dart';

void main() {
  test('sanitizeGroup clamps sizes into underwater-safe range', () {
    final sanitized = UnderwaterButtonLayout.sanitizeGroup({
      'a': const ButtonConfig(size: 40, offsetX: 0, offsetY: 0),
      'b': const ButtonConfig(size: 220, offsetX: 120, offsetY: 0),
    });

    expect(sanitized['a']!.size, UnderwaterButtonLayout.minSize);
    expect(sanitized['b']!.size, UnderwaterButtonLayout.maxSize);
  });

  test('sanitizeGroup resolves overlapping controls', () {
    final sanitized = UnderwaterButtonLayout.sanitizeGroup(
      {
        'save': const ButtonConfig(size: 72, offsetX: 0, offsetY: 0),
        'map': const ButtonConfig(size: 72, offsetX: 0, offsetY: 0),
      },
      priorityOrder: const ['save', 'map'],
    );

    expect(
      UnderwaterButtonLayout.conflicts(sanitized['save']!, sanitized['map']!),
      isFalse,
    );
  });

  test('resolveForButton keeps moving control separated', () {
    final resolved = UnderwaterButtonLayout.resolveForButton(
      buttonId: 'map',
      proposedConfig: const ButtonConfig(size: 72, offsetX: 0, offsetY: 0),
      currentConfigs: {
        'save': const ButtonConfig(size: 72, offsetX: 0, offsetY: 0),
        'map': const ButtonConfig(size: 72, offsetX: 120, offsetY: 0),
      },
      priorityOrder: const ['save', 'map'],
    );

    expect(
      UnderwaterButtonLayout.conflicts(
        const ButtonConfig(size: 72, offsetX: 0, offsetY: 0),
        resolved,
      ),
      isFalse,
    );
  });
}
