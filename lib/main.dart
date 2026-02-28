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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

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

    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Shreeji GyanSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // Switch automatically
      home: const AuthWrapper(), // Set home to the wrapper
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // This will rebuild every time notifyListeners() is called in AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      return const NavigationWrapper();
    } else {
      return const LoginScreen();
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This watches the AuthProvider for any changes (login or logout)
    final authProvider = Provider.of<AuthProvider>(context);

    // If a token exists, show the main app. If not, show the login screen.
    if (authProvider.isAuthenticated) {
      return const NavigationWrapper();
    } else {
      return const LoginScreen();
    }
  }
}
