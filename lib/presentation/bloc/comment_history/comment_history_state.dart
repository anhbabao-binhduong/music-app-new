import 'package:equatable/equatable.dart';
import 'package:music_app/domain/entities/comment_entity.dart';

abstract class CommentHistoryState extends Equatable {
  const CommentHistoryState();

  @override
  List<Object> get props => [];
}

class CommentHistoryInitial extends CommentHistoryState {}

class CommentHistoryLoading extends CommentHistoryState {}

class CommentHistoryLoaded extends CommentHistoryState {
  final List<CommentEntity> comments;

  const CommentHistoryLoaded(this.comments);

  @override
  List<Object> get props => [comments];
}

class CommentHistoryError extends CommentHistoryState {
  final String message;

  const CommentHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
