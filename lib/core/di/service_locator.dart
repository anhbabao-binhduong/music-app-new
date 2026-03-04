import 'package:get_it/get_it.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../domain/repositories/music_repository.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/search/search_cubit.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../services/music_player_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Services (Singletons) ───────────────────────────────
  final musicService = MusicPlayerService();
  await musicService.init();
  getIt.registerSingleton<MusicPlayerService>(musicService);

  // ── Repositories ────────────────────────────────────────
  getIt.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(),
  );

  // ── BLoCs / Cubits (Factories — new instance per page) ──
  getIt.registerFactory<PlayerBloc>(
    () => PlayerBloc(getIt<MusicPlayerService>()),
  );
  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(getIt<MusicRepository>()),
  );

  // ThemeBloc is a Singleton (persists across the whole app)
  getIt.registerLazySingleton<ThemeBloc>(() => ThemeBloc());
}