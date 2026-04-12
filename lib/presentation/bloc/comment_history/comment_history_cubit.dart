import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/domain/repositories/comment_repository.dart';
import 'comment_history_state.dart';

class CommentHistoryCubit extends Cubit<CommentHistoryState> {
  final CommentRepository _repo;

  CommentHistoryCubit(this._repo) : super(CommentHistoryInitial());

  Future<void> loadUserComments(String userId) async {
    emit(CommentHistoryLoading());
    final result = await _repo.getUserComments(userId);
    result.fold(
      (failure) => emit(CommentHistoryError(failure.message)),
      (comments) => emit(CommentHistoryLoaded(comments)),
    );
  }

  Future<void> editComment(String commentId, String userId, String newContent) async {
    // Retain current state to restore if error
    final currentState = state;
    if (currentState is CommentHistoryLoaded) {
      emit(CommentHistoryLoading());
      final result = await _repo.editComment(commentId, userId, newContent);
      result.fold(
        (failure) {
          emit(CommentHistoryError(failure.message));
          // Restore old list
          emit(currentState);
        },
        (_) => loadUserComments(userId),
      );
    }
  }

  Future<void> deleteComment(String commentId, String userId) async {
    final currentState = state;
    if (currentState is CommentHistoryLoaded) {
      emit(CommentHistoryLoading());
      final result = await _repo.deleteComment(commentId, userId);
      result.fold(
        (failure) {
          emit(CommentHistoryError(failure.message));
          emit(currentState);
        },
        (_) => loadUserComments(userId),
      );
    }
  }
}
