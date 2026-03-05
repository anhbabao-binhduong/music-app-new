// lib/domain/entities/playlist_entity.dart
import 'package:equatable/equatable.dart';

class PlaylistEntity extends Equatable {
  final String id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final String? coverArtUrl;

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.coverArtUrl,
  });

  @override
  List<Object?> get props => [id, name, songIds, createdAt, coverArtUrl];
}