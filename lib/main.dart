import 'package:flutter/material.dart';
import 'core/di/hive_initializer.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Order matters:
  // 1. Init Hive (open all boxes)
  await HiveInitializer.init();

  // 2. Setup DI (services, repos, blocs)
  await setupServiceLocator();

  runApp(const MyApp());
}