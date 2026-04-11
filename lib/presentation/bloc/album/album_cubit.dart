import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_albums_usecase.dart';
import 'album_state.dart';

class AlbumCubit extends Cubit<AlbumState> {
  final GetAlbumsUsecase _usecase;

  AlbumCubit(this._usecase) : super(AlbumInitial());

  Future<void> loadAlbums() async {
    emit(AlbumLoading());
    try {
      final albums = await _usecase();
      emit(AlbumLoaded(albums));
    } catch (e) {
      emit(AlbumError(e.toString()));
    }
  }
}
