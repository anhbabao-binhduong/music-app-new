import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/firebase_options.dart';

import 'presentation/bloc/player/player_bloc.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'services/music_player_service.dart';
import 'app.dart';
import 'core/di/hive_initializer.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase phải init trước mọi thứ khác
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await HiveInitializer.init();
  await setupServiceLocator();

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
        ],
        child: const MyApp(),
      ),
    ),
  );
}