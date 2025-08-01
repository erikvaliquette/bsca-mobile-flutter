// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_business_connection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalBusinessConnectionAdapter
    extends TypeAdapter<LocalBusinessConnection> {
  @override
  final int typeId = 2;

  @override
  LocalBusinessConnection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalBusinessConnection(
      id: fields[0] as String,
      name: fields[1] as String,
      userId: fields[9] as String,
      counterpartyId: fields[10] as String,
      relationshipType: fields[11] as String,
      status: fields[12] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      cachedAt: fields[13] as DateTime,
      currentUserId: fields[14] as String,
      location: fields[2] as String?,
      title: fields[3] as String?,
      organization: fields[4] as String?,
      profileImageUrl: fields[5] as String?,
      sdgGoals: (fields[6] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalBusinessConnection obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.organization)
      ..writeByte(5)
      ..write(obj.profileImageUrl)
      ..writeByte(6)
      ..write(obj.sdgGoals)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.userId)
      ..writeByte(10)
      ..write(obj.counterpartyId)
      ..writeByte(11)
      ..write(obj.relationshipType)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.cachedAt)
      ..writeByte(14)
      ..write(obj.currentUserId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalBusinessConnectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
