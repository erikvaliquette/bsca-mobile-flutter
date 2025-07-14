// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_trip_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalTripDataAdapter extends TypeAdapter<LocalTripData> {
  @override
  final int typeId = 0;

  @override
  LocalTripData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalTripData(
      id: fields[0] as String?,
      userId: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
      distance: fields[4] as double,
      mode: fields[5] as String,
      fuelType: fields[6] as String?,
      emissions: fields[7] as double,
      startLocation: fields[8] as String?,
      endLocation: fields[9] as String?,
      isActive: fields[10] as bool,
      purpose: fields[11] as String?,
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalTripData obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.mode)
      ..writeByte(6)
      ..write(obj.fuelType)
      ..writeByte(7)
      ..write(obj.emissions)
      ..writeByte(8)
      ..write(obj.startLocation)
      ..writeByte(9)
      ..write(obj.endLocation)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.purpose)
      ..writeByte(12)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTripDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalLocationPointAdapter extends TypeAdapter<LocalLocationPoint> {
  @override
  final int typeId = 1;

  @override
  LocalLocationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalLocationPoint(
      id: fields[0] as String?,
      tripId: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      timestamp: fields[4] as String,
      altitude: fields[5] as double?,
      speed: fields[6] as double?,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalLocationPoint obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.altitude)
      ..writeByte(6)
      ..write(obj.speed)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalLocationPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
