import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/local_music_data.dart';
import 'domain/entities/song_entity.dart';
import 'presentation/bloc/player/player_bloc.dart';
import 'presentation/bloc/search/search_cubit.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'services/music_player_service.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/hive_initializer.dart';
import 'core/di/service_locator.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/presentation/bloc/playlist/playlist_cubit.dart';
import 'package:music_app/presentation/bloc/player/player_event.dart';

void _setupAuthListener() {
  final supabase = Supabase.instance.client;
  
  supabase.auth.onAuthStateChange.listen((event) async {
    if (event.event == AuthChangeEvent.signedOut) {
      // User đã đăng xuất - xóa toàn bộ dữ liệu nhạc
      final musicService = getIt<MusicPlayerService>();
      await musicService.stop();
      await musicService.handler.updateQueue([]);
      getIt<PlayerBloc>().add(ResetPlayerEvent());
      // Xóa các Cubit state
      getIt<FavoriteCubit>().emit([]);
      getIt<DownloadCubit>().emit([]);
    }
    
    if (event.event == AuthChangeEvent.signedIn) {
      // User đăng nhập - reload lại dữ liệu
      final favoriteCubit = getIt<FavoriteCubit>();
      final downloadCubit = getIt<DownloadCubit>();
      
      // TODO: Cần có method public để reload, không gọi private method
      // favoriteCubit.loadFavorites();
      // downloadCubit.loadDownloads();
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage
  await HiveInitializer.init();
  await setupServiceLocator();

  // Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 🎧 Player service (KHÔNG init lại)
  final musicService = getIt<MusicPlayerService>();

  // 🎵 Load nhạc từ Supabase
  final songRepo = SongRepository();
  final supabasePlaylist = await songRepo.fetchSongsFromSupabase();

  final user = Supabase.instance.client.auth.currentUser;

    // ⭐ CHỈ load khi đã đăng nhập
    if (user != null && supabasePlaylist.isNotEmpty) {
      await musicService.handler.updateQueue(supabasePlaylist);
    }

  // 🔍 Search data
  final songPool = supabasePlaylist.map((item) => SongEntity(
        id: item.id,
        title: item.title,
        artist: item.artist ?? 'Unknown',
        album: item.album ?? 'Local Music',
        artUrl: item.artUri?.toString(),
        audioUrl: item.id,
        durationMs: item.duration?.inMilliseconds ?? 0,
      )).toList();

  final searchCubit = getIt<SearchCubit>()..loadSongPool(songPool);

  // Setup auth listener sau khi Supabase đã khởi tạo
  _setupAuthListener();

  // 🚀 RUN APP
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicPlayerService>(
          create: (_) => musicService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>(
            key: UniqueKey(), // ⭐ ép rebuild khi cần
            create: (_) => getIt<PlayerBloc>(),
          ),
          BlocProvider<ThemeBloc>(
            create: (_) => getIt<ThemeBloc>()..add(const LoadThemeEvent()),
          ),
          BlocProvider<SearchCubit>.value(value: searchCubit),

          BlocProvider<FavoriteCubit>(
            create: (_) => getIt<FavoriteCubit>(),
          ),
          BlocProvider<DownloadCubit>(
            create: (_) => getIt<DownloadCubit>(),
          ),
          BlocProvider<PlaylistCubit>(
            create: (_) => getIt<PlaylistCubit>(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}