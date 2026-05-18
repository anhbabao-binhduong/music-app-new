import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordCheckEmail = '/forgot-password-check-email';
  static const String resetPassword = '/reset-password';
  static const String userSearch = '/user-search';
  static const String userProfile = '/user-profile';
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();