import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Required for SystemNavigator.pop()
import '../core/constants/app_colors.dart';
import 'screens/home/home_tab.dart';
import 'screens/courses/course_list_screen.dart';
import 'screens/learning/my_learning_screen.dart';
import 'screens/profile/profile_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const CourseListScreen(),
    const MyCoursesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ✅ Sabse solid tareeka exit dialog dikhane ka
  Future<void> _handleBackPress() async {
    // 1. Agar user kisi aur tab par hai, toh pehle Home Tab (Index 0) par le jao
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    // 2. Agar Home Tab par hi hai, toh Dialog dikhao
    final bool shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Exit App", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Do you really want to exit Shreeji GyanSetu?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    // 3. Agar user ne 'Yes' click kiya, toh app close karo
    if (shouldExit) {
      SystemNavigator.pop(); // ✅ Ye har baar kaam karega (Android/iOS standard)
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ Hamesha back gesture ko block rakho taaki hamara logic chale
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPress(); // ✅ Har baar ye function call hoga
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).cardColor,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle_fill),
                label: 'My Learning',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}