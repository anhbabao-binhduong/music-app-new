import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';   // 👈 THÊM

import '../../data/repositories/music_repository_impl.dart';
import '../../domain/repositories/music_repository.dart';
import '../../presentation/bloc/chart/chart_cubit.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/search/search_cubit.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/favorite/favorite_cubit.dart';
import '../../presentation/bloc/download/download_cubit.dart';
import '../../presentation/bloc/playlist/playlist_cubit.dart';
import '../../presentation/bloc/history/history_cubit.dart';
import '../../services/lyrics_service.dart';
import '../../services/music_player_service.dart';
import '../../services/playlist_storage_service.dart';

// 👇 IMPORT MỚI CHO CATEGORY
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_songs_by_category_usecase.dart';
import '../../presentation/bloc/category/category_cubit.dart';

// 👇 IMPORT MỚI CHO ALBUM
import '../../domain/usecases/get_albums_usecase.dart';
import '../../presentation/bloc/album/album_cubit.dart';

// 👇 IMPORT CHO COMMENT
import '../../domain/repositories/comment_repository.dart';
import '../../data/repositories/comment_repository_impl.dart';
import '../../presentation/bloc/comment/comment_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Đăng ký SupabaseClient (nếu chưa có) ─────────────────────────────
  // Giả sử Supabase đã được khởi tạo trước đó, ta chỉ lấy instance
  final supabase = Supabase.instance.client;
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  // ─── MusicPlayerService & AudioHandler ────────────────────────────────
  final musicService = MusicPlayerService();
  await musicService.init();
  getIt.registerSingleton<MusicPlayerService>(musicService);
  getIt.registerSingleton<AudioHandler>(musicService.handler);

  // ─── LyricsService ────────────────────────────────────────────────────
  getIt.registerLazySingleton<LyricsService>(() => LyricsService());

  // ─── PlaylistStorageService ───────────────────────────────────────────
  getIt.registerLazySingleton<PlaylistStorageService>(
    () => PlaylistStorageService(),
  );

  // ─── MusicRepository (sửa lại để nhận SupabaseClient) ─────────────────
  getIt.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  // ─── Use Cases cho Category (mới) ──────────────────────────────────────
  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<MusicRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetSongsByCategoryUseCase(getIt<MusicRepository>()),
  );

  // ─── Use Cases cho Album (mới) ──────────────────────────────────────────
  getIt.registerLazySingleton(
    () => GetAlbumsUsecase(getIt<MusicRepository>()),
  );

  // ─── BLoC / Cubit ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<HistoryCubit>(() => HistoryCubit());

  getIt.registerLazySingleton<PlayerBloc>(
    () => PlayerBloc(getIt<AudioHandler>(), getIt<HistoryCubit>()),
  );

  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(getIt<MusicRepository>()),
  );

  getIt.registerFactory<ChartCubit>(() => ChartCubit(getIt<MusicRepository>()));

  getIt.registerLazySingleton<ThemeBloc>(() => ThemeBloc());
  getIt.registerLazySingleton<FavoriteCubit>(() => FavoriteCubit());
  getIt.registerLazySingleton<DownloadCubit>(() => DownloadCubit());
  getIt.registerLazySingleton<PlaylistCubit>(() => PlaylistCubit());

  // ─── CategoryCubit (mới) – dùng factory ───────────────────────────────
  getIt.registerFactory<CategoryCubit>(
    () => CategoryCubit(
      getCategories: getIt<GetCategoriesUseCase>(),
      getSongsByCategory: getIt<GetSongsByCategoryUseCase>(),
    ),
  );

  getIt.registerFactory<AlbumCubit>(
    () => AlbumCubit(getIt<GetAlbumsUsecase>()),
  );

  // ─── Comment feature ────────────────────────────────────────────────────
  getIt.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(),
  );
  getIt.registerFactory<CommentCubit>(
    () => CommentCubit(getIt<CommentRepository>()),
  );
}