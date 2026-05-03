import 'package:flutter/foundation.dart';
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
import 'package:music_app/presentation/bloc/category/category_cubit.dart';
import 'package:music_app/presentation/bloc/history/history_cubit.dart';
import 'package:music_app/presentation/bloc/comment/comment_cubit.dart';
import 'package:music_app/presentation/bloc/upload/upload_cubit.dart';
import 'package:music_app/presentation/bloc/user_songs/user_songs_cubit.dart';
import 'package:music_app/presentation/bloc/admin/admin_cubit.dart';
import 'package:device_preview/device_preview.dart';
import 'package:music_app/core/router/app_routes.dart';

Map<String, String> _readAuthParamsFromUrl(Uri uri) {
  final params = <String, String>{...uri.queryParameters};

  if (uri.fragment.isNotEmpty) {
    final fragment = uri.fragment.startsWith('?')
        ? uri.fragment.substring(1)
        : uri.fragment;
    params.addAll(Uri.splitQueryString(fragment));
  }

  return params;
}

Future<bool> _handleWebPasswordRecoveryRedirect() async {
  if (!kIsWeb) return false;

  final supabase = Supabase.instance.client;
  final params = _readAuthParamsFromUrl(Uri.base);

  final hasRecoveryType = params['type'] == 'recovery';
  final hasAccessToken = params.containsKey('access_token');

  if (!hasRecoveryType && !hasAccessToken) return false;

  try {
    final code = params['code'];
    final refreshToken = params['refresh_token'];

    if (code != null && code.isNotEmpty) {
      await supabase.auth.exchangeCodeForSession(code);
    } else if (refreshToken != null && refreshToken.isNotEmpty) {
      await supabase.auth.setSession(refreshToken);
    }
  } catch (_) {}

  return true;
}

void _setupAuthListener() {
  final supabase = Supabase.instance.client;
  
  supabase.auth.onAuthStateChange.listen((event) async {
    if (event.event == AuthChangeEvent.signedOut) {
      final musicService = getIt<MusicPlayerService>();
      await musicService.stop();
      await musicService.handler.updateQueue([]);
      getIt<PlayerBloc>().add(ResetPlayerEvent());
      getIt<FavoriteCubit>().clear();
      getIt<DownloadCubit>().clear();
      // ✅ Xóa sạch lịch sử khỏi bộ nhớ ngay lập tức
      getIt<HistoryCubit>().clearLocalData();
    }

    if (event.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => false,
        );
      });
      return;
    }

    if (event.event == AuthChangeEvent.signedIn ||
        event.event == AuthChangeEvent.initialSession) {
      // Tải lại lịch sử của user mới (xóa cũ trước, load mới sau)
      getIt<HistoryCubit>().reloadForUser();
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

  // 8. Handle web password recovery redirect
  final shouldOpenResetPassword = await _handleWebPasswordRecoveryRedirect();

  // 9. Run app
  runApp(
  DevicePreview(
    enabled: true, // đổi thành false
    builder: (context) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicPlayerService>(
          create: (_) => musicService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HistoryCubit>.value(
            value: getIt<HistoryCubit>(),
          ),
          BlocProvider<PlayerBloc>.value(
            value: getIt<PlayerBloc>(),
          ),
          BlocProvider<ThemeBloc>.value(
            value: getIt<ThemeBloc>()..add(const LoadThemeEvent()),
          ),
          BlocProvider<SearchCubit>.value(value: searchCubit),
          BlocProvider<FavoriteCubit>.value(
            value: getIt<FavoriteCubit>(),
          ),
          BlocProvider<DownloadCubit>.value(
            value: getIt<DownloadCubit>(),
          ),
          BlocProvider<PlaylistCubit>.value(
            value: getIt<PlaylistCubit>(),
          ),
          BlocProvider<CategoryCubit>.value(
            value: getIt<CategoryCubit>(),
          ),
          BlocProvider<CommentCubit>(
            create: (_) => getIt<CommentCubit>(),
          ),
          BlocProvider<UploadCubit>.value(
            value: getIt<UploadCubit>(),
          ),
          BlocProvider<UserSongsCubit>.value(
            value: getIt<UserSongsCubit>(),
          ),
          BlocProvider<AdminCubit>.value(
            value: getIt<AdminCubit>(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  ),
);

  if (shouldOpenResetPassword) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.pushNamed(AppRoutes.resetPassword);
    });
  }
}
