import 'package:hive/hive.dart';
import '../../domain/entities/album_entity.dart';

part 'album_model.g.dart';

@HiveType(typeId: 3)
class AlbumModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String artistName;
  @HiveField(3) final String? coverUrl;
  @HiveField(4) final int? releaseYear;
  @HiveField(5) final String? description;
  @HiveField(6) final List<String> songIds;

  AlbumModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.releaseYear,
    this.description,
    required this.songIds,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    // album_songs nested: [{song_id, track_number}, ...]
    final rawSongs = json['album_songs'] as List<dynamic>? ?? [];
    final sorted = List<Map<String, dynamic>>.from(
      rawSongs.map((e) => Map<String, dynamic>.from(e as Map)),
    )..sort((a, b) =>
        ((a['track_number'] as num?) ?? 0)
            .compareTo((b['track_number'] as num?) ?? 0));

    return AlbumModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artistName: json['artist_name'] as String,
      coverUrl: json['cover_url'] as String?,
      releaseYear: json['release_year'] as int?,
      description: json['description'] as String?,
      songIds: sorted.map((e) => e['song_id'] as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist_name': artistName,
        'cover_url': coverUrl,
        'release_year': releaseYear,
        'description': description,
      };

  AlbumEntity toEntity() => AlbumEntity(
        id: id,
        title: title,
        artistName: artistName,
        coverUrl: coverUrl,
        releaseYear: releaseYear,
        description: description,
        songIds: songIds,
      );
}
