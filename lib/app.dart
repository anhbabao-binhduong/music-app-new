import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_preview/device_preview.dart';
import 'core/constants/app_theme.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'pages/root_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) => MaterialApp(
        title: 'Music App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeState.flutterThemeMode,
        locale: DevicePreview.locale(context),     
        builder: DevicePreview.appBuilder,           
        home: const RootPage(),
      ),
    );
  }
}