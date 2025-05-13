import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'features/common/screens/splash_screen.dart';
import 'features/common/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/settings/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Load dark mode preference before runApp
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  ThemeController.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'CrowdEase',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
