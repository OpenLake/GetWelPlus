import 'package:flutter/material.dart';
import 'package:flutter_app/auth/auth_wrapper.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/pages/mood_tracker.dart';
import 'package:flutter_app/pages/stress_check_page.dart';
import 'package:flutter_app/pages/online_meet_page.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://prvbbbnsizxxfxreokov.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBydmJiYm5zaXp4eGZ4cmVva292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4OTMwODgsImV4cCI6MjA4NjQ2OTA4OH0.GOqP5k0AnGzqse5loXuPz9BkfGCUdJgApUL9QBVw0es',
  );

  await NotificationService.instance.initialize(navigatorKey: navigatorKey);
  await NotificationService.instance.requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GetWel+',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/mood': (_) => const MoodTrackerPage(),
        '/stress': (_) => const StressCheckPage(),
        '/online_meet': (_) => const OnlineMeetPage(),
      },
    );
  }
}
