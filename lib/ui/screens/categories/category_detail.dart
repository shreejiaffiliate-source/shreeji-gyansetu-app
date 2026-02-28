import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/custom_button.dart';
import '../learning/lesson_player_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final String categorySlug;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categorySlug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName, style: TextStyle(color: Colors.white),),
        leading: BackButton(
          color: Colors.white,
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        // 2. Fetch data using the slug-filtered API
        future: ApiService().getCoursesByCategory(categorySlug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final coursesData = snapshot.data!;

          // 3. Use GridView to show the CourseCards exactly like the Home Screen
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68, // Adjust this to fit your card content
            ),
            itemCount: coursesData.length,
            itemBuilder: (context, index) {
              // 4. Convert JSON to your Model and pass it to your CourseCard
              final course = CourseModel.fromJson(coursesData[index]);
              return CourseCard(course: course);
            },
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
          Icon(Icons.category_outlined, size: 80, color: AppColors.primarySoft),
          const SizedBox(height: 16),
          const Text(
            "No courses found in this category",
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}