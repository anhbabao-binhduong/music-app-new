import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/domain/entities/comment_entity.dart';

abstract class CommentRepository {
  Future<Either<Failure, List<CommentEntity>>> getComments(String songId);

  Future<Either<Failure, Unit>> addComment({
    required String songId,
    required String userId,
    required String displayName,
    required String content,
  });

  Future<Either<Failure, Unit>> deleteComment(String commentId, String userId);
}
