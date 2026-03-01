import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/course_card.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Load enrolled courses specifically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    // Filter the list to show only enrolled ones
    final myCourses = courseProvider.popularCourses.where((c) => c.isEnrolled).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("My Learning")),
      body: courseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : myCourses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CourseCard(course: myCourses[index]), // Or a list-style widget
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("You haven't enrolled in any courses yet."),
        ],
      ),
    );
  }
}