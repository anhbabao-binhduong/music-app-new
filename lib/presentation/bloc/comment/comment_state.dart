import 'package:equatable/equatable.dart';
import 'package:music_app/domain/entities/comment_entity.dart';

abstract class CommentState extends Equatable {
  const CommentState();
  @override
  List<Object?> get props => [];
}

class CommentInitial extends CommentState {}

class CommentLoading extends CommentState {}

class CommentLoaded extends CommentState {
  final List<CommentEntity> comments;
  const CommentLoaded(this.comments);
  @override
  List<Object?> get props => [comments];
}

class CommentError extends CommentState {
  final String message;
  const CommentError(this.message);
  @override
  List<Object?> get props => [message];
}
