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

  @override
  Future<Either<Failure, List<CommentEntity>>> getUserComments(String userId) async {
    try {
      // Dùng raw SQL để JOIN comments → songs (song_id là text, songs.id là bigint)
      final response = await _supabase.rpc('get_user_comments_with_songs', params: {
        'p_user_id': userId,
      });

      final comments = (response as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return CommentEntity(
          id: map['id'] as String,
          songId: map['song_id'] as String,
          userId: map['user_id'] as String,
          displayName: map['display_name'] as String? ?? 'Anonymous',
          content: map['content'] as String,
          createdAt: DateTime.parse(map['created_at'] as String),
          songTitle: map['song_title'] as String?,
          songArtist: map['song_artist'] as String?,
          songArtUrl: map['song_art_url'] as String?,
        );
      }).toList();

      return Right(comments);
    } catch (e) {
      return Left(CacheFailure('Không thể tải lịch sử bình luận: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> editComment(String commentId, String userId, String newContent) async {
    try {
      await _supabase
          .from('comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .eq('user_id', userId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Không thể sửa bình luận: $e'));
    }
  }
}
