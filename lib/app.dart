import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/core/router/app_routes.dart';
import 'package:music_app/pages/auth/forgot_password_check_email_page.dart';
import 'package:music_app/pages/auth/forgot_password_page.dart';
import 'package:music_app/pages/auth/login_page.dart';
import 'package:music_app/pages/auth/reset_password_page.dart';
import 'package:music_app/presentation/bloc/forgot_password/forgot_password_cubit.dart';
import 'package:music_app/pages/chat/chat_page.dart';
import 'package:music_app/pages/chat/conversations_page.dart';
import 'core/constants/app_theme.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'pages/root_page.dart';
import 'pages/user_search/user_search_page.dart';
import 'pages/user_search/user_profile_view_page.dart';

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
          AppRoutes.userSearch: (_) => const UserSearchPage(),
          AppRoutes.conversations: (_) => const ConversationsPage(),
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
          if (settings.name == AppRoutes.userProfile) {
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => UserProfileViewPage(userId: userId),
            );
          }
          if (settings.name == AppRoutes.chat) {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => ChatPage(
                conversationId: args['conversationId']!,
                otherUserName: args['otherUserName']!,
                otherUserId: args['otherUserId']!,
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