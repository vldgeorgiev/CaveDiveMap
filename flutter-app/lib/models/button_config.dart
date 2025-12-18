import 'package:hive/hive.dart';

part 'button_config.g.dart';

/// Configuration for a single button's appearance and position
@HiveType(typeId: 2)
class ButtonConfig {
  @HiveField(0)
  final double size;

  @HiveField(1)
  final double offsetX;

  @HiveField(2)
  final double offsetY;

  const ButtonConfig({
    required this.size,
    required this.offsetX,
    required this.offsetY,
  });

  /// Create a copy with optional parameter overrides
  ButtonConfig copyWith({double? size, double? offsetX, double? offsetY}) {
    return ButtonConfig(
      size: size ?? this.size,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {'size': size, 'offsetX': offsetX, 'offsetY': offsetY};
  }

  /// Create from JSON
  factory ButtonConfig.fromJson(Map<String, dynamic> json) {
    return ButtonConfig(
      size: (json['size'] as num).toDouble(),
      offsetX: (json['offsetX'] as num).toDouble(),
      offsetY: (json['offsetY'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ButtonConfig &&
        other.size == size &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY;
  }

  @override
  int get hashCode => Object.hash(size, offsetX, offsetY);

  @override
  String toString() =>
      'ButtonConfig(size: $size, offsetX: $offsetX, offsetY: $offsetY)';

  // ========== Default Configurations ==========

  // Main Screen Defaults (matching Swift app)
  static ButtonConfig defaultMainSave() =>
      const ButtonConfig(size: 75, offsetX: 0, offsetY: 200);

  static ButtonConfig defaultMainMap() =>
      const ButtonConfig(size: 75, offsetX: 130, offsetY: 200);

  static ButtonConfig defaultMainReset() =>
      const ButtonConfig(size: 75, offsetX: -70, offsetY: 110);

  static ButtonConfig defaultMainCamera() =>
      const ButtonConfig(size: 75, offsetX: 70, offsetY: 110);

  // Save Data View Defaults (matching Swift app)
  static ButtonConfig defaultSaveDataSave() =>
      const ButtonConfig(size: 75, offsetX: 0, offsetY: 200);

  static ButtonConfig defaultSaveDataIncrement() =>
      const ButtonConfig(size: 75, offsetX: 70, offsetY: 110);

  static ButtonConfig defaultSaveDataDecrement() =>
      const ButtonConfig(size: 75, offsetX: -70, offsetY: 110);

  static ButtonConfig defaultSaveDataCycle() =>
      const ButtonConfig(size: 75, offsetX: 130, offsetY: 200);
}
