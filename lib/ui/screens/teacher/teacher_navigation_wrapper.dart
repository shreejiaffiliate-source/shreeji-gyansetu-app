import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_queries_screen.dart';
import '../../widgets/gyansetu_banner_ad.dart'; // 🎯 NAYA: Banner Ad import kiya

class TeacherNavigationWrapper extends StatefulWidget {
  const TeacherNavigationWrapper({super.key});

  @override
  State<TeacherNavigationWrapper> createState() => _TeacherNavigationWrapperState();
}

class _TeacherNavigationWrapperState extends State<TeacherNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TeacherDashboardScreen(),
    const TeacherCoursesScreen(),
    const TeacherQueriesScreen(),
    const TeacherProfileScreen(),   // Replace with TeacherProfileScreen
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🎯 NAYA CHANGE: Body ko Column me daalkar uske bottom me Banner ad fix kar diya
      body: Column(
        children: [
          Expanded(
            child: _screens[_currentIndex],
          ),
          // 🎯 NAYA: Ye ad hamesha bottom navigation bar ke theek upar rahegi
          const GyansetuBannerAd(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.play_lesson_outlined), activeIcon: Icon(Icons.play_lesson), label: 'Courses'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Queries'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}