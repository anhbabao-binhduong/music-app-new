import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart'; 
import '../../data/repositories/music_repository_impl.dart';
import '../../domain/repositories/music_repository.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/search/search_cubit.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../services/music_player_service.dart';
import '../../services/playlist_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final musicService = MusicPlayerService();
  await musicService.init();
  getIt.registerLazySingleton<PlaylistStorageService>(() => PlaylistStorageService());
  // 1. Đăng ký MusicPlayerService để dùng các hàm tiện ích như playSong, playPlaylist...
  getIt.registerSingleton<MusicPlayerService>(musicService);

  // 2. Đăng ký CÁI HANDLER bên trong nó cho kiểu AudioHandler
  // Thay vì (musicService as AudioHandler), hãy dùng:
  getIt.registerSingleton<AudioHandler>(musicService.handler);

  // --- Các phần dưới giữ nguyên ---
  getIt.registerLazySingleton<MusicRepository>(() => MusicRepositoryImpl());

  getIt.registerLazySingleton<PlayerBloc>(
    () => PlayerBloc(getIt<AudioHandler>()),
  );
  
  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(getIt<MusicRepository>()),
  );

  getIt.registerLazySingleton<ThemeBloc>(() => ThemeBloc());
}