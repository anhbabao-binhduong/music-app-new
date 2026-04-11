import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String songId;
  final String userId;
  final String displayName;
  final String content;
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.songId,
    required this.userId,
    required this.displayName,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, songId, userId, displayName, content, createdAt];
}
