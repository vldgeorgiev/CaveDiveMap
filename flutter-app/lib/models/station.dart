import 'package:drift/drift.dart';

part 'station.g.dart';

class StationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get number => integer().unique()();
  RealColumn get depth => real()();
  DateTimeColumn get timestamp => dateTime()();
}

class SurveyLegsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromStationId => integer().references(StationsTable, #id)();
  IntColumn get toStationId => integer().references(StationsTable, #id)();
  RealColumn get distance => real()();
  RealColumn get heading => real()();
  RealColumn get left => real().withDefault(const Constant(0.0))();
  RealColumn get right => real().withDefault(const Constant(0.0))();
  RealColumn get up => real().withDefault(const Constant(0.0))();
  RealColumn get down => real().withDefault(const Constant(0.0))();
  DateTimeColumn get timestamp => dateTime()();
}

class AutoPointsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get distance => real()();
  RealColumn get heading => real()();
  RealColumn get depth => real()();
  DateTimeColumn get timestamp => dateTime()();
}

@DriftDatabase(tables: [StationsTable, SurveyLegsTable, AutoPointsTable])
class CaveSurveyDatabase extends _$CaveSurveyDatabase {
  CaveSurveyDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

/// Station model
class Station {
  final int? id;
  final int number;
  final double depth;
  final DateTime timestamp;

  Station({
    this.id,
    required this.number,
    required this.depth,
    required this.timestamp,
  });

  factory Station.fromDrift(StationsTableData data) {
    return Station(
      id: data.id,
      number: data.number,
      depth: data.depth,
      timestamp: data.timestamp,
    );
  }

  StationsTableCompanion toDriftCompanion() {
    return StationsTableCompanion.insert(
      number: number,
      depth: depth,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'depth': depth,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      number: json['number'] as int,
      depth: (json['depth'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Station copyWith({
    int? id,
    int? number,
    double? depth,
    DateTime? timestamp,
  }) {
    return Station(
      id: id ?? this.id,
      number: number ?? this.number,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Station(#$number: depth=${depth.toStringAsFixed(1)}m)';
  }
}

/// Survey leg model — a directed edge between two stations
class SurveyLeg {
  final int? id;
  final int fromStationId;
  final int toStationId;
  final double distance;
  final double heading;
  final double left;
  final double right;
  final double up;
  final double down;
  final DateTime timestamp;

  SurveyLeg({
    this.id,
    required this.fromStationId,
    required this.toStationId,
    required this.distance,
    required this.heading,
    this.left = 0.0,
    this.right = 0.0,
    this.up = 0.0,
    this.down = 0.0,
    required this.timestamp,
  });

  factory SurveyLeg.fromDrift(SurveyLegsTableData data) {
    return SurveyLeg(
      id: data.id,
      fromStationId: data.fromStationId,
      toStationId: data.toStationId,
      distance: data.distance,
      heading: data.heading,
      left: data.left,
      right: data.right,
      up: data.up,
      down: data.down,
      timestamp: data.timestamp,
    );
  }

  SurveyLegsTableCompanion toDriftCompanion() {
    return SurveyLegsTableCompanion.insert(
      fromStationId: fromStationId,
      toStationId: toStationId,
      distance: distance,
      heading: heading,
      left: Value(left),
      right: Value(right),
      up: Value(up),
      down: Value(down),
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromStationId': fromStationId,
      'toStationId': toStationId,
      'distance': distance,
      'heading': heading,
      'left': left,
      'right': right,
      'up': up,
      'down': down,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SurveyLeg.fromJson(Map<String, dynamic> json) {
    return SurveyLeg(
      fromStationId: json['fromStationId'] as int,
      toStationId: json['toStationId'] as int,
      distance: (json['distance'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      up: (json['up'] as num?)?.toDouble() ?? 0.0,
      down: (json['down'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'SurveyLeg($fromStationId→$toStationId: ${distance.toStringAsFixed(2)}m @ ${heading.toStringAsFixed(1)}°, LRUD=${left.toStringAsFixed(1)}/${right.toStringAsFixed(1)}/${up.toStringAsFixed(1)}/${down.toStringAsFixed(1)})';
  }
}

/// Auto-collected point — debug data, no station identity
class AutoPoint {
  final int? id;
  final double distance;
  final double heading;
  final double depth;
  final DateTime timestamp;

  AutoPoint({
    this.id,
    required this.distance,
    required this.heading,
    required this.depth,
    required this.timestamp,
  });

  factory AutoPoint.fromDrift(AutoPointsTableData data) {
    return AutoPoint(
      id: data.id,
      distance: data.distance,
      heading: data.heading,
      depth: data.depth,
      timestamp: data.timestamp,
    );
  }

  AutoPointsTableCompanion toDriftCompanion() {
    return AutoPointsTableCompanion.insert(
      distance: distance,
      heading: heading,
      depth: depth,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'heading': heading,
      'depth': depth,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AutoPoint.fromJson(Map<String, dynamic> json) {
    return AutoPoint(
      distance: (json['distance'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'AutoPoint(${distance.toStringAsFixed(2)}m @ ${heading.toStringAsFixed(1)}°, depth: ${depth.toStringAsFixed(1)}m)';
  }
}
