import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_preview/device_preview.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/core/router/app_routes.dart';
import 'package:music_app/pages/auth/forgot_password_check_email_page.dart';
import 'package:music_app/pages/auth/forgot_password_page.dart';
import 'package:music_app/pages/auth/login_page.dart';
import 'package:music_app/pages/auth/reset_password_page.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_cubit.dart';
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
        navigatorKey: appNavigatorKey,
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.forgotPassword: (_) => BlocProvider<ForgotPasswordCubit>(
                create: (_) => getIt<ForgotPasswordCubit>(),
                child: const ForgotPasswordPage(),
              ),
          AppRoutes.resetPassword: (_) => BlocProvider<ForgotPasswordCubit>(
                create: (_) => getIt<ForgotPasswordCubit>(),
                child: const ResetPasswordPage(),
              ),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.forgotPasswordCheckEmail) {
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => BlocProvider<ForgotPasswordCubit>(
                create: (_) => getIt<ForgotPasswordCubit>(),
                child: ForgotPasswordCheckEmailPage(email: email),
              ),
            );
          }
          return null;
        },
        home: const RootPage(),
      ),
    );
  }
}