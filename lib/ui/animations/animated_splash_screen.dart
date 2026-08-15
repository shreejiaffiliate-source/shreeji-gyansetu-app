import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../../core/utils/storage_service.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoginStateAndNavigate();
  }

  Future<void> _checkLoginStateAndNavigate() async {
    // 3 seconds wait karo
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final storage = StorageService();
    String? token = await storage.getToken();
    String? role = await storage.getUserRole();

    if (token != null) {
      // User logged in hai
      if (role == 'Teacher') {
        // Navigator.of(context).pushReplacementNamed('/teacher_home');
        print("Go to Teacher Dashboard");
      } else {
        Navigator.of(context).pushReplacementNamed('/student_home'); // Ya jo bhi aapka route ho NavigationWrapper ke liye
      }
    } else {
      // Not logged in
      Navigator.of(context).pushReplacementNamed('/auth_wrapper'); // Ya login screen ka route
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.network(
          'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json',// Download a JSON from LottieFiles
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}