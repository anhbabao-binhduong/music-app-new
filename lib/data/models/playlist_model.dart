import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 2)
class PlaylistModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) List<String> songIds;
  @HiveField(3) final DateTime createdAt;
  @HiveField(4) String? coverArtUrl;

  PlaylistModel({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
    this.coverArtUrl,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 🔥 THÊM ĐOẠN NÀY
  PlaylistModel copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    String? coverArtUrl,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? List<String>.from(this.songIds),
      createdAt: createdAt ?? this.createdAt,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
    );
  }
}