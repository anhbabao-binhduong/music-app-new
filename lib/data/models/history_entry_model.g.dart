// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryModelAdapter extends TypeAdapter<HistoryEntryModel> {
  @override
  final int typeId = 1;

  @override
  HistoryEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntryModel(
      songId: fields[0] as String,
      playedAt: fields[1] as DateTime,
      playDurationMs: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntryModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.playedAt)
      ..writeByte(2)
      ..write(obj.playDurationMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
