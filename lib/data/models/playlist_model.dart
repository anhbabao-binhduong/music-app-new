import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 2)
class PlaylistModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1)       String name;
  @HiveField(2)       List<String> songIds;  // list of SongModel keys
  @HiveField(3) final DateTime createdAt;
  @HiveField(4)       String? coverArtUrl;

  PlaylistModel({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
    this.coverArtUrl,
  })  : songIds   = songIds   ?? [],
        createdAt = createdAt ?? DateTime.now();
}