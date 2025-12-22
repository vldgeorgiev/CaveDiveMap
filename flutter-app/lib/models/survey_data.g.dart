// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_data.dart';

// ignore_for_file: type=lint
class $SurveyDataTableTable extends SurveyDataTable
    with TableInfo<$SurveyDataTableTable, SurveyDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyDataTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordNumberMeta = const VerificationMeta(
    'recordNumber',
  );
  @override
  late final GeneratedColumn<int> recordNumber = GeneratedColumn<int>(
    'record_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _rtypeMeta = const VerificationMeta('rtype');
  @override
  late final GeneratedColumn<String> rtype = GeneratedColumn<String>(
    'rtype',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    recordNumber,
    distance,
    heading,
    depth,
    left,
    right,
    up,
    down,
    rtype,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_data_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyDataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('record_number')) {
      context.handle(
        _recordNumberMeta,
        recordNumber.isAcceptableOrUnknown(
          data['record_number']!,
          _recordNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordNumberMeta);
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
    if (data.containsKey('rtype')) {
      context.handle(
        _rtypeMeta,
        rtype.isAcceptableOrUnknown(data['rtype']!, _rtypeMeta),
      );
    } else if (isInserting) {
      context.missing(_rtypeMeta);
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
  SurveyDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyDataTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_number'],
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
      rtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rtype'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $SurveyDataTableTable createAlias(String alias) {
    return $SurveyDataTableTable(attachedDatabase, alias);
  }
}

class SurveyDataTableData extends DataClass
    implements Insertable<SurveyDataTableData> {
  final int id;
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
  const SurveyDataTableData({
    required this.id,
    required this.recordNumber,
    required this.distance,
    required this.heading,
    required this.depth,
    required this.left,
    required this.right,
    required this.up,
    required this.down,
    required this.rtype,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['record_number'] = Variable<int>(recordNumber);
    map['distance'] = Variable<double>(distance);
    map['heading'] = Variable<double>(heading);
    map['depth'] = Variable<double>(depth);
    map['left'] = Variable<double>(left);
    map['right'] = Variable<double>(right);
    map['up'] = Variable<double>(up);
    map['down'] = Variable<double>(down);
    map['rtype'] = Variable<String>(rtype);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  SurveyDataTableCompanion toCompanion(bool nullToAbsent) {
    return SurveyDataTableCompanion(
      id: Value(id),
      recordNumber: Value(recordNumber),
      distance: Value(distance),
      heading: Value(heading),
      depth: Value(depth),
      left: Value(left),
      right: Value(right),
      up: Value(up),
      down: Value(down),
      rtype: Value(rtype),
      timestamp: Value(timestamp),
    );
  }

  factory SurveyDataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyDataTableData(
      id: serializer.fromJson<int>(json['id']),
      recordNumber: serializer.fromJson<int>(json['recordNumber']),
      distance: serializer.fromJson<double>(json['distance']),
      heading: serializer.fromJson<double>(json['heading']),
      depth: serializer.fromJson<double>(json['depth']),
      left: serializer.fromJson<double>(json['left']),
      right: serializer.fromJson<double>(json['right']),
      up: serializer.fromJson<double>(json['up']),
      down: serializer.fromJson<double>(json['down']),
      rtype: serializer.fromJson<String>(json['rtype']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordNumber': serializer.toJson<int>(recordNumber),
      'distance': serializer.toJson<double>(distance),
      'heading': serializer.toJson<double>(heading),
      'depth': serializer.toJson<double>(depth),
      'left': serializer.toJson<double>(left),
      'right': serializer.toJson<double>(right),
      'up': serializer.toJson<double>(up),
      'down': serializer.toJson<double>(down),
      'rtype': serializer.toJson<String>(rtype),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  SurveyDataTableData copyWith({
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
  }) => SurveyDataTableData(
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
  SurveyDataTableData copyWithCompanion(SurveyDataTableCompanion data) {
    return SurveyDataTableData(
      id: data.id.present ? data.id.value : this.id,
      recordNumber: data.recordNumber.present
          ? data.recordNumber.value
          : this.recordNumber,
      distance: data.distance.present ? data.distance.value : this.distance,
      heading: data.heading.present ? data.heading.value : this.heading,
      depth: data.depth.present ? data.depth.value : this.depth,
      left: data.left.present ? data.left.value : this.left,
      right: data.right.present ? data.right.value : this.right,
      up: data.up.present ? data.up.value : this.up,
      down: data.down.present ? data.down.value : this.down,
      rtype: data.rtype.present ? data.rtype.value : this.rtype,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyDataTableData(')
          ..write('id: $id, ')
          ..write('recordNumber: $recordNumber, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('depth: $depth, ')
          ..write('left: $left, ')
          ..write('right: $right, ')
          ..write('up: $up, ')
          ..write('down: $down, ')
          ..write('rtype: $rtype, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordNumber,
    distance,
    heading,
    depth,
    left,
    right,
    up,
    down,
    rtype,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyDataTableData &&
          other.id == this.id &&
          other.recordNumber == this.recordNumber &&
          other.distance == this.distance &&
          other.heading == this.heading &&
          other.depth == this.depth &&
          other.left == this.left &&
          other.right == this.right &&
          other.up == this.up &&
          other.down == this.down &&
          other.rtype == this.rtype &&
          other.timestamp == this.timestamp);
}

class SurveyDataTableCompanion extends UpdateCompanion<SurveyDataTableData> {
  final Value<int> id;
  final Value<int> recordNumber;
  final Value<double> distance;
  final Value<double> heading;
  final Value<double> depth;
  final Value<double> left;
  final Value<double> right;
  final Value<double> up;
  final Value<double> down;
  final Value<String> rtype;
  final Value<DateTime> timestamp;
  const SurveyDataTableCompanion({
    this.id = const Value.absent(),
    this.recordNumber = const Value.absent(),
    this.distance = const Value.absent(),
    this.heading = const Value.absent(),
    this.depth = const Value.absent(),
    this.left = const Value.absent(),
    this.right = const Value.absent(),
    this.up = const Value.absent(),
    this.down = const Value.absent(),
    this.rtype = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SurveyDataTableCompanion.insert({
    this.id = const Value.absent(),
    required int recordNumber,
    required double distance,
    required double heading,
    required double depth,
    this.left = const Value.absent(),
    this.right = const Value.absent(),
    this.up = const Value.absent(),
    this.down = const Value.absent(),
    required String rtype,
    required DateTime timestamp,
  }) : recordNumber = Value(recordNumber),
       distance = Value(distance),
       heading = Value(heading),
       depth = Value(depth),
       rtype = Value(rtype),
       timestamp = Value(timestamp);
  static Insertable<SurveyDataTableData> custom({
    Expression<int>? id,
    Expression<int>? recordNumber,
    Expression<double>? distance,
    Expression<double>? heading,
    Expression<double>? depth,
    Expression<double>? left,
    Expression<double>? right,
    Expression<double>? up,
    Expression<double>? down,
    Expression<String>? rtype,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordNumber != null) 'record_number': recordNumber,
      if (distance != null) 'distance': distance,
      if (heading != null) 'heading': heading,
      if (depth != null) 'depth': depth,
      if (left != null) 'left': left,
      if (right != null) 'right': right,
      if (up != null) 'up': up,
      if (down != null) 'down': down,
      if (rtype != null) 'rtype': rtype,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SurveyDataTableCompanion copyWith({
    Value<int>? id,
    Value<int>? recordNumber,
    Value<double>? distance,
    Value<double>? heading,
    Value<double>? depth,
    Value<double>? left,
    Value<double>? right,
    Value<double>? up,
    Value<double>? down,
    Value<String>? rtype,
    Value<DateTime>? timestamp,
  }) {
    return SurveyDataTableCompanion(
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
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordNumber.present) {
      map['record_number'] = Variable<int>(recordNumber.value);
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
    if (rtype.present) {
      map['rtype'] = Variable<String>(rtype.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyDataTableCompanion(')
          ..write('id: $id, ')
          ..write('recordNumber: $recordNumber, ')
          ..write('distance: $distance, ')
          ..write('heading: $heading, ')
          ..write('depth: $depth, ')
          ..write('left: $left, ')
          ..write('right: $right, ')
          ..write('up: $up, ')
          ..write('down: $down, ')
          ..write('rtype: $rtype, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$SurveyDatabase extends GeneratedDatabase {
  _$SurveyDatabase(QueryExecutor e) : super(e);
  $SurveyDatabaseManager get managers => $SurveyDatabaseManager(this);
  late final $SurveyDataTableTable surveyDataTable = $SurveyDataTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [surveyDataTable];
}

typedef $$SurveyDataTableTableCreateCompanionBuilder =
    SurveyDataTableCompanion Function({
      Value<int> id,
      required int recordNumber,
      required double distance,
      required double heading,
      required double depth,
      Value<double> left,
      Value<double> right,
      Value<double> up,
      Value<double> down,
      required String rtype,
      required DateTime timestamp,
    });
typedef $$SurveyDataTableTableUpdateCompanionBuilder =
    SurveyDataTableCompanion Function({
      Value<int> id,
      Value<int> recordNumber,
      Value<double> distance,
      Value<double> heading,
      Value<double> depth,
      Value<double> left,
      Value<double> right,
      Value<double> up,
      Value<double> down,
      Value<String> rtype,
      Value<DateTime> timestamp,
    });

class $$SurveyDataTableTableFilterComposer
    extends Composer<_$SurveyDatabase, $SurveyDataTableTable> {
  $$SurveyDataTableTableFilterComposer({
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

  ColumnFilters<int> get recordNumber => $composableBuilder(
    column: $table.recordNumber,
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

  ColumnFilters<String> get rtype => $composableBuilder(
    column: $table.rtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurveyDataTableTableOrderingComposer
    extends Composer<_$SurveyDatabase, $SurveyDataTableTable> {
  $$SurveyDataTableTableOrderingComposer({
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

  ColumnOrderings<int> get recordNumber => $composableBuilder(
    column: $table.recordNumber,
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

  ColumnOrderings<String> get rtype => $composableBuilder(
    column: $table.rtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurveyDataTableTableAnnotationComposer
    extends Composer<_$SurveyDatabase, $SurveyDataTableTable> {
  $$SurveyDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get recordNumber => $composableBuilder(
    column: $table.recordNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<double> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<double> get left =>
      $composableBuilder(column: $table.left, builder: (column) => column);

  GeneratedColumn<double> get right =>
      $composableBuilder(column: $table.right, builder: (column) => column);

  GeneratedColumn<double> get up =>
      $composableBuilder(column: $table.up, builder: (column) => column);

  GeneratedColumn<double> get down =>
      $composableBuilder(column: $table.down, builder: (column) => column);

  GeneratedColumn<String> get rtype =>
      $composableBuilder(column: $table.rtype, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$SurveyDataTableTableTableManager
    extends
        RootTableManager<
          _$SurveyDatabase,
          $SurveyDataTableTable,
          SurveyDataTableData,
          $$SurveyDataTableTableFilterComposer,
          $$SurveyDataTableTableOrderingComposer,
          $$SurveyDataTableTableAnnotationComposer,
          $$SurveyDataTableTableCreateCompanionBuilder,
          $$SurveyDataTableTableUpdateCompanionBuilder,
          (
            SurveyDataTableData,
            BaseReferences<
              _$SurveyDatabase,
              $SurveyDataTableTable,
              SurveyDataTableData
            >,
          ),
          SurveyDataTableData,
          PrefetchHooks Function()
        > {
  $$SurveyDataTableTableTableManager(
    _$SurveyDatabase db,
    $SurveyDataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recordNumber = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<double> heading = const Value.absent(),
                Value<double> depth = const Value.absent(),
                Value<double> left = const Value.absent(),
                Value<double> right = const Value.absent(),
                Value<double> up = const Value.absent(),
                Value<double> down = const Value.absent(),
                Value<String> rtype = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => SurveyDataTableCompanion(
                id: id,
                recordNumber: recordNumber,
                distance: distance,
                heading: heading,
                depth: depth,
                left: left,
                right: right,
                up: up,
                down: down,
                rtype: rtype,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recordNumber,
                required double distance,
                required double heading,
                required double depth,
                Value<double> left = const Value.absent(),
                Value<double> right = const Value.absent(),
                Value<double> up = const Value.absent(),
                Value<double> down = const Value.absent(),
                required String rtype,
                required DateTime timestamp,
              }) => SurveyDataTableCompanion.insert(
                id: id,
                recordNumber: recordNumber,
                distance: distance,
                heading: heading,
                depth: depth,
                left: left,
                right: right,
                up: up,
                down: down,
                rtype: rtype,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurveyDataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$SurveyDatabase,
      $SurveyDataTableTable,
      SurveyDataTableData,
      $$SurveyDataTableTableFilterComposer,
      $$SurveyDataTableTableOrderingComposer,
      $$SurveyDataTableTableAnnotationComposer,
      $$SurveyDataTableTableCreateCompanionBuilder,
      $$SurveyDataTableTableUpdateCompanionBuilder,
      (
        SurveyDataTableData,
        BaseReferences<
          _$SurveyDatabase,
          $SurveyDataTableTable,
          SurveyDataTableData
        >,
      ),
      SurveyDataTableData,
      PrefetchHooks Function()
    >;

class $SurveyDatabaseManager {
  final _$SurveyDatabase _db;
  $SurveyDatabaseManager(this._db);
  $$SurveyDataTableTableTableManager get surveyDataTable =>
      $$SurveyDataTableTableTableManager(_db, _db.surveyDataTable);
}
