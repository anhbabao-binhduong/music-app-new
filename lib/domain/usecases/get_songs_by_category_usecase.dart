// lib/domain/usecases/get_songs_by_category_usecase.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/song_entity.dart';
import '../repositories/music_repository.dart';

class GetSongsByCategoryUseCase {
  final MusicRepository _repository;
  const GetSongsByCategoryUseCase(this._repository);

  /// [slug] = null → trả tất cả bài hát
  Future<Either<Failure, List<SongEntity>>> call(String? slug) =>
      _repository.getSongsByCategory(slug);
}