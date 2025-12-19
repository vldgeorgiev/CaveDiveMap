/// Survey data point model matching Swift SavedData struct
class SurveyData {
  final int recordNumber; // Sequential point ID
  final double distance; // Cumulative meters from start
  final double heading; // Magnetic degrees (0-360)
  final double depth; // Meters (manually adjusted)
  final double left; // Passage width left (manual points only)
  final double right; // Passage width right
  final double up; // Passage height up
  final double down; // Passage height down
  final String rtype; // "auto" or "manual"
  final DateTime timestamp; // When point was recorded

  const SurveyData({
    required this.recordNumber,
    required this.distance,
    required this.heading,
    required this.depth,
    this.left = 0.0,
    this.right = 0.0,
    this.up = 0.0,
    this.down = 0.0,
    required this.rtype,
    required this.timestamp,
  });

  /// Create from JSON (for Hive storage and migration)
  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      recordNumber: json['recordNumber'] as int,
      distance: (json['distance'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      up: (json['up'] as num?)?.toDouble() ?? 0.0,
      down: (json['down'] as num?)?.toDouble() ?? 0.0,
      rtype: json['rtype'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'recordNumber': recordNumber,
      'distance': distance,
      'heading': heading,
      'depth': depth,
      'left': left,
      'right': right,
      'up': up,
      'down': down,
      'rtype': rtype,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SurveyData copyWith({
    int? recordNumber,
    double? distance,
    double? heading,
    double? depth,
    double? left,
    double? right,
    double? up,
    double? down,
    String? rtype,
    DateTime? timestamp,
  }) {
    return SurveyData(
      recordNumber: recordNumber ?? this.recordNumber,
      distance: distance ?? this.distance,
      heading: heading ?? this.heading,
      depth: depth ?? this.depth,
      left: left ?? this.left,
      right: right ?? this.right,
      up: up ?? this.up,
      down: down ?? this.down,
      rtype: rtype ?? this.rtype,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SurveyData(#$recordNumber: ${distance.toStringAsFixed(2)}m @ ${heading.toStringAsFixed(1)}°, depth: ${depth.toStringAsFixed(1)}m, type: $rtype)';
  }
}
