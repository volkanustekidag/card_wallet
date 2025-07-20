// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iban_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IbanCardAdapter extends TypeAdapter<IbanCard> {
  @override
  final int typeId = 2;

  @override
  IbanCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IbanCard(
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, IbanCard obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.cardHolder)
      ..writeByte(3)
      ..write(obj.iban)
      ..writeByte(4)
      ..write(obj.swiftCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IbanCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
