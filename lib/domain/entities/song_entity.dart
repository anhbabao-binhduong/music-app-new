// lib/domain/entities/song_entity.dart
import 'package:equatable/equatable.dart';

class SongEntity extends Equatable {
  final String  id;
  final String  title;
  final String  artist;
  final String  album;
  final String? artUrl;
  final String? audioUrl;
  final int     durationMs;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.artUrl,
    this.audioUrl,
    this.durationMs = 0,
  });

  @override
  List<Object?> get props =>
      [id, title, artist, album, artUrl, audioUrl, durationMs];
}