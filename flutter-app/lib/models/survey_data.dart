import 'package:drift/drift.dart';

part 'survey_data.g.dart';

/// Survey data table definition for Drift
class SurveyDataTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recordNumber => integer().unique()();
  RealColumn get distance => real()();
  RealColumn get heading => real()();
  RealColumn get depth => real()();
  RealColumn get left => real().withDefault(const Constant(0.0))();
  RealColumn get right => real().withDefault(const Constant(0.0))();
  RealColumn get up => real().withDefault(const Constant(0.0))();
  RealColumn get down => real().withDefault(const Constant(0.0))();
  TextColumn get rtype => text()();
  DateTimeColumn get timestamp => dateTime()();
}

/// Survey database using Drift
@DriftDatabase(tables: [SurveyDataTable])
class SurveyDatabase extends _$SurveyDatabase {
  SurveyDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

/// Survey data point model matching Swift SavedData struct
class SurveyData {
  final int? id;
  final int recordNumber;
  final double distance;
  final double heading;
  final double depth;
  final double left;
  final double right;
  final double up;
  final double down;
  final String rtype;
  final DateTime timestamp;

  SurveyData({
    this.id,
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

  /// Create from Drift data object
  factory SurveyData.fromDrift(SurveyDataTableData data) {
    return SurveyData(
      id: data.id,
      recordNumber: data.recordNumber,
      distance: data.distance,
      heading: data.heading,
      depth: data.depth,
      left: data.left,
      right: data.right,
      up: data.up,
      down: data.down,
      rtype: data.rtype,
      timestamp: data.timestamp,
    );
  }

  /// Convert to Drift companion for inserts/updates
  SurveyDataTableCompanion toDriftCompanion() {
    return SurveyDataTableCompanion.insert(
      recordNumber: recordNumber,
      distance: distance,
      heading: heading,
      depth: depth,
      left: Value(left),
      right: Value(right),
      up: Value(up),
      down: Value(down),
      rtype: rtype,
      timestamp: timestamp,
    );
  }

  /// Create from JSON (for migration and import)
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
    int? id,
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
      id: id ?? this.id,
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
