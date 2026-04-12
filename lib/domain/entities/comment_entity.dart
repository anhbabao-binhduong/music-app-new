import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String songId;
  final String userId;
  final String displayName;
  final String content;
  final DateTime createdAt;
  // Song info — chỉ có khi query kèm JOIN (lịch sử bình luận)
  final String? songTitle;
  final String? songArtist;
  final String? songArtUrl;

  const CommentEntity({
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

  @override
  List<Object?> get props => [id, songId, userId, displayName, content, createdAt, songTitle, songArtist, songArtUrl];
}
