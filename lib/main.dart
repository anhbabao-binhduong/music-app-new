import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/local_music_data.dart'; 
import 'domain/entities/song_entity.dart';
import 'presentation/bloc/player/player_bloc.dart';
import 'presentation/bloc/search/search_cubit.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'services/music_player_service.dart';
import 'app.dart';
import 'core/di/hive_initializer.dart';
import 'core/di/service_locator.dart';
import 'package:music_app/presentation/bloc/download/download_cubit.dart';
import 'package:music_app/presentation/bloc/favorite/favorite_cubit.dart';
import 'package:music_app/presentation/bloc/playlist/playlist_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await HiveInitializer.init();
  await setupServiceLocator();
  
  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://pdbkojvgjrvnzqmerwmz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkYmtvanZnanJ2bnpxbWVyd216Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjE3ODMsImV4cCI6MjA4ODgzNzc4M30.uuT4AYL5UWbb7Tdyt2curTcpuwbYPNYFGXFrg7stYp0', 
  );

  // 1. Khởi tạo Repository để lấy nhạc
  final songRepo = SongRepository();

  // 2. Tải danh sách nhạc từ Supabase về (THAY THẾ HOÀN TOÀN localPlaylist)
  final supabasePlaylist = await songRepo.fetchSongsFromSupabase();
    localPlaylist = supabasePlaylist;
  // 3. Chuyển đổi dữ liệu từ Supabase sang SongEntity để SearchCubit có thể tìm kiếm
  final songPool = supabasePlaylist.map((item) => SongEntity(
    id:         item.id,
    title:      item.title,
    artist:     item.artist ?? 'Unknown',
    album:      item.album  ?? 'Local Music',
    artUrl:     item.artUri?.toString(),
    audioUrl:   item.id,
    durationMs: item.duration?.inMilliseconds ?? 0,
  )).toList();

  // 4. Nạp danh sách bài hát vừa tải vào bloc tìm kiếm
  final searchCubit = getIt<SearchCubit>()..loadSongPool(songPool);

  // 5. Chạy App
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicPlayerService>(
          create: (_) => getIt<MusicPlayerService>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>(
            create: (_) => getIt<PlayerBloc>(),
          ),
          BlocProvider<ThemeBloc>(
            create: (_) => getIt<ThemeBloc>()..add(const LoadThemeEvent()),
          ),
          BlocProvider<SearchCubit>.value(value: searchCubit),
          BlocProvider<FavoriteCubit>(
            create: (_) => FavoriteCubit(),
          ),
          BlocProvider<DownloadCubit>(
            create: (_) => DownloadCubit(),
          ),
          BlocProvider<PlaylistCubit>(
            create: (_) => PlaylistCubit(),
          ),
        ],
        child: const MyApp(),
      ),
      
    ),
  );
}