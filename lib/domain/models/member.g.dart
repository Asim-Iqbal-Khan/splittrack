// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 1;

  @override
  Member read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Member(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
