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
      cardColorId: fields[6] as int,
      createdAt: fields[7] as DateTime?,
      notes: fields[8] as String?,
      tags: (fields[9] as List?)?.cast<String>(),
      expiryReminderEnabled: fields[10] as bool? ?? false,
      expiryReminderDaysBefore: fields[11] as int? ?? 30,
      paymentReminderEnabled: fields[12] as bool? ?? false,
      paymentDueDay: fields[13] as int?,
      paymentReminderDaysBefore: fields[14] as int? ?? 3,
      reminderHour: fields[15] as int? ?? 9,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCard obj) {
    writer
      ..writeByte(15)
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
      ..writeByte(6)
      ..write(obj.cardColorId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.expiryReminderEnabled)
      ..writeByte(11)
      ..write(obj.expiryReminderDaysBefore)
      ..writeByte(12)
      ..write(obj.paymentReminderEnabled)
      ..writeByte(13)
      ..write(obj.paymentDueDay)
      ..writeByte(14)
      ..write(obj.paymentReminderDaysBefore)
      ..writeByte(15)
      ..write(obj.reminderHour);
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
