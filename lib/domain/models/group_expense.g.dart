// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupExpenseAdapter extends TypeAdapter<GroupExpense> {
  @override
  final int typeId = 2;

  @override
  GroupExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupExpense(
      title: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      whoPaid: fields[3] as Member,
      forWhom: (fields[4] as List).cast<Member>(),
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpense obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.whoPaid)
      ..writeByte(4)
      ..write(obj.forWhom)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
