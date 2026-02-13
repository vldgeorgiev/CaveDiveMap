import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/button_config.dart';

/// Shared underwater layout constraints for customizable in-dive controls.
class UnderwaterButtonLayout {
  static const double minSize = 60.0;
  static const double maxSize = 150.0;
  static const double minSpacing = 12.0;
  static const double minOffset = -200.0;
  static const double maxOffset = 200.0;

  static ButtonConfig normalize(ButtonConfig config) {
    return config.copyWith(
      size: config.size.clamp(minSize, maxSize),
      offsetX: _clampOffset(config.offsetX),
      offsetY: _clampOffset(config.offsetY),
    );
  }

  static Map<String, ButtonConfig> sanitizeGroup(
    Map<String, ButtonConfig> configs, {
    List<String>? priorityOrder,
  }) {
    final order = <String>[...(priorityOrder ?? const <String>[])];
    for (final key in configs.keys) {
      if (!order.contains(key)) {
        order.add(key);
      }
    }

    final sanitized = <String, ButtonConfig>{};
    for (final key in order) {
      final config = configs[key];
      if (config == null) continue;
      final normalized = normalize(config);
      sanitized[key] = _resolveCollisions(normalized, sanitized.values);
    }
    return sanitized;
  }

  static ButtonConfig resolveForButton({
    required String buttonId,
    required ButtonConfig proposedConfig,
    required Map<String, ButtonConfig> currentConfigs,
    required List<String> priorityOrder,
  }) {
    final merged = Map<String, ButtonConfig>.from(currentConfigs);
    merged[buttonId] = proposedConfig;

    final resolved = sanitizeGroup(merged, priorityOrder: priorityOrder);
    return resolved[buttonId] ?? normalize(proposedConfig);
  }

  static bool conflicts(ButtonConfig a, ButtonConfig b) {
    final inflateBy = minSpacing / 2;
    return _rectFor(
      a,
    ).inflate(inflateBy).overlaps(_rectFor(b).inflate(inflateBy));
  }

  static ButtonConfig _resolveCollisions(
    ButtonConfig candidate,
    Iterable<ButtonConfig> existing,
  ) {
    if (_isPlacementValid(candidate, existing)) {
      return candidate;
    }

    const radialStep = 8.0;
    const maxRadius = 320.0;
    const samplesPerRing = 32;

    for (
      double radius = radialStep;
      radius <= maxRadius;
      radius += radialStep
    ) {
      for (int i = 0; i < samplesPerRing; i++) {
        final angle = (2 * math.pi * i) / samplesPerRing;
        final probe = candidate.copyWith(
          offsetX: _clampOffset(candidate.offsetX + radius * math.cos(angle)),
          offsetY: _clampOffset(candidate.offsetY + radius * math.sin(angle)),
        );
        if (_isPlacementValid(probe, existing)) {
          return probe;
        }
      }
    }

    return candidate;
  }

  static bool _isPlacementValid(
    ButtonConfig candidate,
    Iterable<ButtonConfig> existing,
  ) {
    for (final other in existing) {
      if (conflicts(candidate, other)) {
        return false;
      }
    }
    return true;
  }

  static Rect _rectFor(ButtonConfig config) {
    return Rect.fromCenter(
      center: Offset(config.offsetX, config.offsetY),
      width: config.size,
      height: config.size,
    );
  }

  static double _clampOffset(double value) {
    return value.clamp(minOffset, maxOffset);
  }
}
