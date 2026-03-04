import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String artist;
  @HiveField(3) final String album;
  @HiveField(4) final String? artUrl;
  @HiveField(5) final String? audioUrl;
  @HiveField(6) final int durationMs;
  @HiveField(7) final DateTime? addedAt;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.artUrl,
    this.audioUrl,
    this.durationMs = 0,
    this.addedAt,
  });

  // ─── Converters ──────────────────────────────────────────

  factory SongModel.fromMediaItem(MediaItem item) => SongModel(
    id:          item.id,
    title:       item.title,
    artist:      item.artist ?? 'Unknown Artist',
    album:       item.album  ?? 'Unknown Album',
    artUrl:      item.artUri?.toString(),
    audioUrl:    item.id,                       // id == stream URL
    durationMs:  item.duration?.inMilliseconds ?? 0,
    addedAt:     DateTime.now(),
  );

  MediaItem toMediaItem() => MediaItem(
    id:       audioUrl ?? id,
    title:    title,
    artist:   artist,
    album:    album,
    artUri:   artUrl != null ? Uri.tryParse(artUrl!) : null,
    duration: Duration(milliseconds: durationMs),
    extras:   {'addedAt': addedAt?.toIso8601String()},
  );

  SongModel copyWith({DateTime? addedAt}) => SongModel(
    id: id, title: title, artist: artist, album: album,
    artUrl: artUrl, audioUrl: audioUrl, durationMs: durationMs,
    addedAt: addedAt ?? this.addedAt,
  );
}