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
import 'package:music_app/presentation/bloc/category/category_cubit.dart'; // 👈 THÊM

void _setupAuthListener() {
  final supabase = Supabase.instance.client;
  
  supabase.auth.onAuthStateChange.listen((event) async {
    if (event.event == AuthChangeEvent.signedOut) {
      final musicService = getIt<MusicPlayerService>();
      await musicService.stop();
      await musicService.handler.updateQueue([]);
      getIt<PlayerBloc>().add(ResetPlayerEvent());
      getIt<FavoriteCubit>().emit([]);
      getIt<DownloadCubit>().emit([]);
    }
    
    if (event.event == AuthChangeEvent.signedIn) {
      // TODO: reload data
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Hive
  await HiveInitializer.init();

  // 2. Khởi tạo Supabase TRƯỚC
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 3. Sau đó mới gọi service locator (vì nó cần Supabase.instance.client)
  await setupServiceLocator();

  // 4. Lấy music service
  final musicService = getIt<MusicPlayerService>();

  // 5. Load nhạc từ Supabase
  final songRepo = SongRepository();
  final supabasePlaylist = await songRepo.fetchSongsFromSupabase();

  final user = Supabase.instance.client.auth.currentUser;

  if (user != null && supabasePlaylist.isNotEmpty) {
    await musicService.handler.updateQueue(supabasePlaylist);
  }

  // 6. Search data
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

  // 7. Auth listener
  _setupAuthListener();

  // 8. Run app
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
            key: UniqueKey(),
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
          BlocProvider<CategoryCubit>(
            create: (context) => getIt<CategoryCubit>(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}