import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gyansetu/ui/navigation_wrapper.dart';
import 'package:gyansetu/ui/screens/auth/login_screen.dart';
import 'package:gyansetu/ui/screens/auth/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/course_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/services/notification_service.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Services
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Initialized");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("❌ Firebase/Notification Init Error: $e");
  }

  // 2. Setup Auth State
  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  // 3. Setup Theme State
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool("theme_mode") ?? false;

  runApp(
    MultiProvider(
      providers: [
        // Using .value because we initialized authProvider above to run checkLoginStatus
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the whole MaterialApp in a Consumer to handle theme and auth changes globally
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, child) {
        return MaterialApp(
          title: 'Shreeji GyanSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,

          // Using a conditional home directly here is often more reliable than a separate Wrapper widget
          home: auth.isAuthenticated
              ? const NavigationWrapper()
              : const LoginScreen(),

          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}

// Keeping this for route-based navigation if needed
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use watch to ensure the widget rebuilds on auth changes
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const NavigationWrapper();
    } else {
      return const LoginScreen();
    }
  }
}