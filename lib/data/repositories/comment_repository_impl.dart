import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/data/models/comment_model.dart';
import 'package:music_app/domain/entities/comment_entity.dart';
import 'package:music_app/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final SupabaseClient _supabase;

  CommentRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments(String songId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('song_id', songId)
          .order('created_at', ascending: false);

      final comments = (response as List)
          .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
          .toList();

      return Right(comments);
    } catch (e) {
      return Left(CacheFailure('Không thể tải bình luận: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addComment({
    required String songId,
    required String userId,
    required String displayName,
    required String content,
  }) async {
    try {
      await _supabase.from('comments').insert(
        CommentModel.toInsertJson(
          userId: userId,
          displayName: displayName,
          songId: songId,
          content: content,
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Không thể gửi bình luận: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(
      String commentId, String userId) async {
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Không thể xóa bình luận: $e'));
    }
  }
}
