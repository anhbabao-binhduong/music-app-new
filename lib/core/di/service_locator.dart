import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';

import '../../data/repositories/music_repository_impl.dart';
import '../../domain/repositories/music_repository.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/search/search_cubit.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../presentation/bloc/download/download_cubit.dart';
import '../../presentation/bloc/playlist/playlist_cubit.dart';

import '../../services/lyrics_service.dart'; // 👈 THÊM
import '../../services/music_player_service.dart';
import '../../services/playlist_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {

  final musicService = MusicPlayerService();
  await musicService.init();

  getIt.registerSingleton<MusicPlayerService>(musicService);
  getIt.registerSingleton<AudioHandler>(musicService.handler);

  getIt.registerLazySingleton<LyricsService>( // 👈 THÊM
    () => LyricsService(),
  );

  getIt.registerLazySingleton<PlaylistStorageService>(
    () => PlaylistStorageService(),
  );

  getIt.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(),
  );

  getIt.registerFactory<PlayerBloc>(
    () => PlayerBloc(getIt<AudioHandler>()),
  );

  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(getIt<MusicRepository>()),
  );

  getIt.registerLazySingleton<ThemeBloc>(
    () => ThemeBloc(),
  );

  getIt.registerLazySingleton<FavoriteCubit>(
    () => FavoriteCubit(),
  );

  getIt.registerLazySingleton<DownloadCubit>(
    () => DownloadCubit(),
  );

  getIt.registerLazySingleton<PlaylistCubit>(
    () => PlaylistCubit(),
  );
}