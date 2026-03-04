import 'package:hive/hive.dart';

part 'history_entry_model.g.dart';

@HiveType(typeId: 1)
class HistoryEntryModel extends HiveObject {
  @HiveField(0) final String songId;
  @HiveField(1) final DateTime playedAt;
  @HiveField(2) final int playDurationMs;   // bao nhiêu ms đã nghe

  HistoryEntryModel({
    required this.songId,
    required this.playedAt,
    this.playDurationMs = 0,
  });
}