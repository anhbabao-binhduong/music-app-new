import 'package:music_app/domain/entities/comment_entity.dart';

class CommentModel {
  final String id;
  final String songId;
  final String userId;
  final String displayName;
  final String content;
  final DateTime createdAt;
  final String? songTitle;
  final String? songArtist;
  final String? songArtUrl;

  const CommentModel({
    required this.id,
    required this.songId,
    required this.userId,
    required this.displayName,
    required this.content,
    required this.createdAt,
    this.songTitle,
    this.songArtist,
    this.songArtUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      songId: json['song_id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Anonymous',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      songTitle: json['song_title'] as String?,
      songArtist: json['song_artist'] as String?,
      songArtUrl: json['song_art_url'] as String?,
    );
  }

  CommentEntity toEntity() => CommentEntity(
        id: id,
        songId: songId,
        userId: userId,
        displayName: displayName,
        content: content,
        createdAt: createdAt,
        songTitle: songTitle,
        songArtist: songArtist,
        songArtUrl: songArtUrl,
      );

  static Map<String, dynamic> toInsertJson({
    required String userId,
    required String displayName,
    required String songId,
    required String content,
  }) =>
      {
        'user_id': userId,
        'display_name': displayName,
        'song_id': songId,
        'content': content,
      };
}
