// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'button_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ButtonConfigAdapter extends TypeAdapter<ButtonConfig> {
  @override
  final int typeId = 2;

  @override
  ButtonConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ButtonConfig(
      size: fields[0] as double,
      offsetX: fields[1] as double,
      offsetY: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ButtonConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.size)
      ..writeByte(1)
      ..write(obj.offsetX)
      ..writeByte(2)
      ..write(obj.offsetY);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ButtonConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
