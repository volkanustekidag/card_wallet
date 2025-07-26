// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardAdapter extends TypeAdapter<CreditCard> {
  @override
  final int typeId = 3;

  @override
  CreditCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCard(
      id: fields[0] as dynamic,
      bankName: fields[1] as String,
      creditCardNumber: fields[2] as String,
      cardHolder: fields[3] as String,
      expirationDate: fields[4] as String,
      cvc2: fields[5] as String,
      cardColorId: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCard obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.creditCardNumber)
      ..writeByte(3)
      ..write(obj.cardHolder)
      ..writeByte(4)
      ..write(obj.expirationDate)
      ..writeByte(5)
      ..write(obj.cvc2)
      ..writeByte(6)
      ..write(obj.cardColorId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
