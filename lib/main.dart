import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 🎯 NAYA: AdMob SDK Import
import 'package:gyansetu/ui/navigation_wrapper.dart';
import 'package:gyansetu/ui/screens/auth/login_screen.dart';
import 'package:gyansetu/ui/screens/auth/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/course_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/services/internet_wrapper.dart';
import 'data/services/notification_service.dart';
import 'package:gyansetu/ui/screens/teacher/teacher_navigation_wrapper.dart'; // Teacher ka wrapper
import 'package:gyansetu/core/utils/storage_service.dart';

import 'ui/widgets/gyansetu_interstitial_ad.dart'; // Storage service role nikalne ke liye

// ✅ 1. GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 NAYA: AdMob SDK engine ko start kiya
  await MobileAds.instance.initialize();

  // Interstitial Ad background me load ho jayegi
  GyansetuInterstitialAd.loadAd();

  // 2. Initialize Services
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Initialized successfully");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Notification Service
    await NotificationService.initialize(navigatorKey);

    // ✅ 4. AUTO-SYNC TOKEN: Har baar app khulte hi latest token server par bhejein
    // Ye tabhi upload karega agar AuthProvider.storedToken null nahi hai
    await NotificationService.getAndUploadToken();

  } catch (e) {
    debugPrint("❌ Firebase/Notification Init Error: $e");
  }

  // Setup Auth State
  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  // Setup Theme State
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool("theme_mode") ?? false;

  runApp(
    MultiProvider(
      providers: [
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
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Shreeji GyanSetu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,

          // ✅ YAHAN HUMNE WRAPPER ADD KIYA HAI
          builder: (context, widget) {
            return InternetWrapper(
              // Agar aapne AuthProvider ya kisi aur provider mein isServerDown handle kiya hai
              // toh wahan se value pass kar sakte ho, varna abhi ke liye false rakho.
              child: widget!,
            );
          },

          // home: auth.isAuthenticated
          //     ? const NavigationWrapper()
          //     : const LoginScreen(),

          // NAYA CODE:
          home: const AuthWrapper(),

          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Agar user logged in hai
    if (authProvider.isAuthenticated) {
      // FutureBuilder se hum role nikalenge
      return FutureBuilder<String?>(
        future: StorageService().getUserRole(),
        builder: (context, snapshot) {
          // Jab tak role nikal raha hai, ek loading spinner dikhao
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // Role check karo aur sahi Dashboard par bhejo
          if (snapshot.data == 'Teacher') {
            return const TeacherNavigationWrapper();
          } else {
            return const NavigationWrapper(); // Student Dashboard
          }
        },
      );
    } else {
      // Agar logged in nahi hai, toh direct Login Screen
      return const LoginScreen();
    }
  }
}