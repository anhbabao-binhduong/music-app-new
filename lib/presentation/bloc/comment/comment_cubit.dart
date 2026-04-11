import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/domain/repositories/comment_repository.dart';
import 'comment_state.dart';

String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

class CommentCubit extends Cubit<CommentState> {
  final CommentRepository _repo;

  CommentCubit(this._repo) : super(CommentInitial());

  Future<void> loadComments(String songId) async {
    emit(CommentLoading());
    final result = await _repo.getComments(songId);
    result.fold(
      (failure) => emit(CommentError(failure.message)),
      (comments) => emit(CommentLoaded(comments)),
    );
  }

  Future<void> addComment({
    required String songId,
    required String userId,
    required String displayName,
    required String content,
  }) async {
    final result = await _repo.addComment(
      songId: songId,
      userId: userId,
      displayName: displayName,
      content: content,
    );
    result.fold(
      (failure) => emit(CommentError(failure.message)),
      (_) => loadComments(songId),
    );
  }

  Future<void> deleteComment(
      String commentId, String userId, String songId) async {
    final result = await _repo.deleteComment(commentId, userId);
    result.fold(
      (failure) => emit(CommentError(failure.message)),
      (_) => loadComments(songId),
    );
  }
}
