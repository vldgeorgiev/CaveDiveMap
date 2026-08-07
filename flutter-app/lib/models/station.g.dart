// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station.dart';

// ignore_for_file: type=lint
class $StationsTableTable extends StationsTable
    with TableInfo<$StationsTableTable, StationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<double> depth = GeneratedColumn<double>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, number, depth, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $StationsTableTable createAlias(String alias) {
    return $StationsTableTable(attachedDatabase, alias);
  }
}

class StationsTableData extends DataClass
    implements Insertable<StationsTableData> {
  final int id;
  final int number;
  final double depth;
  final DateTime timestamp;
  const StationsTableData({
    required this.id,
    required this.number,
    required this.depth,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['number'] = Variable<int>(number);
    map['depth'] = Variable<double>(depth);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  StationsTableCompanion toCompanion(bool nullToAbsent) {
    return StationsTableCompanion(
      id: Value(id),
      number: Value(number),
      depth: Value(depth),
      timestamp: Value(timestamp),
    );
  }

  factory StationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationsTableData(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<int>(json['number']),
      depth: serializer.fromJson<double>(json['depth']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<int>(number),
      'depth': serializer.toJson<double>(depth),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  StationsTableData copyWith({
    int? id,
    int? number,
    double? depth,
    DateTime? timestamp,
  }) => StationsTableData(
    id: id ?? this.id,
    number: number ?? this.number,
    depth: depth ?? this.depth,
    timestamp: timestamp ?? this.timestamp,
  );
  StationsTableData copyWithCompanion(StationsTableCompanion data) {
    return StationsTableData(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      depth: data.depth.present ? data.depth.value : this.depth,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationsTableData(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('depth: $depth, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number, depth, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationsTableData &&
          other.id == this.id &&
          other.number == this.number &&
          other.depth == this.depth &&
          other.timestamp == this.timestamp);
}

class StationsTableCompanion extends UpdateCompanion<StationsTableData> {
  final Value<int> id;
  final Value<int> number;
  final Value<double> depth;
  final Value<DateTime> timestamp;
  const StationsTableCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.depth = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  StationsTableCompanion.insert({
    this.id = const Value.absent(),
    required int number,
    required double depth,
    required DateTime timestamp,
  }) : number = Value(number),
       depth = Value(depth),
       timestamp = Value(timestamp);
  static Insertable<StationsTableData> custom({
    Expression<int>? id,
    Expression<int>? number,
    Expression<double>? depth,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (depth != null) 'depth': depth,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  StationsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? number,
    Value<double>? depth,
    Value<DateTime>? timestamp,
  }) {
    return StationsTableCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (depth.present) {
      map['depth'] = Variable<double>(depth.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationsTableCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('depth: $depth, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $SurveyLegsTableTable extends SurveyLegsTable
    with TableInfo<$SurveyLegsTableTable, SurveyLegsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyLegsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromStationIdMeta = const VerificationMeta(
    'fromStationId',
  );
  @override
  late final GeneratedColumn<int> fromStationId = GeneratedColumn<int>(
    'from_station_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stations_table (id)',
    ),
  );
  static const VerificationMeta _toStationIdMeta = const VerificationMeta(
    'toStationId',
  );
  @override
  late final GeneratedColumn<int> toStationId = GeneratedColumn<int>(
    'to_station_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stations_table (id)',
    ),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftMeta = const VerificationMeta('left');
  @override
  late final GeneratedColumn<double> left = GeneratedColumn<double>(
    'left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _rightMeta = const VerificationMeta('right');
  @override
  late final GeneratedColumn<double> right = GeneratedColumn<double>(
    'right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _upMeta = const VerificationMeta('up');
  @override
  late final GeneratedColumn<double> up = GeneratedColumn<double>(
    'up',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _downMeta = const VerificationMeta('down');
  @override
  late final GeneratedColumn<double> down = GeneratedColumn<double>(
    'down',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromStationId,
    toStationId,
    distance,
    heading,
    left,
    right,
    up,
    down,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_legs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyLegsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_station_id')) {
      context.handle(
        _fromStationIdMeta,
        fromStationId.isAcceptableOrUnknown(
          data['from_station_id']!,
          _fromStationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromStationIdMeta);
    }
    if (data.containsKey('to_station_id')) {
      context.handle(
        _toStationIdMeta,
        toStationId.isAcceptableOrUnknown(
          data['to_station_id']!,
          _toStationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toStationIdMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    } else if (isInserting) {
      context.missing(_headingMeta);
    }
    if (data.containsKey('left')) {
      context.handle(
        _leftMeta,
        left.isAcceptableOrUnknown(data['left']!, _leftMeta),
      );
    }
    if (data.containsKey('right')) {
      context.handle(
        _rightMeta,
        right.isAcceptableOrUnknown(data['right']!, _rightMeta),
      );
    }
    if (data.containsKey('up')) {
      context.handle(_upMeta, up.isAcceptableOrUnknown(data['up']!, _upMeta));
    }
    if (data.containsKey('down')) {
      context.handle(
        _downMeta,
        down.isAcceptableOrUnknown(data['down']!, _downMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyLegsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyLegsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromStationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_station_id'],
      )!,
      toStationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_station_id'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      )!,
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      )!,
      left: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}left'],
      )!,
      right: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}right'],
      )!,
      up: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}up'],
      )!,
      down: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}down'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $SurveyLegsTableTable createAlias(String alias) {
    return $SurveyLegsTableTable(attachedDatabase, alias);
  }
}

class SurveyLegsTableData extends DataClass
    implements Insertable<SurveyLegsTableData> {
  final int id;
  final int fromStationId;
  final int toStationId;
  final double distance;
  final double heading;
  final double left;
  final double right;
  final double up;
  final double down;
  final DateTime timestamp;
  const SurveyLegsTableData({
    required this.id,
    required this.fromStationId,
    required this.toStationId,
    required this.distance,
    required this.heading,
    required this.left,
    required this.right,
    required this.up,
    required this.down,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_station_id'] = Variable<int>(fromStationId);
    map['to_station_id'] = Variable<int>(toStationId);
    map['distance'] = Variable<double>(distance);
    map['heading'] = Variable<double>(heading);
    map['left'] = Variable<double>(left);
    map['right'] = Variable<double>(right);
    map['up'] = Variable<double>(up);
    map['down'] = Variable<double>(down);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  SurveyLegsTableCompanion toCompanion(bool nullToAbsent) {
    return SurveyLegsTableCompanion(
      id: Value(id),
      fromStationId: Value(fromStationId),
      toStationId: Value(toStationId),
      distance: Value(distance),
      heading: Value(heading),
      left: Value(left),
      right: Value(right),
      up: Value(up),
      down: Value(down),
      timestamp: Value(timestamp),
    );
  }

  factory SurveyLegsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyLegsTableData(
      id: serializer.fromJson<int>(json['id']),
      fromStationId: serializer.fromJson<int>(json['fromStationId']),
      toStationId: serializer.fromJson<int>(json['toStationId']),
      distance: serializer.fromJson<double>(json['distance']),
      heading: serializer.fromJson<double>(json['heading']),
      left: serializer.fromJson<double>(json['left']),
      right: serializer.fromJson<double>(json['right']),
      up: serializer.fromJson<double>(json['up']),
      down: serializer.fromJson<double>(json['down']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromStationId': serializer.toJson<int>(fromStationId),
      'toStationId': serializer.toJson<int>(toStationId),
      'distance': serializer.toJson<double>(distance),
      'heading': serializer.toJson<double>(heading),
      'left': serializer.toJson<double>(left),
      'right': serializer.toJson<double>(right),
      'up': serializer.toJson<double>(up),
      'down': serializer.toJson<double>(down),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  SurveyLegsTableData copyWith({
    int? id,
    int? fromStationId,
    int? toStationId,
    double? distance,
    double? heading,
    double? left,
    double? right,
    double? up,
    double? down,
    DateTime? timestamp,
  }) => SurveyLegsTableData(
    id: id ?? this.id,
    fromStationId: fromStationId ?? this.fromStationId,
    toStationId: toStationId ?? this.toStationId,
    distance: distance ?? this.distance,
    heading: heading ?? this.heading,
    left: left ?? this.left,
    right: right ?? this.right,
    up: up ?? this.up,
    down: down ?? this.down,
    timestamp: timestamp ?? this.timestamp,
  );
  SurveyLegsTableData copyWithCompanion(SurveyLegsTableCompanion data) {
    return SurveyLegsTableData(
      id: data.id.present ? data.id.value : this.id,
      fromStationId: data.fromStationId.present
          ? data.fromStationId.value
          : this.fromStationId,
      toStationId: data.toStationId.present
          ? data.toStationId.value
          : this.toStationId,
      distance: data.distance.present ? data.distance.value : this.distance,
      heading: data.heading.present ? data.heading.value : this.heading,
      left: data.left.present ? data.left.value : this.left,
      right: data.right.present ? data.right.value : this.right,
      up: data.up.present ? data.up.value : this.up,
      down: data.down.present ? data.down.value : this.down,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyLegsTableData(')
          ..write('id: $id, ')
          ..write('fromStationId: $fromStationId, ')
          ..write('toStationId: $toStationId, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('left: $left, ')
          ..write('right: $right, ')
          ..write('up: $up, ')
          ..write('down: $down, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromStationId,
    toStationId,
    distance,
    heading,
    left,
    right,
    up,
    down,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyLegsTableData &&
          other.id == this.id &&
          other.fromStationId == this.fromStationId &&
          other.toStationId == this.toStationId &&
          other.distance == this.distance &&
          other.heading == this.heading &&
          other.left == this.left &&
          other.right == this.right &&
          other.up == this.up &&
          other.down == this.down &&
          other.timestamp == this.timestamp);
}

class SurveyLegsTableCompanion extends UpdateCompanion<SurveyLegsTableData> {
  final Value<int> id;
  final Value<int> fromStationId;
  final Value<int> toStationId;
  final Value<double> distance;
  final Value<double> heading;
  final Value<double> left;
  final Value<double> right;
  final Value<double> up;
  final Value<double> down;
  final Value<DateTime> timestamp;
  const SurveyLegsTableCompanion({
    this.id = const Value.absent(),
    this.fromStationId = const Value.absent(),
    this.toStationId = const Value.absent(),
    this.distance = const Value.absent(),
    this.heading = const Value.absent(),
    this.left = const Value.absent(),
    this.right = const Value.absent(),
    this.up = const Value.absent(),
    this.down = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SurveyLegsTableCompanion.insert({
    this.id = const Value.absent(),
    required int fromStationId,
    required int toStationId,
    required double distance,
    required double heading,
    this.left = const Value.absent(),
    this.right = const Value.absent(),
    this.up = const Value.absent(),
    this.down = const Value.absent(),
    required DateTime timestamp,
  }) : fromStationId = Value(fromStationId),
       toStationId = Value(toStationId),
       distance = Value(distance),
       heading = Value(heading),
       timestamp = Value(timestamp);
  static Insertable<SurveyLegsTableData> custom({
    Expression<int>? id,
    Expression<int>? fromStationId,
    Expression<int>? toStationId,
    Expression<double>? distance,
    Expression<double>? heading,
    Expression<double>? left,
    Expression<double>? right,
    Expression<double>? up,
    Expression<double>? down,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromStationId != null) 'from_station_id': fromStationId,
      if (toStationId != null) 'to_station_id': toStationId,
      if (distance != null) 'distance': distance,
      if (heading != null) 'heading': heading,
      if (left != null) 'left': left,
      if (right != null) 'right': right,
      if (up != null) 'up': up,
      if (down != null) 'down': down,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SurveyLegsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? fromStationId,
    Value<int>? toStationId,
    Value<double>? distance,
    Value<double>? heading,
    Value<double>? left,
    Value<double>? right,
    Value<double>? up,
    Value<double>? down,
    Value<DateTime>? timestamp,
  }) {
    return SurveyLegsTableCompanion(
      id: id ?? this.id,
      fromStationId: fromStationId ?? this.fromStationId,
      toStationId: toStationId ?? this.toStationId,
      distance: distance ?? this.distance,
      heading: heading ?? this.heading,
      left: left ?? this.left,
      right: right ?? this.right,
      up: up ?? this.up,
      down: down ?? this.down,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromStationId.present) {
      map['from_station_id'] = Variable<int>(fromStationId.value);
    }
    if (toStationId.present) {
      map['to_station_id'] = Variable<int>(toStationId.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (left.present) {
      map['left'] = Variable<double>(left.value);
    }
    if (right.present) {
      map['right'] = Variable<double>(right.value);
    }
    if (up.present) {
      map['up'] = Variable<double>(up.value);
    }
    if (down.present) {
      map['down'] = Variable<double>(down.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyLegsTableCompanion(')
          ..write('id: $id, ')
          ..write('fromStationId: $fromStationId, ')
          ..write('toStationId: $toStationId, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('left: $left, ')
          ..write('right: $right, ')
          ..write('up: $up, ')
          ..write('down: $down, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AutoPointsTableTable extends AutoPointsTable
    with TableInfo<$AutoPointsTableTable, AutoPointsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AutoPointsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<double> depth = GeneratedColumn<double>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    distance,
    heading,
    depth,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auto_points_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AutoPointsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    } else if (isInserting) {
      context.missing(_headingMeta);
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AutoPointsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AutoPointsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      )!,
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $AutoPointsTableTable createAlias(String alias) {
    return $AutoPointsTableTable(attachedDatabase, alias);
  }
}

class AutoPointsTableData extends DataClass
    implements Insertable<AutoPointsTableData> {
  final int id;
  final double distance;
  final double heading;
  final double depth;
  final DateTime timestamp;
  const AutoPointsTableData({
    required this.id,
    required this.distance,
    required this.heading,
    required this.depth,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['distance'] = Variable<double>(distance);
    map['heading'] = Variable<double>(heading);
    map['depth'] = Variable<double>(depth);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AutoPointsTableCompanion toCompanion(bool nullToAbsent) {
    return AutoPointsTableCompanion(
      id: Value(id),
      distance: Value(distance),
      heading: Value(heading),
      depth: Value(depth),
      timestamp: Value(timestamp),
    );
  }

  factory AutoPointsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AutoPointsTableData(
      id: serializer.fromJson<int>(json['id']),
      distance: serializer.fromJson<double>(json['distance']),
      heading: serializer.fromJson<double>(json['heading']),
      depth: serializer.fromJson<double>(json['depth']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'distance': serializer.toJson<double>(distance),
      'heading': serializer.toJson<double>(heading),
      'depth': serializer.toJson<double>(depth),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AutoPointsTableData copyWith({
    int? id,
    double? distance,
    double? heading,
    double? depth,
    DateTime? timestamp,
  }) => AutoPointsTableData(
    id: id ?? this.id,
    distance: distance ?? this.distance,
    heading: heading ?? this.heading,
    depth: depth ?? this.depth,
    timestamp: timestamp ?? this.timestamp,
  );
  AutoPointsTableData copyWithCompanion(AutoPointsTableCompanion data) {
    return AutoPointsTableData(
      id: data.id.present ? data.id.value : this.id,
      distance: data.distance.present ? data.distance.value : this.distance,
      heading: data.heading.present ? data.heading.value : this.heading,
      depth: data.depth.present ? data.depth.value : this.depth,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AutoPointsTableData(')
          ..write('id: $id, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('depth: $depth, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, distance, heading, depth, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutoPointsTableData &&
          other.id == this.id &&
          other.distance == this.distance &&
          other.heading == this.heading &&
          other.depth == this.depth &&
          other.timestamp == this.timestamp);
}

class AutoPointsTableCompanion extends UpdateCompanion<AutoPointsTableData> {
  final Value<int> id;
  final Value<double> distance;
  final Value<double> heading;
  final Value<double> depth;
  final Value<DateTime> timestamp;
  const AutoPointsTableCompanion({
    this.id = const Value.absent(),
    this.distance = const Value.absent(),
    this.heading = const Value.absent(),
    this.depth = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  AutoPointsTableCompanion.insert({
    this.id = const Value.absent(),
    required double distance,
    required double heading,
    required double depth,
    required DateTime timestamp,
  }) : distance = Value(distance),
       heading = Value(heading),
       depth = Value(depth),
       timestamp = Value(timestamp);
  static Insertable<AutoPointsTableData> custom({
    Expression<int>? id,
    Expression<double>? distance,
    Expression<double>? heading,
    Expression<double>? depth,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (distance != null) 'distance': distance,
      if (heading != null) 'heading': heading,
      if (depth != null) 'depth': depth,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  AutoPointsTableCompanion copyWith({
    Value<int>? id,
    Value<double>? distance,
    Value<double>? heading,
    Value<double>? depth,
    Value<DateTime>? timestamp,
  }) {
    return AutoPointsTableCompanion(
      id: id ?? this.id,
      distance: distance ?? this.distance,
      heading: heading ?? this.heading,
      depth: depth ?? this.depth,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (depth.present) {
      map['depth'] = Variable<double>(depth.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AutoPointsTableCompanion(')
          ..write('id: $id, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('depth: $depth, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$CaveSurveyDatabase extends GeneratedDatabase {
  _$CaveSurveyDatabase(QueryExecutor e) : super(e);
  $CaveSurveyDatabaseManager get managers => $CaveSurveyDatabaseManager(this);
  late final $StationsTableTable stationsTable = $StationsTableTable(this);
  late final $SurveyLegsTableTable surveyLegsTable = $SurveyLegsTableTable(
    this,
  );
  late final $AutoPointsTableTable autoPointsTable = $AutoPointsTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stationsTable,
    surveyLegsTable,
    autoPointsTable,
  ];
}

typedef $$StationsTableTableCreateCompanionBuilder =
    StationsTableCompanion Function({
      Value<int> id,
      required int number,
      required double depth,
      required DateTime timestamp,
    });
typedef $$StationsTableTableUpdateCompanionBuilder =
    StationsTableCompanion Function({
      Value<int> id,
      Value<int> number,
      Value<double> depth,
      Value<DateTime> timestamp,
    });

class $$StationsTableTableFilterComposer
    extends Composer<_$CaveSurveyDatabase, $StationsTableTable> {
  $$StationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StationsTableTableOrderingComposer
    extends Composer<_$CaveSurveyDatabase, $StationsTableTable> {
  $$StationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StationsTableTableAnnotationComposer
    extends Composer<_$CaveSurveyDatabase, $StationsTableTable> {
  $$StationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<double> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$StationsTableTableTableManager
    extends
        RootTableManager<
          _$CaveSurveyDatabase,
          $StationsTableTable,
          StationsTableData,
          $$StationsTableTableFilterComposer,
          $$StationsTableTableOrderingComposer,
          $$StationsTableTableAnnotationComposer,
          $$StationsTableTableCreateCompanionBuilder,
          $$StationsTableTableUpdateCompanionBuilder,
          (
            StationsTableData,
            BaseReferences<
              _$CaveSurveyDatabase,
              $StationsTableTable,
              StationsTableData
            >,
          ),
          StationsTableData,
          PrefetchHooks Function()
        > {
  $$StationsTableTableTableManager(
    _$CaveSurveyDatabase db,
    $StationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<double> depth = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => StationsTableCompanion(
                id: id,
                number: number,
                depth: depth,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int number,
                required double depth,
                required DateTime timestamp,
              }) => StationsTableCompanion.insert(
                id: id,
                number: number,
                depth: depth,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CaveSurveyDatabase,
      $StationsTableTable,
      StationsTableData,
      $$StationsTableTableFilterComposer,
      $$StationsTableTableOrderingComposer,
      $$StationsTableTableAnnotationComposer,
      $$StationsTableTableCreateCompanionBuilder,
      $$StationsTableTableUpdateCompanionBuilder,
      (
        StationsTableData,
        BaseReferences<
          _$CaveSurveyDatabase,
          $StationsTableTable,
          StationsTableData
        >,
      ),
      StationsTableData,
      PrefetchHooks Function()
    >;
typedef $$SurveyLegsTableTableCreateCompanionBuilder =
    SurveyLegsTableCompanion Function({
      Value<int> id,
      required int fromStationId,
      required int toStationId,
      required double distance,
      required double heading,
      Value<double> left,
      Value<double> right,
      Value<double> up,
      Value<double> down,
      required DateTime timestamp,
    });
typedef $$SurveyLegsTableTableUpdateCompanionBuilder =
    SurveyLegsTableCompanion Function({
      Value<int> id,
      Value<int> fromStationId,
      Value<int> toStationId,
      Value<double> distance,
      Value<double> heading,
      Value<double> left,
      Value<double> right,
      Value<double> up,
      Value<double> down,
      Value<DateTime> timestamp,
    });

final class $$SurveyLegsTableTableReferences
    extends
        BaseReferences<
          _$CaveSurveyDatabase,
          $SurveyLegsTableTable,
          SurveyLegsTableData
        > {
  $$SurveyLegsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StationsTableTable _fromStationIdTable(_$CaveSurveyDatabase db) =>
      db.stationsTable.createAlias(
        $_aliasNameGenerator(
          db.surveyLegsTable.fromStationId,
          db.stationsTable.id,
        ),
      );

  $$StationsTableTableProcessedTableManager get fromStationId {
    final $_column = $_itemColumn<int>('from_station_id')!;

    final manager = $$StationsTableTableTableManager(
      $_db,
      $_db.stationsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromStationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StationsTableTable _toStationIdTable(_$CaveSurveyDatabase db) =>
      db.stationsTable.createAlias(
        $_aliasNameGenerator(
          db.surveyLegsTable.toStationId,
          db.stationsTable.id,
        ),
      );

  $$StationsTableTableProcessedTableManager get toStationId {
    final $_column = $_itemColumn<int>('to_station_id')!;

    final manager = $$StationsTableTableTableManager(
      $_db,
      $_db.stationsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toStationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SurveyLegsTableTableFilterComposer
    extends Composer<_$CaveSurveyDatabase, $SurveyLegsTableTable> {
  $$SurveyLegsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get left => $composableBuilder(
    column: $table.left,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get right => $composableBuilder(
    column: $table.right,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get up => $composableBuilder(
    column: $table.up,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get down => $composableBuilder(
    column: $table.down,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$StationsTableTableFilterComposer get fromStationId {
    final $$StationsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableFilterComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StationsTableTableFilterComposer get toStationId {
    final $$StationsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableFilterComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyLegsTableTableOrderingComposer
    extends Composer<_$CaveSurveyDatabase, $SurveyLegsTableTable> {
  $$SurveyLegsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get left => $composableBuilder(
    column: $table.left,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get right => $composableBuilder(
    column: $table.right,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get up => $composableBuilder(
    column: $table.up,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get down => $composableBuilder(
    column: $table.down,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$StationsTableTableOrderingComposer get fromStationId {
    final $$StationsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableOrderingComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StationsTableTableOrderingComposer get toStationId {
    final $$StationsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableOrderingComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyLegsTableTableAnnotationComposer
    extends Composer<_$CaveSurveyDatabase, $SurveyLegsTableTable> {
  $$SurveyLegsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<double> get left =>
      $composableBuilder(column: $table.left, builder: (column) => column);

  GeneratedColumn<double> get right =>
      $composableBuilder(column: $table.right, builder: (column) => column);

  GeneratedColumn<double> get up =>
      $composableBuilder(column: $table.up, builder: (column) => column);

  GeneratedColumn<double> get down =>
      $composableBuilder(column: $table.down, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$StationsTableTableAnnotationComposer get fromStationId {
    final $$StationsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StationsTableTableAnnotationComposer get toStationId {
    final $$StationsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toStationId,
      referencedTable: $db.stationsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StationsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.stationsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyLegsTableTableTableManager
    extends
        RootTableManager<
          _$CaveSurveyDatabase,
          $SurveyLegsTableTable,
          SurveyLegsTableData,
          $$SurveyLegsTableTableFilterComposer,
          $$SurveyLegsTableTableOrderingComposer,
          $$SurveyLegsTableTableAnnotationComposer,
          $$SurveyLegsTableTableCreateCompanionBuilder,
          $$SurveyLegsTableTableUpdateCompanionBuilder,
          (SurveyLegsTableData, $$SurveyLegsTableTableReferences),
          SurveyLegsTableData,
          PrefetchHooks Function({bool fromStationId, bool toStationId})
        > {
  $$SurveyLegsTableTableTableManager(
    _$CaveSurveyDatabase db,
    $SurveyLegsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyLegsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyLegsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyLegsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fromStationId = const Value.absent(),
                Value<int> toStationId = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<double> heading = const Value.absent(),
                Value<double> left = const Value.absent(),
                Value<double> right = const Value.absent(),
                Value<double> up = const Value.absent(),
                Value<double> down = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => SurveyLegsTableCompanion(
                id: id,
                fromStationId: fromStationId,
                toStationId: toStationId,
                distance: distance,
                heading: heading,
                left: left,
                right: right,
                up: up,
                down: down,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fromStationId,
                required int toStationId,
                required double distance,
                required double heading,
                Value<double> left = const Value.absent(),
                Value<double> right = const Value.absent(),
                Value<double> up = const Value.absent(),
                Value<double> down = const Value.absent(),
                required DateTime timestamp,
              }) => SurveyLegsTableCompanion.insert(
                id: id,
                fromStationId: fromStationId,
                toStationId: toStationId,
                distance: distance,
                heading: heading,
                left: left,
                right: right,
                up: up,
                down: down,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SurveyLegsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({fromStationId = false, toStationId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fromStationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromStationId,
                                    referencedTable:
                                        $$SurveyLegsTableTableReferences
                                            ._fromStationIdTable(db),
                                    referencedColumn:
                                        $$SurveyLegsTableTableReferences
                                            ._fromStationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (toStationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toStationId,
                                    referencedTable:
                                        $$SurveyLegsTableTableReferences
                                            ._toStationIdTable(db),
                                    referencedColumn:
                                        $$SurveyLegsTableTableReferences
                                            ._toStationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SurveyLegsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CaveSurveyDatabase,
      $SurveyLegsTableTable,
      SurveyLegsTableData,
      $$SurveyLegsTableTableFilterComposer,
      $$SurveyLegsTableTableOrderingComposer,
      $$SurveyLegsTableTableAnnotationComposer,
      $$SurveyLegsTableTableCreateCompanionBuilder,
      $$SurveyLegsTableTableUpdateCompanionBuilder,
      (SurveyLegsTableData, $$SurveyLegsTableTableReferences),
      SurveyLegsTableData,
      PrefetchHooks Function({bool fromStationId, bool toStationId})
    >;
typedef $$AutoPointsTableTableCreateCompanionBuilder =
    AutoPointsTableCompanion Function({
      Value<int> id,
      required double distance,
      required double heading,
      required double depth,
      required DateTime timestamp,
    });
typedef $$AutoPointsTableTableUpdateCompanionBuilder =
    AutoPointsTableCompanion Function({
      Value<int> id,
      Value<double> distance,
      Value<double> heading,
      Value<double> depth,
      Value<DateTime> timestamp,
    });

class $$AutoPointsTableTableFilterComposer
    extends Composer<_$CaveSurveyDatabase, $AutoPointsTableTable> {
  $$AutoPointsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AutoPointsTableTableOrderingComposer
    extends Composer<_$CaveSurveyDatabase, $AutoPointsTableTable> {
  $$AutoPointsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AutoPointsTableTableAnnotationComposer
    extends Composer<_$CaveSurveyDatabase, $AutoPointsTableTable> {
  $$AutoPointsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<double> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AutoPointsTableTableTableManager
    extends
        RootTableManager<
          _$CaveSurveyDatabase,
          $AutoPointsTableTable,
          AutoPointsTableData,
          $$AutoPointsTableTableFilterComposer,
          $$AutoPointsTableTableOrderingComposer,
          $$AutoPointsTableTableAnnotationComposer,
          $$AutoPointsTableTableCreateCompanionBuilder,
          $$AutoPointsTableTableUpdateCompanionBuilder,
          (
            AutoPointsTableData,
            BaseReferences<
              _$CaveSurveyDatabase,
              $AutoPointsTableTable,
              AutoPointsTableData
            >,
          ),
          AutoPointsTableData,
          PrefetchHooks Function()
        > {
  $$AutoPointsTableTableTableManager(
    _$CaveSurveyDatabase db,
    $AutoPointsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AutoPointsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AutoPointsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AutoPointsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<double> heading = const Value.absent(),
                Value<double> depth = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => AutoPointsTableCompanion(
                id: id,
                distance: distance,
                heading: heading,
                depth: depth,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double distance,
                required double heading,
                required double depth,
                required DateTime timestamp,
              }) => AutoPointsTableCompanion.insert(
                id: id,
                distance: distance,
                heading: heading,
                depth: depth,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AutoPointsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CaveSurveyDatabase,
      $AutoPointsTableTable,
      AutoPointsTableData,
      $$AutoPointsTableTableFilterComposer,
      $$AutoPointsTableTableOrderingComposer,
      $$AutoPointsTableTableAnnotationComposer,
      $$AutoPointsTableTableCreateCompanionBuilder,
      $$AutoPointsTableTableUpdateCompanionBuilder,
      (
        AutoPointsTableData,
        BaseReferences<
          _$CaveSurveyDatabase,
          $AutoPointsTableTable,
          AutoPointsTableData
        >,
      ),
      AutoPointsTableData,
      PrefetchHooks Function()
    >;

class $CaveSurveyDatabaseManager {
  final _$CaveSurveyDatabase _db;
  $CaveSurveyDatabaseManager(this._db);
  $$StationsTableTableTableManager get stationsTable =>
      $$StationsTableTableTableManager(_db, _db.stationsTable);
  $$SurveyLegsTableTableTableManager get surveyLegsTable =>
      $$SurveyLegsTableTableTableManager(_db, _db.surveyLegsTable);
  $$AutoPointsTableTableTableManager get autoPointsTable =>
      $$AutoPointsTableTableTableManager(_db, _db.autoPointsTable);
}
