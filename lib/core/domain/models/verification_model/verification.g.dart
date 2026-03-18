// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerificationAdapter extends TypeAdapter<Verification> {
  @override
  final int typeId = 1;

  @override
  Verification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Verification(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Verification obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
