import '../../domain/entities/album_entity.dart';
import '../../domain/repositories/music_repository.dart';

class GetAlbumsUsecase {
  final MusicRepository repository;
  GetAlbumsUsecase(this.repository);
  Future<List<AlbumEntity>> call() => repository.getAlbums();
}
