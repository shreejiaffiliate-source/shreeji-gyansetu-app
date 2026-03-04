import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 3 seconds (or when animation finishes)
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/auth_wrapper');
    });
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